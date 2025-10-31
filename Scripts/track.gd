extends TileMapLayer

@export var start_pos : Vector2
@export var clock_pos : Vector2
@export var end_cell : Vector2i
@export var start_cell : Vector2i

@onready var timer

func _ready() -> void:
	start_pos = map_to_local(get_used_cells_by_id(0, Vector2i(2, 2) )[0] )
	clock_pos = map_to_local(get_used_cells_by_id(0, Vector2i(2, 4))[0] )
	end_cell = get_used_cells_by_id(0, Vector2i(2, 3) )[0]
	start_cell = get_used_cells_by_id( 0, Vector2i(2, 2) )[0]
	
	timer = load("res://Nodes/lap_times.tscn").instantiate() as Control
	timer.position = Vector2(clock_pos.x - timer.size.x / 2, clock_pos.y - timer.size.y / 2)
	add_child(timer)

# -1 time for DNF
func add_time(gen, time):
	print("Addingg time", gen, ' ', time)
	timer.add_time(gen, time)
