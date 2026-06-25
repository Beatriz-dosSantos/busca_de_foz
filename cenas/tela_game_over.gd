extends CanvasLayer

func _ready():
	hide()

func aparecer():
	show()
	get_tree().paused = true

func _on_tentar_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_sair_pressed():
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.iniciar_jogo()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu/menu_princ.tscn")
