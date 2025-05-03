extends TileMapLayer

@export var start_pos : Vector2

func _ready() -> void:
	start_pos = map_to_local(get_used_cells_by_id( 0, Vector2i(2, 2) )[0] )
	
