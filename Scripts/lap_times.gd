extends ColorRect
class_name LapTimer

@onready var template = $Scroll/VBox/Template 
@onready var vbox = $Scroll/VBox

func add_time(gen, secs):
	var temp = template.duplicate()
	temp.get_child(0).text = str(gen)
	temp.get_child(1).text = str(int(secs)) + "." + str(int( secs * 1000) % 1000)
	if secs < 0: temp.get_child(1).text = "DNF"
		
	vbox.add_child(temp)
	vbox.move_child(temp, 1)
