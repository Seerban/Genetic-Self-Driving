extends Node2D

var timer : float = 0
@export var time_per_gen := 5
@export var camera_mode := 0
var best_car : Car # used for camera view

@onready var cars = []
@onready var track = $Track
@onready var camera = $Camera
@onready var ui = $UI

@export var generation = 0
@export var car_count = 25
@export var rays = 7 # per side + 1 middle
@export var bits_accuracy = 8
@export var ray_len = 600
@export var mutation_chance = 0.04

func _ready() -> void:
	spawn_cars(car_count)

func spawn_cars(x : int, top_car : String = ''):
	if not top_car or len(top_car) != bits_accuracy * (rays+1) * 6: 
		top_car = "0".repeat((rays+1) * bits_accuracy * 6)
		generation = 1
		get_node("UI/TopUI/GenerationData/Generation").text = "Generation: 1"
		get_node("UI/TopUI/GenerationData/Bits").text = "Bits per car: " + str(len(top_car))
		print("No top car, defaulting (" + str((rays+1) * bits_accuracy * 6) + " bits)")
	cars.clear()
	cars.append( load("res://Nodes/car.tscn").instantiate() ) 
	cars[0].init_code(rays, ray_len, bits_accuracy, top_car)
	cars[0].name = "best"
	cars[0].modulate = Color.RED
	cars[0].z_index = 2
	best_car = cars[0]
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
	get_node("UI/TopUI/GenerationData/Generation").text = "Generation: " + str(generation)
	best_car = select_best()
	for i in cars:
		if is_instance_valid(i):
			i.queue_free()
	spawn_cars(car_count, best_car.code)

func _physics_process(delta: float) -> void:
	timer += delta
	if timer > time_per_gen:
		timer = 0
		next_gen()
	if camera_mode == 1:
		if is_instance_valid(best_car):
			camera.position = best_car.position

func _on_mutation_slider_value_changed(value: float) -> void:
	mutation_chance = value / 100
	ui.get_node("Sidebar/MutationLabel").text = "Mutation Chance: " + str(value) + "%"

func _on_rays_slider_value_changed(value: float) -> void:
	rays = value
	ui.get_node("Sidebar/RaysLabel").text = "Raycasts: " + str(int(value)) + " per side"

func _on_length_slider_value_changed(value: float) -> void:
	ray_len = value
	ui.get_node("Sidebar/LengthLabel").text = "Raycast Length: " + str(int(value))

func _on_car_slider_value_changed(value: float) -> void:
	car_count = int(value)
	ui.get_node("Sidebar/CarLabel").text = "Car Count: " + str(int(value))

func _on_bits_slider_value_changed(value: float) -> void:
	bits_accuracy = int(value)
	get_node("UI/Sidebar/BitsLabel").text = "Bits per Ray: " + str(int(value))

func _on_full_view_pressed() -> void:
	camera.zoom = Vector2(0.14, 0.14)
	camera.position = Vector2(20000, 16000)
	camera_mode = 0

func _on_spec_best_pressed() -> void:
	camera.zoom = Vector2(0.75, 0.75)
	camera_mode = 1

func _on_time_slider_value_changed(value: float) -> void:
	time_per_gen = value
	ui.get_node("Sidebar/TimeLabel").text = "Seconds per Generation: " + str(int(value))

func _on_timer_timeout() -> void:
	var exists = false
	for i in cars:
		if i.acceleration != 0:
			exists = true
	if not exists:
		timer += 60
