extends Node2D

var timer = 0
@export var time_per_gen = 15

@onready var cars = []
@onready var track = $Track
@onready var camera = $Camera

@export var generation = 0
@export var car_count = 50
@export var rays = 8 #per side + 1 middle
@export var bits_accuracy = 10
@export var ray_len = 1000
@export var mutation_chance = 0.01

func _ready() -> void:
	spawn_cars(car_count)

func spawn_cars(x : int, top_car : String = ''):
	if not top_car: 
		top_car = "0".repeat((rays+1) * bits_accuracy * 6)
		print("No top car, defaulting (" + str((rays+1) * bits_accuracy * 6) + " bits)")
	cars.clear()
	cars.append( load("res://Nodes/car.tscn").instantiate() ) 
	cars[0].init_code(rays, ray_len, bits_accuracy, top_car)
	cars[0].name = "best"
	cars[0].modulate = Color.RED
	cars[0].z_index = 2
	for i in range(1,x):
		cars.append( load("res://Nodes/car.tscn").instantiate() )
		cars[i].init_code( rays, ray_len, bits_accuracy, mutate(top_car, mutation_chance) )
	for car in cars:
		add_child(car)
		car.global_position = Vector2(track.start_pos.x * track.scale.x, track.start_pos.y * track.scale.y)

func select_best() -> Car:
	var max_dist = -1
	var max_index = 0
	var best_dist = 0
	for i in range( len(cars) ):
		if not is_instance_valid(cars[i]): continue
		if cars[i].tiles_travelled > max_dist:
			max_dist = cars[i].tiles_travelled
			max_index = i
		if cars[i].tiles_travelled == max_dist and cars[i].distance < best_dist:
			max_dist = cars[i].tiles_travelled
			max_index = i
	return cars[max_index]

func mutate(code : String, chance : float) -> String:
	var new_code = []
	for i in code:
		if randf() < chance:
			if i == '0': new_code.append('1')
			else: new_code.append('0')
		else: new_code.append(i)
	return ''.join(new_code)

func next_gen() -> void:
	generation += 1
	var best_car = select_best().code
	for i in cars:
		if is_instance_valid(i):
			i.queue_free()
	spawn_cars(car_count, best_car)

func _physics_process(delta: float) -> void:
	timer += delta
	if timer > 10:
		timer = 0
		next_gen()

func _on_button_pressed() -> void:
	mutation_chance = 0.01
	next_gen()

func _on_button_2_pressed() -> void:
	mutation_chance = 0.25
	next_gen()
