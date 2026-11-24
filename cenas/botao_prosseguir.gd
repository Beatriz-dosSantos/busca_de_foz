extends CanvasLayer

const FONTE := preload("res://menu/joystix monospace.otf")

static func mostrar(arvore: SceneTree) -> void:
	var cena := arvore.current_scene
	if cena == null or cena.get_node_or_null("BotaoProsseguir") != null:
		return
	var camada = load("res://cenas/botao_prosseguir.gd").new()
	camada.name = "BotaoProsseguir"
	cena.add_child(camada)

var botao: Button

func _ready():
	layer = 5
	Sons.tocar(Sons.SUCESSO)

	botao = Button.new()
	botao.text = "Prosseguir"
	botao.add_theme_font_override("font", FONTE)
	botao.add_theme_font_size_override("font_size", 28)
	botao.add_theme_color_override("font_color", Color.WHITE)
	botao.add_theme_stylebox_override("normal", _estilo(Color(0.83, 1.0, 1.0, 0.35)))
	botao.add_theme_stylebox_override("hover", _estilo(Color(0.66, 0.63, 1.0, 0.5)))
	botao.add_theme_stylebox_override("pressed", _estilo(Color(0.27, 0.45, 1.0, 0.76)))
	botao.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	botao.focus_mode = Control.FOCUS_NONE
	botao.set_anchors_preset(Control.PRESET_CENTER)
	botao.offset_left = -160
	botao.offset_right = 160
	botao.offset_top = -36
	botao.offset_bottom = 36
	botao.pivot_offset = Vector2(160, 36)
	botao.pressed.connect(_prosseguir)
	add_child(botao)

	botao.scale = Vector2(0.2, 0.2)
	create_tween().tween_property(botao, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _estilo(cor: Color) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = cor
	e.border_color = Color(0, 0.33, 0.53, 0.7)
	e.set_border_width_all(3)
	e.set_corner_radius_all(7)
	return e

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		_prosseguir()

func _prosseguir():
	var tela = get_tree().get_first_node_in_group("telasucesso")
	if tela != null and tela.has_method("aparecer"):
		tela.aparecer()
	queue_free()
