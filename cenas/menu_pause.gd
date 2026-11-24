extends CanvasLayer

func _ready():
	add_to_group("menu_pause")
	hide()

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		alternar_pause()

func _notification(what):
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		alternar_pause()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if OS.has_feature("mobile") and not get_tree().paused:
			alternar_pause()

func alternar_pause():
	var esta_pausado = get_tree().paused
	if esta_pausado and not visible:
		return

	get_tree().paused = !esta_pausado

	if get_tree().paused:
		show()
	else:
		hide()

func _on_button_pressed():
	alternar_pause()
