extends CharacterBody2D
class_name Car

@export var code : String

var raycasts : Array[GeneticRayCast2D]
@export var tiles_travelled : int = 0
@export var frames_on_wall : int = 0
@export var distance : float
var last_tile : Vector2i = Vector2i(0, 0)

@export var acceleration = 20
@export var top_speed = 1000
@export var max_turn = 3
@export var turn_speed_factor = 2 #1 means no turning at max speed
@export var front_aero = 0.98
@export var sideways_aero = 0.96
@export var collision_penalty = 0.8

@export var raycast_length = 500
@export var raycast_count = 3 #per side + 1 middle

@onready var track : TileMapLayer

func init_code(rays : int, raylen : int, bits_accuracy : int, code : String) -> void:
	self.raycast_count = rays
	self.raycast_length = raylen
	self.code = code
	if len(code) == (rays+1) * bits_accuracy * 6:
		var rayi = 0
		for i in range(-90, 1, 180 / (raycast_count * 2)):
			var ray = GeneticRayCast2D.new(bits_accuracy, code.substr(rayi*bits_accuracy*6, bits_accuracy*6), raycast_length )
			var ray2 = GeneticRayCast2D.new(bits_accuracy, code.substr(rayi*bits_accuracy*6, bits_accuracy*6), raycast_length )
			ray2.negated = true
			rayi += 1
			ray.collision_mask = 1
			ray2.collision_mask = 1
			ray.target_position = Vector2(0, raycast_length)
			ray2.target_position = Vector2(0, raycast_length)
			ray.rotation_degrees = rotation_degrees + i - 90
			ray2.rotation_degrees = rotation_degrees + i + 180 / (raycast_count * 2)
			raycasts.append(ray)
			add_child(ray)
			if i < 0:
				raycasts.append(ray2)
				add_child(ray2)
	else:
		print("WRONG CAR CODE LENGTH: ", len(code))

func _ready() -> void:
	track = get_tree().get_first_node_in_group("Track")

func accel(x) -> void:
	if x < 0: x *= 0.333
	velocity = velocity.move_toward(Vector2(top_speed, 0).rotated(rotation), acceleration * x)

func turn(x) -> void:
	x = clamp(x, -1, 1)
	var turn_mult = 0

	if velocity.length() > top_speed / 4:
		var speed_ratio = clamp(velocity.length() / (top_speed * turn_speed_factor), 0, 1)
		turn_mult = max_turn * (1.0 - speed_ratio)  # Less turn at high speed
	else:
		var speed_ratio = clamp(velocity.length() / (top_speed / 4 * turn_speed_factor), 0, 1)
		turn_mult = clamp( (max_turn - (max_turn * (1.0 - speed_ratio))) * 2, 0, max_turn)  # Less turn at high speed
	
	rotation_degrees += x * turn_mult

	# Smooth velocity turn (adjust 0.5 to control "driftiness")
	var angle = deg_to_rad(x * turn_mult)
	var rotated_velocity = velocity.rotated(angle)
	velocity = velocity.lerp(rotated_velocity, 0.75)

func forces() -> void:
	var sideways_vel = velocity.dot( Vector2(0, 1).rotated( rotation ) )
	var front_vel = velocity.dot( Vector2(1, 0).rotated( rotation ) )
	velocity = Vector2( front_vel * front_aero , sideways_vel * sideways_aero ).rotated( rotation )

func _physics_process(delta: float) -> void:
	forces()
	update_tile()
	var turn_factor = 0
	var accel_factor = 0
	for i in range(0, len(raycasts) / 2):
		turn_factor += raycasts[i].get_turn_factor()
	for i in range(len(raycasts) / 2 + 1, len(raycasts)):
		turn_factor += raycasts[i].get_turn_factor()
	for i in raycasts:
		accel_factor += i.get_accel_factor()
	#var turn = 0
	#var accel = 0
	# if Input.is_key_pressed(KEY_W): accel = 1
	# if Input.is_key_pressed(KEY_S): accel = -1
	# if Input.is_key_pressed(KEY_D): turn = 1
	# if Input.is_key_pressed(KEY_A): turn = -1
	#if name == "best": print(turn_factor)
	turn(turn_factor)
	accel(accel_factor)
	distance += velocity.length()
	if move_and_slide():
		collision()

func update_tile() -> void:
	var tile_pos = track.local_to_map(global_position / track.scale)
	if tile_pos != last_tile:
		last_tile = tile_pos
		tiles_travelled += 1
		if tile_pos == track.start_cell and tiles_travelled < 30 and tiles_travelled > 2: queue_free()

func collision() -> void:
	velocity *= collision_penalty
	frames_on_wall += 1
	set_physics_process(false)
