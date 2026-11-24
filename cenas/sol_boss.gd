extends CharacterBody2D

const BotaoProsseguir = preload("res://cenas/botao_prosseguir.gd")

enum Estado { ALTO, DESCENDO, BAIXO, SUBINDO }

@export var projetil_cena: PackedScene
@export var vida_max: int = 320
@export var dano_contato: int = 10
@export var raios_por_rajada: int = 5
@export var tempo_no_alto: float = 5.0
@export var tempo_embaixo: float = 4.0
@export var duracao_movimento: float = 1.2
@export var altura_chao: float = 360.0
@export var margem_canto: float = 44.0
@export var recuo_ao_descer: float = 60.0
@export var amplitude_flutua: float = 6.0
@export var velocidade_flutua: float = 2.0
@export var intervalo_ataque: float = 1.6
@export var velocidade_animacao_ataque: float = 1.5
@export var quadro_do_tiro: int = -1

@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D
@onready var ponto_de_tiro: Marker2D = $Marker2D
@onready var barra_vida = $BarraVida
@onready var timer: Timer = $Timer

var vida: int = 320
var morto: bool = false
var estado: int = Estado.ALTO
var tempo_estado := 0.0
var lado := 1
var pos_base := Vector2.ZERO
var t := 0.0
var raio := 71.0
var _tween: Tween
var atacando := false
var ja_atirou := false
var machucado := false

var anim_idle := "movimento"
var anim_ataque := ""
var anim_dano := ""
var anim_morte := ""

func _ready():
	vida = vida_max
	anim_ataque = _primeira_animacao(["ataque"])
	anim_dano = _primeira_animacao(["machucou", "machuchou"])
	anim_morte = _primeira_animacao(["morte", "morre"])
	for nome in [anim_ataque, anim_dano, anim_morte]:
		if nome != "":
			animacao.sprite_frames.set_animation_loop(nome, false)
	animacao.animation_finished.connect(_on_animacao_terminou)
	animacao.frame_changed.connect(_on_quadro_mudou)
	animacao.play(anim_idle)
	barra_vida.mostrar(vida, vida_max)
	timer.wait_time = intervalo_ataque
	var quadro := animacao.sprite_frames.get_frame_texture(anim_idle, 0)
	if quadro:
		raio = quadro.get_width() * 0.5 * animacao.scale.x
	pos_base = global_position
	await get_tree().process_frame
	_escolher_lado()
	pos_base = _ponto_do_canto()
	global_position = pos_base

func _primeira_animacao(nomes: Array) -> String:
	for nome in nomes:
		if animacao.sprite_frames.has_animation(nome):
			return nome
	return ""

func _area_visivel() -> Rect2:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return Rect2(Vector2.ZERO, get_viewport_rect().size)
	var tamanho := get_viewport_rect().size / cam.zoom
	return Rect2(cam.get_screen_center_position() - tamanho * 0.5, tamanho)

func _ponto_do_canto() -> Vector2:
	var area := _area_visivel()
	var espaco_barra := 24.0
	var x := area.end.x - margem_canto - raio if lado == 1 else area.position.x + margem_canto + raio
	return Vector2(x, area.position.y + margem_canto + espaco_barra + raio)

func _escolher_lado():
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	lado = 1 if player.global_position.x < _area_visivel().get_center().x else -1

func _physics_process(delta):
	if morto:
		return
	t += delta * velocidade_flutua
	tempo_estado += delta
	match estado:
		Estado.ALTO:
			pos_base = pos_base.lerp(_ponto_do_canto(), min(1.0, delta * 3.0))
			if tempo_estado >= tempo_no_alto and not atacando:
				var x_baixo := pos_base.x - lado * recuo_ao_descer
				_mover_para(Vector2(x_baixo, altura_chao - raio + 6.0), Estado.DESCENDO, Estado.BAIXO)
		Estado.BAIXO:
			if tempo_estado >= tempo_embaixo and not atacando:
				_escolher_lado()
				_mover_para(_ponto_do_canto(), Estado.SUBINDO, Estado.ALTO)
	if estado == Estado.ALTO or estado == Estado.BAIXO:
		global_position = pos_base + Vector2(0, sin(t) * amplitude_flutua)

func _mover_para(destino: Vector2, durante: int, depois: int):
	estado = durante
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "global_position", destino, duracao_movimento) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _tween.finished
	if morto:
		return
	pos_base = global_position
	estado = depois
	tempo_estado = 0.0

func _on_timer_timeout():
	iniciar_ataque()

func iniciar_ataque():
	if morto or atacando or machucado:
		return
	if estado != Estado.ALTO and estado != Estado.BAIXO:
		return
	if anim_ataque == "":
		atirar(raios_por_rajada)
		return
	atacando = true
	ja_atirou = false
	animacao.speed_scale = velocidade_animacao_ataque
	animacao.play(anim_ataque)

func _quadro_do_tiro() -> int:
	if quadro_do_tiro >= 0:
		return quadro_do_tiro
	return int(animacao.sprite_frames.get_frame_count(anim_ataque) * 0.65)

func _on_quadro_mudou():
	if atacando and not ja_atirou and animacao.animation == anim_ataque and animacao.frame >= _quadro_do_tiro():
		ja_atirou = true
		atirar(raios_por_rajada)

func _on_animacao_terminou():
	if morto:
		return
	if animacao.animation == anim_ataque:
		atacando = false
		animacao.speed_scale = 1.0
		animacao.play(anim_idle)
	elif animacao.animation == anim_dano:
		machucado = false
		animacao.play(anim_idle)

func atirar(quantidade: int):
	var player = get_tree().get_first_node_in_group("player")
	if projetil_cena == null or player == null:
		return
	var centro = player.global_position + Vector2(0, -20)
	var base_ang = (centro - ponto_de_tiro.global_position).normalized().angle()
	var espalhar := 0.28
	var inicio := -espalhar * (quantidade - 1) / 2.0
	for i in range(quantidade):
		var ang = base_ang + inicio + espalhar * i
		var r = projetil_cena.instantiate()
		r.global_position = ponto_de_tiro.global_position
		r.direcao = Vector2(cos(ang), sin(ang))
		get_tree().current_scene.add_child(r)

func receber_dano(dano: int):
	if morto:
		return
	vida -= dano
	barra_vida.mostrar(vida, vida_max)
	if vida <= 0:
		vencer()
	elif anim_dano != "" and not atacando:
		machucado = true
		animacao.speed_scale = 1.0
		animacao.play(anim_dano)
		animacao.frame = 0

func vencer():
	if morto:
		return
	morto = true
	atacando = false
	machucado = false
	if _tween:
		_tween.kill()
	timer.stop()
	remove_from_group("inimigo")
	$CollisionShape2D.set_deferred("disabled", true)
	barra_vida.visible = false
	animacao.speed_scale = 1.0
	if anim_morte != "":
		animacao.play(anim_morte)
		await animacao.animation_finished
	else:
		var efeito := create_tween().set_parallel(true)
		efeito.tween_property(animacao, "modulate:a", 0.0, 0.6)
		efeito.tween_property(animacao, "scale", animacao.scale * 0.6, 0.6)
		await efeito.finished
	BotaoProsseguir.mostrar(get_tree())
	queue_free()
