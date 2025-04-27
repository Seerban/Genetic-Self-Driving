extends CharacterBody2D

@export var acceleration = 20
@export var top_speed = 1000
@export var max_turn = 2
@export var turn_speed_factor = 2 #1 = 0 turning at max speed
@export var front_aero = 0.98
@export var sideways_aero = 0.96

func accel(reverse = false) -> void:
	var accel_mult = 1
	if reverse: accel_mult *= -0.333
	velocity = velocity.move_toward(Vector2(top_speed, 0).rotated(rotation), acceleration * accel_mult)

func turn(x) -> void:
	x = clamp(x, -1, 1)
	var turn_mult = 0

	if velocity.length() > top_speed / 4:
		var speed_ratio = clamp(velocity.length() / (top_speed * turn_speed_factor), 0, 1)
		turn_mult = max_turn * (1.0 - speed_ratio)  # Less turn at high speed
	else:
		var speed_ratio = clamp(velocity.length() / (top_speed / 4 * turn_speed_factor), 0, 1)
		turn_mult = clamp( (max_turn - (max_turn * (1.0 - speed_ratio))) * 2, 0, max_turn)  # Less turn at high speed
		print(turn_mult)
	
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
	var turn = 0
	if Input.is_key_pressed(KEY_W): accel()
	if Input.is_key_pressed(KEY_S): accel(true)
	if Input.is_key_pressed(KEY_D): turn = 1
	if Input.is_key_pressed(KEY_A): turn = -1
	turn(turn)
	move_and_slide()
