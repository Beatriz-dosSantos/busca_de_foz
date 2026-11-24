extends CanvasLayer

@export_file("*.tscn") var proxima_cena: String = ""
@export_multiline var mensagem: String = ""

const MUSICA_FINAL_CAMINHO := "res://assets/som/goodbye.wav"

const TEXTO_FINAL := "Finalmente de volta ao lar! Lembre-se que se chama Ciclo porque sempre se repete, quem sabe na sua próxima aventura ela descobrirá lugares mais distantes..."

@onready var fundo_final: AnimatedSprite2D = $FundoFinal
@onready var fundo_cor: ColorRect = $ColorRect
@onready var btn_prox: Button = $ColorRect/botaoProximo
@onready var btn_sair: Button = $ColorRect/botaoSair
@onready var l1: Label = $Label
@onready var l2: Label = $Label2
@onready var l3: Label = $Label3
@onready var musica: AudioStreamPlayer = $AudioStreamPlayer

func _ready():
	hide()

func aparecer():
	AjusteTela.usar_modo_fixo()
	show()
	get_tree().paused = true
	_parar_sons_da_fase()
	if proxima_cena == "":
		musica.stream = load(MUSICA_FINAL_CAMINHO)
		_mostrar_final()
	else:
		l1.text = "parabéns!"
		l2.text = "fase concluída com sucesso!"
		l3.text = mensagem
		l3.visible = mensagem != ""
		btn_prox.visible = true
		btn_sair.visible = false
	musica.play()

func _mostrar_final():
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.apagar_progresso()

	var material_pixel := ShaderMaterial.new()
	material_pixel.shader = preload("res://assets/intro/pixel_suave.gdshader")
	fundo_final.material = material_pixel
	fundo_final.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	fundo_final.visible = true
	fundo_final.play("default")
	fundo_cor.color = Color(0, 0, 0, 0.3)

	l1.text = "Sucesso!"
	l2.text = TEXTO_FINAL
	l2.add_theme_font_size_override("font_size", 24)
	l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l2.offset_left = -510
	l2.offset_right = 510
	l2.offset_top = 250
	l2.offset_bottom = 385
	l3.visible = false

	btn_prox.visible = false
	btn_sair.visible = OS.get_name() != "iOS"

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
		gs.avancar_fase()
		gs.salvar_progresso(proxima_cena)
	btn_prox.disabled = true
	LoadManager.loadScene(proxima_cena)

func _parar_sons_da_fase():
	var cena := get_tree().current_scene
	if cena == null:
		return
	for som in cena.find_children("*", "AudioStreamPlayer", true, false):
		if som != musica and not is_ancestor_of(som):
			som.stop()
	for som in cena.find_children("*", "AudioStreamPlayer2D", true, false):
		som.stop()

func _on_botao_sair_pressed():
	get_tree().quit()
