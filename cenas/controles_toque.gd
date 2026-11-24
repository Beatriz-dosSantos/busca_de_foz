extends Node2D

const FORCAR_NO_PC := true

const ESCALA_ICONE := 3.0
const ESCALA_PAUSA := 2.0
const MARGEM := 24.0
const ESPACO := 20.0

var player = null
var btn_esquerda: TouchScreenButton
var btn_direita: TouchScreenButton
var btn_pular: TouchScreenButton
var btn_atacar: TouchScreenButton
var btn_pausa: TouchScreenButton

static func deve_aparecer() -> bool:
	return FORCAR_NO_PC or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = get_parent().get_parent()

	btn_esquerda = _criar_botao("esquerda", "esquerda", ESCALA_ICONE)
	btn_direita = _criar_botao("direita", "direita", ESCALA_ICONE)
	btn_pular = _criar_botao("pular", "pular", ESCALA_ICONE)
	btn_atacar = _criar_botao("atacar", "atacar", ESCALA_ICONE)
	btn_pausa = _criar_botao("pausa", "", ESCALA_PAUSA)
	btn_pausa.pressed.connect(_on_pausa)

	btn_esquerda.passby_press = true
	btn_direita.passby_press = true

	_posicionar()
	get_viewport().size_changed.connect(_posicionar)
	call_deferred("_garantir_menu_pause")

func _criar_botao(icone: String, acao: String, escala: float) -> TouchScreenButton:
	var b := TouchScreenButton.new()
	b.texture_normal = load("res://assets/toque/%s.png" % icone)
	b.texture_pressed = load("res://assets/toque/%s_press.png" % icone)
	b.scale = Vector2(escala, escala)
	b.action = acao
	b.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(b)
	return b

func _posicionar():
	var tela: Vector2 = get_viewport().get_visible_rect().size
	var t := 32.0 * ESCALA_ICONE
	var base_y := tela.y - MARGEM - t

	btn_esquerda.position = Vector2(MARGEM, base_y)
	btn_direita.position = Vector2(MARGEM + t + ESPACO, base_y)

	btn_pular.position = Vector2(tela.x - MARGEM - t, base_y)
	btn_atacar.position = Vector2(tela.x - MARGEM - 2.0 * t - ESPACO, base_y)

	btn_pausa.position = Vector2(tela.x - MARGEM - 32.0 * ESCALA_PAUSA, MARGEM)

func _process(_delta):
	var pausado := get_tree().paused
	if pausado:
		_soltar_acoes()
	var morto: bool = player != null and player.get("is_dead") == true
	var jogo_visivel := not pausado and not morto

	for b in [btn_esquerda, btn_direita, btn_pular, btn_atacar]:
		b.visible = jogo_visivel
	btn_pausa.visible = jogo_visivel

func _soltar_acoes():
	for acao in ["esquerda", "direita", "pular", "atacar"]:
		if Input.is_action_pressed(acao):
			Input.action_release(acao)

func _on_pausa():
	var menu = get_tree().get_first_node_in_group("menu_pause")
	if menu:
		menu.alternar_pause()

func _garantir_menu_pause():
	if get_tree().get_first_node_in_group("menu_pause") == null and get_tree().current_scene:
		var menu = load("res://cenas/menu_pause.tscn").instantiate()
		get_tree().current_scene.add_child(menu)
