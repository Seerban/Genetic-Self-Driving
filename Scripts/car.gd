extends CharacterBody2D

@export var acceleration = 20
@export var top_speed = 300
@export var max_turn_degrees = 2
@export var front_aero = 0.98
@export var sideways_aero = 0.95

func accel(reverse = false) -> void:
	var accel_mult = 1
	if reverse: accel_mult *= -0.333
	velocity = velocity.move_toward(Vector2(top_speed, 0).rotated(rotation), acceleration * accel_mult)

func turn(x) -> void:
	x = clamp(x, -1, 1)
	#dif velocity.dot( Vector2(1,0).rotated(rotation) ) < 0: x = -x
	rotation_degrees += x * max_turn_degrees * min(velocity.length() / top_speed, 1)

func forces() -> void:
	var sideways_vel = velocity.dot( Vector2(0, 1).rotated( rotation ) )
	var front_vel = velocity.dot( Vector2(1, 0).rotated( rotation ) )
	print(sideways_vel)
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
