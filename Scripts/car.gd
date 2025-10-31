extends CharacterBody2D
class_name Car

# Variables managed by base.gd when spawned

@export var code : String # genetic binary code
@export var distance : float = 0 # distance travelled

var acceleration = 1 # linear acceleration to top_speed
var brake_factor = 5 # multiplier to backwards acceleration under braking
var top_speed = 1000
var max_turn = 3 # turning multiplier
var turn_speed_factor = 2 # speed negative influence over turning (1 = no turning at maxspeed)
var front_aero = 0.99 # forward damping
var side_aero = 0.9 # sideways damping

var penalty_remaining = 0 # penalty to top speed for bad behaviour
var penalty_factor = 0.15

var raycasts : Array[GeneticRayCast2D]
@export var raycast_length = 500
@export var raycast_count = 3 # per side + 1 middle

@onready var track : TileMapLayer
@onready var base : Node2D

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
	base = get_parent()

func accel(x) -> void:
	if x < 0:
		# if car is moving forward
		if velocity.dot( Vector2(1, 0).rotated( rotation ) ) > 0:
			x = brake_factor
		else:
			x *= 0.333
	
	if penalty_remaining > 0:
		velocity = velocity.move_toward(Vector2(top_speed * penalty_factor, 0).rotated(rotation), acceleration * x)
	else:
		velocity = velocity.move_toward(Vector2(top_speed, 0).rotated(rotation), acceleration * x)

func turn(x) -> void:
	x = clamp(x, -1, 1)
	var turn_mult = 0
	turn_mult = max_turn * ( (top_speed - velocity.length() * 0.8) / top_speed )
	rotation_degrees += x * turn_mult

	# Smooth velocity turn (adjust 0.5 to control "driftiness")
	var angle = deg_to_rad(x * turn_mult)
	var rotated_velocity = velocity.rotated(angle)
	velocity = velocity.lerp(rotated_velocity, 0.75)

func forces() -> void:
	var sideways_vel = velocity.dot( Vector2(0, 1).rotated( rotation ) )
	var front_vel = velocity.dot( Vector2(1, 0).rotated( rotation ) )
	velocity = Vector2( front_vel * front_aero , sideways_vel * side_aero ).rotated( rotation )

func turn_process() -> void:
	var turn_factor = 0
	for i in range(0, len(raycasts) / 2):
		turn_factor += raycasts[i].get_turn_factor()
	for i in range(len(raycasts) / 2 + 1, len(raycasts)):
		turn_factor += raycasts[i].get_turn_factor()
	turn(turn_factor)

func accel_process() -> void:
	var accel_factor = 0
	for i in raycasts:
		accel_factor += i.get_accel_factor()
	accel(accel_factor)

func _physics_process(delta: float) -> void:
	forces()
	turn_process()
	accel_process()
	
	distance += velocity.dot( Vector2(1, 0).rotated( rotation ) )
	penalty_remaining -= delta
	
	if move_and_slide():
		velocity = get_last_slide_collision().get_normal() * velocity.length() * 0.3
		penalty_remaining = 3 # Crashing penalty
		
	if track.local_to_map(position/2) == track.end_cell:
		if not base.initializing:
			base.next_gen(self)
