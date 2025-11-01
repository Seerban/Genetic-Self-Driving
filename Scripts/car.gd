extends CharacterBody2D
class_name Car

# Variables managed by base.gd when spawned

@export var code : String # genetic binary code
@export var distance : float = 0 # distance travelled
var visited_tiles : Array[Vector2i]
var last_tile := Vector2i.ZERO

var acceleration = 5 # linear acceleration to top_speed
var brake_factor = 5 # multiplier to backwards acceleration under braking
var top_speed = 1000
var max_turn = 10 # turning multiplier
var turn_speed_factor = 2 # speed negative influence over turning (1 = no turning at maxspeed)
var front_aero = 0.995 # forward damping
var side_aero = 0.95 # sideways damping

var penalty_remaining = 0 # penalty to top speed for bad behaviour
var penalty_factor = 0.15

var raycasts : Array[GeneticRayCast2D]
var raycast_length = 750
@export var raycast_count = 3. # per side + 1 middle

@onready var track : TileMapLayer
@onready var base : Node2D

func init_code(rays : int, bits_accuracy : int, code : String) -> void:
	self.raycast_count = rays
	self.code = code
	if len(code) == (rays+1) * bits_accuracy * 6:
		var rayi = 0
		for i in range(0, 90, 90 / raycast_count):
			var ray = GeneticRayCast2D.new(bits_accuracy, code.substr(rayi*bits_accuracy*6, bits_accuracy*6), raycast_length )
			var ray2 = GeneticRayCast2D.new(bits_accuracy, code.substr(rayi*bits_accuracy*6, bits_accuracy*6), raycast_length )
			
			ray2.negated = true # rays are symmetrical genome-wise
			rayi += 1
			
			ray.collision_mask = 1
			ray2.collision_mask = 1
			
			ray.target_position = Vector2(0, raycast_length)
			ray2.target_position = Vector2(0, raycast_length)
			
			ray.rotation_degrees = -i
			ray2.rotation_degrees = 180 + i
			
			raycasts.append(ray)
			add_child(ray)
			raycasts.append(ray2)
			add_child(ray2)
	else:
		print("Genome length mismatch: ", len(code))

func _ready() -> void:
	track = get_tree().get_first_node_in_group("Track")
	base = get_parent()

func accel(x) -> void:
	x = clamp(x, -1, 1)
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
		turn_factor += raycasts[i].get_turn_factor() / raycast_count
	for i in range(len(raycasts) / 2 + 1, len(raycasts)):
		turn_factor += raycasts[i].get_turn_factor() / raycast_count
	turn(turn_factor)

func accel_process() -> void:
	var accel_factor = 0
	for i in raycasts:
		accel_factor += i.get_accel_factor() / raycast_count
	accel(accel_factor)

func get_tile_pos() -> Vector2i:
	return track.local_to_map(position/2)

func disable():
	acceleration = 0
	max_turn = 0
	velocity = Vector2.ZERO
	distance = 0

func _physics_process(delta: float) -> void:
	forces()
	turn_process()
	accel_process()
	
	# Add distance travelled
	distance += velocity.dot( Vector2(1, 0).rotated( rotation ) ) - abs(velocity.dot( Vector2(0, 1).rotated( rotation ) ))
	penalty_remaining -= delta
	
	if move_and_slide():
		velocity = get_last_slide_collision().get_normal() * velocity.length() * 0.3
		penalty_remaining = 3 # Crashing penalty
		distance *= 0.5
		
	# Check for finish line
	if get_tile_pos() == track.end_cell:
		if not base.initializing:
			base.next_gen(self)
	
	# Check for backtracking
	if get_tile_pos() != last_tile:
		last_tile = get_tile_pos()
		if last_tile in visited_tiles:
			disable()
		visited_tiles.append(last_tile)
