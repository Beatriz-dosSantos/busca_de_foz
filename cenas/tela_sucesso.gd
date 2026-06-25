extends CanvasLayer

@export_file("*.tscn") var proxima_cena: String = ""  
@export var item_recompensa: String = ""              

func _ready():
	hide()

func aparecer():
	show()
	get_tree().paused = true
	var btn_prox = get_node_or_null("ColorRect/botaoProximo")
	var l1 = get_node_or_null("Label")
	var l2 = get_node_or_null("Label2")
	var l3 = get_node_or_null("Label3")
	if proxima_cena == "":
		if l1: l1.text = "parabéns!"
		if l2: l2.text = "você venceu o jogo!"
		if l3: l3.text = "Foz finalmente voltou para o mar!"
		if btn_prox: btn_prox.visible = false
	else:
		if l1: l1.text = "parabéns!"
		if l2: l2.text = "fase concluída com sucesso!"
		if l3: l3.text = "clique em \"Próxima fase\" para continuar"
		if btn_prox: btn_prox.visible = true

func _on_botao_menu_pressed():
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.iniciar_jogo()   
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu/menu_princ.tscn")

func _on_botao_proximo_pressed():
	if proxima_cena == "":
		return
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.avancar_fase(item_recompensa)
	get_tree().paused = false
	LoadManager.loadScene(proxima_cena)
