extends Node2D

func _ready() -> void:
	var car = load("res://Nodes/car.tscn").instantiate()
	add_child(car)
