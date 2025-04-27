extends Node2D

@onready var car
@onready var camera = $Camera

func _ready() -> void:
	car = load("res://Nodes/car.tscn").instantiate()
	var track = load("res://Nodes/track.tscn").instantiate()
	add_child(track)
	add_child(car)
	car.global_position = track.start_pos * track.scale

func _physics_process(delta: float) -> void:
	camera.global_position = car.global_position
