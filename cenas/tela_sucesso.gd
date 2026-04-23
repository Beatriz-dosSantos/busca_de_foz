extends CanvasLayer

func _ready():
	hide() 

func aparecer():
	show()
	get_tree().paused = true 

func _on_botao_menu_pressed():
	get_tree().paused = false 
	
	get_tree().change_scene_to_file("res://menu/menu_princ.tscn")
