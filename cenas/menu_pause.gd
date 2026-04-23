extends CanvasLayer

func _ready():
	hide() 

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		alternar_pause()

func alternar_pause():
	var esta_pausado = get_tree().paused
	
	get_tree().paused = !esta_pausado
	
	if get_tree().paused:
		show()
	else:
		hide()

func _on_button_pressed():
	alternar_pause()
