extends CanvasLayer

const LARGURA_BASE := 1152.0
const ALTURA_BASE := 648.0

@export var camada_nuvens: NodePath = ^"ParallaxLayer5"
@export var velocidade_nuvens: float = -12.0

var camadas: Array = []
var deriva_nuvens := 0.0
var cam_x_inicial = null
var k := 1.0
var origem := Vector2.ZERO

func _ready():
	layer = -100
	for camada in get_children():
		if not camada is Node2D:
			continue
		var sprite: Sprite2D = null
		for filho in camada.get_children():
			if filho is Sprite2D and filho.texture:
				sprite = filho
				break
		if sprite == null:
			continue
		var largura_local: float = sprite.texture.get_width() * sprite.scale.x
		var espelhar: bool = camada.get_meta("espelhar", false)
		for lado in [-2, -1, 1, 2]:
			var copia: Sprite2D = sprite.duplicate()
			copia.position.x += lado * largura_local
			if espelhar and abs(lado) == 1:
				copia.flip_h = not sprite.flip_h
			camada.add_child(copia)
		camadas.append({
			"no": camada,
			"pos": camada.position,
			"escala": camada.scale,
			"largura_local": largura_local,
			"fator": float(camada.get_meta("fator", 0.5)),
			"espelhar": espelhar,
		})
	_ajustar_tela()
	get_viewport().size_changed.connect(_ajustar_tela)

func _ajustar_tela():
	var tela: Vector2 = get_viewport().get_visible_rect().size
	k = max(tela.x / LARGURA_BASE, tela.y / ALTURA_BASE)
	origem = (tela - Vector2(LARGURA_BASE, ALTURA_BASE) * k) * 0.5
	for info in camadas:
		info.no.scale = info.escala * k

func _process(delta):
	var desloc_chao := 0.0
	var cam := get_viewport().get_camera_2d()
	if cam:
		var cx := cam.get_screen_center_position().x
		if cam_x_inicial == null:
			cam_x_inicial = cx
		desloc_chao = -(cx - cam_x_inicial) * cam.zoom.x
	deriva_nuvens += velocidade_nuvens * delta
	var nuvens = get_node_or_null(camada_nuvens)

	for info in camadas:
		var d: float = desloc_chao * info.fator
		if info.no == nuvens:
			d += deriva_nuvens
		var periodo: float = info.largura_local * info.escala.x * k * (2.0 if info.espelhar else 1.0)
		d = fposmod(d + periodo * 0.5, periodo) - periodo * 0.5
		info.no.position = origem + info.pos * k + Vector2(d, 0)
