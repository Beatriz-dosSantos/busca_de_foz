extends CharacterBody2D

const BotaoProsseguir = preload("res://cenas/botao_prosseguir.gd")

@export var projetil_cena: PackedScene
@export var dano_contato: int = 10
@export var vida_max: int = 80
@export var distancia_visao: float = 300.0
@export var frame_do_tiro: int = 13
@export var dano_interrompe_ataque: bool = true
@export var debug: bool = false

@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D
@onready var ponto_de_tiro: Marker2D = $Marker2D
@onready var barra_vida = $"lixo vida"
@onready var timer: Timer = $Timer

var vida: int = 80
var atacando: bool = false
var pode_atacar: bool = true
var ja_atirou: bool = false
var machucado: bool = false
var morto: bool = false
var _tween: Tween
var _debug_t: float = 0.0

func _ready():
	if projetil_cena == null:
		push_warning("lixao: 'Projetil Cena' estava vazio, usando res://cenas/projetil_lixo.tscn")
		projetil_cena = load("res://cenas/projetil_lixo.tscn")
	vida = vida_max
	barra_vida.mostrar(vida, vida_max)

	animacao.sprite_frames.set_animation_loop("movimento", false)
	if animacao.sprite_frames.has_animation("dano"):
		animacao.sprite_frames.set_animation_loop("dano", false)
	if animacao.sprite_frames.has_animation("morre"):
		animacao.sprite_frames.set_animation_loop("morre", false)
	animacao.animation_finished.connect(_on_animacao_terminou)
	animacao.frame_changed.connect(_on_frame_changed)
	animacao.play("idle")

	timer.one_shot = true
	timer.stop()

func _physics_process(delta):
	if debug:
		_debug_t += delta
		if _debug_t >= 1.0:
			_debug_t = 0.0
			_debug_print()
	if atacando or machucado or not pode_atacar:
		return
	if _player_na_visao():
		_iniciar_ataque()

func _debug_print():
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		print("[lixao] NAO existe nenhum no no grupo 'player' nesta cena")
		return
	print("[lixao] dist=", int(global_position.distance_to(player.global_position)),
		" visao=", int(distancia_visao), " atacando=", atacando, " pode_atacar=", pode_atacar)

func _player_na_visao() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return false
	if "is_dead" in player and player.is_dead:
		return false
	return global_position.distance_to(player.global_position) <= distancia_visao

func _iniciar_ataque():
	if projetil_cena == null:
		return
	atacando = true
	pode_atacar = false
	ja_atirou = false
	animacao.play("movimento")

func _on_frame_changed():
	if atacando and not ja_atirou and animacao.animation == "movimento" and animacao.frame >= frame_do_tiro:
		ja_atirou = true
		_criar_projetil()

func _on_animacao_terminou():
	if morto:
		if animacao.animation == "morre":
			BotaoProsseguir.mostrar(get_tree())
		return
	match animacao.animation:
		"movimento":
			atacando = false
			animacao.play("idle")
			timer.start()
		"dano":
			machucado = false
			pode_atacar = false
			animacao.play("idle")
			timer.start()

func _on_timer_timeout():
	pode_atacar = true

func _criar_projetil():
	var player = get_tree().get_first_node_in_group("player")
	if projetil_cena == null or player == null:
		return
	var projetil = projetil_cena.instantiate()
	var centro_do_player = player.global_position + Vector2(0, -20)
	projetil.direcao = (centro_do_player - ponto_de_tiro.global_position).normalized()
	get_tree().current_scene.add_child(projetil)
	projetil.global_position = ponto_de_tiro.global_position
	projetil.add_collision_exception_with(self)

func receber_dano(dano: int):
	if morto:
		return
	vida -= dano
	barra_vida.mostrar(vida, vida_max)
	if vida <= 0:
		morrer()
	else:
		_tocar_dano()

func _tocar_dano():
	if not animacao.sprite_frames.has_animation("dano"):
		_piscar()
		return
	if atacando and not dano_interrompe_ataque:
		_piscar()
		return
	atacando = false
	machucado = true
	animacao.play("dano")
	animacao.frame = 0

func _piscar():
	if _tween:
		_tween.kill()
	animacao.modulate = Color(1, 0.3, 0.3)
	_tween = create_tween()
	_tween.tween_property(animacao, "modulate", Color.WHITE, 0.25)

func morrer():
	if morto:
		return
	morto = true
	atacando = false
	machucado = false
	timer.stop()
	set_physics_process(false)
	remove_from_group("inimigo")
	$CollisionShape2D.set_deferred("disabled", true)
	barra_vida.visible = false
	if _tween:
		_tween.kill()
	animacao.modulate = Color.WHITE

	if animacao.sprite_frames.has_animation("morre"):
		animacao.play("morre")
	else:
		push_warning("lixao: nao existe a animacao 'morre' no SpriteFrames; sumindo")
		BotaoProsseguir.mostrar(get_tree())
		queue_free()
