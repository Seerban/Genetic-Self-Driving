extends Label

@onready var base = $".."

func _physics_process(delta: float) -> void:
	text = "GENERATION: " + str(base.generation)
