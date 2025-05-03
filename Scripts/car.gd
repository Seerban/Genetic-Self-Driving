extends CharacterBody2D

var raycasts : Array[GeneticRayCast2D]
var tiles_travelled : int = 0
var last_tile : Vector2i = Vector2i(0, 0)

@export var acceleration = 20
@export var top_speed = 1000
@export var max_turn = 2
@export var turn_speed_factor = 2 #1 means no turning at max speed
@export var front_aero = 0.98
@export var sideways_aero = 0.96
@export var collision_penalty = 0.94

@export var raycast_length = 400
@export var raycast_count = 15 #per side + 1 middle

@onready var track : TileMapLayer

func _ready() -> void:
	track = get_tree().get_first_node_in_group("Track")
	for i in range(-90, 91, 180 / (raycast_count * 2)):
		var ray = GeneticRayCast2D.new(7, "011111001111100111110011111001111100111110")
		ray.target_position = Vector2(0, raycast_length)
		ray.rotation_degrees = rotation_degrees + i - 90
		if i > 0:
			ray.negated = true
		raycasts.append(ray)
		add_child(ray)

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
	raycasts[0].get_turn_factor()
	var turn = 0
	var accel = 0
	if Input.is_key_pressed(KEY_W): accel = 1
	if Input.is_key_pressed(KEY_S): accel = -1
	if Input.is_key_pressed(KEY_D): turn = 1
	if Input.is_key_pressed(KEY_A): turn = -1
	turn(turn)
	accel(accel)
	if move_and_slide():
		collision()

func update_tile() -> void:
	var tile_pos = track.local_to_map(position / track.scale)
	if tile_pos != last_tile:
		last_tile = tile_pos
		tiles_travelled += 1

func collision() -> void:
	velocity *= collision_penalty
