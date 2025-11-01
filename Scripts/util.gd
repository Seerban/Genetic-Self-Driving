extends Node

func sigmoid(x: float) -> float:
	return 2.0 / (1.0 + exp(-x)) - 1.0
