extends TileMapLayer

@export var start_pos : Vector2i
@export var start_cell : Vector2i

func _ready() -> void:
	start_pos = map_to_local(get_used_cells_by_id( 0, Vector2i(2, 2) )[0] )
	start_cell = get_used_cells_by_id( 0, Vector2i(2, 2) )[0]
