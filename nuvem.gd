extends CharacterBody2D

const BotaoProsseguir = preload("res://cenas/botao_prosseguir.gd")

enum Estado { VOANDO, DESCENDO, VULNERAVEL, SUBINDO }
enum Movimento { PARADO, PATRULHAR, PERSEGUIR }

@export var projetil_cena: PackedScene = preload("res://cenas/projetil_raio.tscn")
@export var dano_contato: int = 10
@export var vida_max: int = 80
@export var altura_descida: float = 300.0
@export var tiros_para_descer: int = 3
@export var tempo_no_chao: float = 3.0
@export var duracao_movimento: float = 0.6
@export var margem: float = 40.0

@export var modo_movimento: Movimento = Movimento.PATRULHAR
@export var velocidade_lateral: float = 120.0
@export var alcance_patrulha: float = 560.0

@export var intervalo_ataque: float = 1.2
@export var velocidade_animacao_ataque: float = 1.6
@export var quadro_do_tiro: int = -1

@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D
@onready var ponto_de_tiro: Marker2D = $Marker2D
@onready var barra_vida = $TextureProgressBar
@onready var timer: Timer = $Timer

var vida: int = 80
var estado: int = Estado.VOANDO
var tiros_dados: int = 0
var y_alto: float
var y_baixo: float
var x_inicial: float
var dir_patrulha: int = 1
var morto := false
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

	x_inicial = global_position.x
	y_alto = global_position.y
	y_baixo = y_alto + altura_descida

func _primeira_animacao(nomes: Array) -> String:
	for nome in nomes:
		if animacao.sprite_frames.has_animation(nome):
			return nome
	return ""

func area_visivel() -> Rect2:
	var cam = get_viewport().get_camera_2d()
	if cam == null:
		return Rect2()
	var tamanho = get_viewport_rect().size / cam.zoom
	var centro = cam.get_screen_center_position()
	var canto = centro - tamanho * 0.5 + Vector2(margem, margem)
	return Rect2(canto, tamanho - Vector2(margem, margem) * 2.0)

func _physics_process(delta):
	if morto:
		return
	if estado == Estado.VOANDO:
		mover_lados(delta)

	var area = area_visivel()
	if area != Rect2():
		global_position.x = clamp(global_position.x, area.position.x, area.end.x)
		if estado == Estado.VOANDO:
			global_position.y = clamp(global_position.y, area.position.y, area.end.y)

	var player = get_tree().get_first_node_in_group("player")
	if player:
		animacao.flip_h = player.global_position.x < global_position.x

func mover_lados(delta):
	match modo_movimento:
		Movimento.PATRULHAR:
			global_position.x += velocidade_lateral * dir_patrulha * delta
			if global_position.x > x_inicial + alcance_patrulha:
				dir_patrulha = -1
			elif global_position.x < x_inicial - alcance_patrulha:
				dir_patrulha = 1
		Movimento.PERSEGUIR:
			var player = get_tree().get_first_node_in_group("player")
			if player:
				global_position.x = move_toward(
					global_position.x, player.global_position.x, velocidade_lateral * delta)
		Movimento.PARADO:
			pass

func _on_timer_timeout():
	iniciar_ataque()

func iniciar_ataque():
	if morto or atacando or machucado or estado != Estado.VOANDO:
		return
	if get_tree().get_first_node_in_group("player") == null:
		return
	if anim_ataque == "":
		atirar()
		return
	atacando = true
	ja_atirou = false
	animacao.speed_scale = velocidade_animacao_ataque
	animacao.play(anim_ataque)

func _quadro_do_tiro() -> int:
	if quadro_do_tiro >= 0:
		return quadro_do_tiro
	return animacao.sprite_frames.get_frame_count(anim_ataque) - 1

func _on_quadro_mudou():
	if atacando and not ja_atirou and animacao.animation == anim_ataque and animacao.frame >= _quadro_do_tiro():
		ja_atirou = true
		atirar()

func atirar():
	if morto or estado != Estado.VOANDO:
		return
	var player = get_tree().get_first_node_in_group("player")
	if projetil_cena == null or player == null:
		return

	var projetil = projetil_cena.instantiate()
	projetil.top_level = true
	get_tree().current_scene.add_child(projetil)
	projetil.global_position = ponto_de_tiro.global_position
	var centro_do_player = player.global_position + Vector2(0, -20)
	projetil.direcao = (centro_do_player - ponto_de_tiro.global_position).normalized()

	tiros_dados += 1

func _on_animacao_terminou():
	if morto:
		return
	if animacao.animation == anim_ataque:
		atacando = false
		animacao.speed_scale = 1.0
		animacao.play(anim_idle)
		if tiros_dados >= tiros_para_descer:
			descer()
	elif animacao.animation == anim_dano:
		machucado = false
		animacao.play(anim_idle)

func descer():
	estado = Estado.DESCENDO
	var t = create_tween()
	t.tween_property(self, "global_position:y", y_baixo, duracao_movimento).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await t.finished
	if morto or is_queued_for_deletion(): return
	estado = Estado.VULNERAVEL
	await get_tree().create_timer(tempo_no_chao).timeout
	if morto or is_queued_for_deletion(): return
	subir()

func subir():
	estado = Estado.SUBINDO
	var t = create_tween()
	t.tween_property(self, "global_position:y", y_alto, duracao_movimento).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	if morto or is_queued_for_deletion(): return
	tiros_dados = 0
	estado = Estado.VOANDO
	if not machucado:
		animacao.play(anim_idle)

func receber_dano(dano: int):
	if morto or estado == Estado.VOANDO or estado == Estado.SUBINDO:
		return
	vida -= dano
	barra_vida.mostrar(vida, vida_max)
	if vida <= 0:
		morrer()
	elif anim_dano != "":
		machucado = true
		atacando = false
		animacao.speed_scale = 1.0
		animacao.play(anim_dano)
		animacao.frame = 0

func morrer():
	if morto:
		return
	morto = true
	atacando = false
	machucado = false
	timer.stop()
	remove_from_group("inimigo")
	$CollisionShape2D.set_deferred("disabled", true)
	barra_vida.visible = false
	animacao.modulate = Color.WHITE
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
