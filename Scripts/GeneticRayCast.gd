extends RayCast2D
class_name GeneticRayCast2D

var negated : bool
var genome_size : int
var coef_scale := 0.0002
var distance_scale := 0.005
var turn_coef = [0, 0 ,0]
var accel_coef = [0, 0 ,0]

@export var genome : String

func bin_to_value(s : String) -> float:
	var x = 0
	for i in range(genome_size):
		if s[i] != '0':
			x += 2 ** (genome_size - i - 1)
	x -= ((2 ** genome_size) - 1) / 2
	x *= coef_scale
	#print(s, " ", x)
	return x

func _to_string() -> String:
	return "GeneticRaycast<size:" + str(target_position.length()) + " genSize:" + str(genome_size) + " turnCoef:" + str(turn_coef) + " accelCoef:" + str(accel_coef) + ">"

#genome size = bits per coefifcient, 6 coefficients in total (3 for turn, 3 for acceleration)
func _init(gen_size : int = 6, gen : String = '', length : int = 200) -> void:
	distance_scale = 1. / length
	coef_scale = 2 / (2 ** genome_size)
	genome_size = gen_size
	target_position = Vector2(length, 0)
	if gen == '': gen = "0".repeat(genome_size * 6)
	if len(gen) != genome_size * 6:
		print("GENETICRAYCAST WRONG SIZE: " + str(len(gen)), " EXPECTED: " + str(genome_size*6) )
	assert( len(gen) == genome_size * 6 )
	
	genome = gen
	for i in range(0, 3):
		turn_coef[i] = bin_to_value( genome.substr( genome_size * i, genome_size ) )
	
	for i in range(3, 6):
		accel_coef[i - 3] = bin_to_value( genome.substr( genome_size * i, genome_size ) )

func get_turn_factor() -> float:
	var x = 0
	if not is_colliding(): x = target_position.length()
	else: x = global_position.distance_to( get_collision_point() )
	x *= distance_scale
	#print(turn_coef)
	x = turn_coef[0]*x**2 + turn_coef[1]*x + turn_coef[2]
	#print(x, ' ',turn_coef[0]*x**2, ' ',turn_coef[1]*x**2, ' ',turn_coef[2]*x**2)
	if negated: x *= -1
	x = clamp(x, -1, 1)
	return x

func get_accel_factor() -> float:
	var x = 0
	if not is_colliding(): x = target_position.length()
	else: x = global_position.distance_to( get_collision_point() )
	x *= distance_scale
	x = accel_coef[0]*x**2 + accel_coef[1]*x + accel_coef[2]
	x = clamp(x, -1, 1)
	return -x
