extends CharacterBody2D

var fundo_poluicao = preload("res://assets/barra de vida/termometro poluicao1.png")
var cheio_poluicao = preload("res://assets/barra de vida/termometro poluicao cheio.png")
var fundo_termo = preload("res://assets/barra de vida/termometro calor1.png")
var cheio_termo = preload("res://assets/barra de vida/termometro calor cheio.png")

@onready var onda = preload("res://cenas/onda.tscn")
var cena_game_over = preload("res://cenas/tela_game_over.tscn")
var cena_go_chuva = preload("res://cenas/tela_game_over_chuva.tscn")
var cena_go_sol = preload("res://cenas/tela_game_over_sol.tscn")
const ControlesToque = preload("res://cenas/controles_toque.gd")

@onready var barra_vida: TextureProgressBar = $CanvasLayer/ProgressBar
@onready var texto_vida: Label = $CanvasLayer/TextoVida
@onready var texto_barra: Label = $CanvasLayer/TextoBarra

@export var SPEED : int = 170
@export var JUMP_FORCE : int = 300
@export var GRAVITY : int = 900
const ALTURA_BASE_ONDA := 40.0

var escala_mov := Vector2.ONE

@export var vida_max : int = 100 

var is_attacking = false
var is_dead = false
var vida: int = 0 

var dano_onda: int = 5
var _tween: Tween

@export var dano_contato_padrao: int = 10
@export var invencivel_apos_dano: float = 1.0
var _inimigos_encostando: Array = []
var _tempo_invencivel := 0.0

func _ready():
	escala_mov = global_scale.abs()
	vida = 0 
	barra_vida.max_value = vida_max
	barra_vida.value = vida
	atualizar_texto_vida()
	_configurar_tema_da_barra()
	
	var gs = get_node_or_null("/root/GameState")
	if gs:
		dano_onda = gs.dano_onda

	if ControlesToque.deve_aparecer():
		$CanvasLayer.add_child(ControlesToque.new())

	_criar_area_de_contato()

	var sprite = $Flip/AnimatedSprite2D
	sprite.animation_finished.connect(_on_animacao_terminou)
	if sprite.sprite_frames.has_animation("machucou"):
		sprite.sprite_frames.set_animation_loop("machucou", false)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * escala_mov.y * delta

	if is_dead:
		velocity.x = 0
		move_and_slide()
		return
	
	_verificar_contato(delta)

	var direction = Input.get_axis("esquerda", "direita")
	if direction:
		velocity.x = direction * SPEED * escala_mov.x
		if is_on_floor() and not is_attacking and not _machucado():
			$Flip/AnimatedSprite2D.play("andando")
	else:
		velocity.x = 0
		if is_on_floor() and not is_attacking and not _machucado():
			$Flip/AnimatedSprite2D.play("parada")

	if direction != 0:
		$Flip.scale.x = 1 if direction == 1 else -1

	if Input.is_action_just_pressed("pular") and is_on_floor():
		velocity.y -= JUMP_FORCE * escala_mov.y
		$Flip/AnimatedSprite2D.play("pulo")

	if Input.is_action_just_pressed("atacar") and not is_attacking and is_on_floor():
		atacar_onda()

	move_and_slide()

func atacar_onda():
	is_attacking = true
	Sons.tocar(Sons.ONDA, -0.26)
	$Flip/AnimatedSprite2D.play("ondular")
	var o = onda.instantiate()
	o.vel = $Flip.scale.x
	o.dano = dano_onda
	get_parent().add_child(o)
	o.global_position = Vector2($Flip/onda_pos.global_position.x, global_position.y - ALTURA_BASE_ONDA)
	await $Flip/AnimatedSprite2D.animation_finished
	is_attacking = false

func _criar_area_de_contato():
	var forma_corpo: CollisionShape2D = $CollisionShape2D
	var area := Area2D.new()
	area.name = "AreaContato"
	area.collision_layer = 0
	area.collision_mask = collision_mask
	area.monitorable = false
	var forma := CollisionShape2D.new()
	forma.shape = forma_corpo.shape
	forma.position = forma_corpo.position
	forma.scale = forma_corpo.scale * 1.15
	area.add_child(forma)
	add_child(area)
	area.body_entered.connect(func(corpo): if corpo.is_in_group("inimigo"): _inimigos_encostando.append(corpo))
	area.body_exited.connect(func(corpo): _inimigos_encostando.erase(corpo))

func _verificar_contato(delta):
	if _tempo_invencivel > 0.0:
		_tempo_invencivel -= delta
		return
	for inimigo in _inimigos_encostando.duplicate():
		if not is_instance_valid(inimigo) or not inimigo.is_in_group("inimigo"):
			_inimigos_encostando.erase(inimigo)
			continue
		var dano = inimigo.get("dano_contato")
		receber_dano(dano if dano != null else dano_contato_padrao)
		_tempo_invencivel = invencivel_apos_dano
		return

func receber_dano(dano: int):
	if is_dead: return
	vida += dano
	barra_vida.value = vida
	atualizar_texto_vida()
	if vida >= vida_max:
		morrer()
	else:
		_tocar_machucou()

func _machucado() -> bool:
	var sprite = $Flip/AnimatedSprite2D
	return sprite.animation == "machucou" and sprite.is_playing()

func _tocar_machucou():
	var sprite = $Flip/AnimatedSprite2D
	if not sprite.sprite_frames.has_animation("machucou"):
		_piscar()
		return
	sprite.play("machucou")
	sprite.frame = 0

func _piscar():
	var sprite = $Flip/AnimatedSprite2D
	if _tween:
		_tween.kill()
	sprite.modulate = Color(1, 0.3, 0.3)
	_tween = create_tween()
	_tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)

func _on_animacao_terminou():
	var sprite = $Flip/AnimatedSprite2D
	if sprite.animation == "machucou" and not is_dead:
		sprite.play("pulo" if not is_on_floor() else "parada")

func atualizar_texto_vida():
	texto_vida.text = str(vida) + "%"

func _cena_game_over_da_fase() -> PackedScene:
	match get_tree().current_scene.name:
		"fasefloreta", "fase2":
			return cena_go_chuva
		"fase4":
			return cena_go_sol
		_:
			return cena_game_over

func morrer():
	is_dead = true
	Sons.tocar(Sons.MORTE_FOZ)
	velocity.x = 0
	$Flip/AnimatedSprite2D.play("morte")
	await $Flip/AnimatedSprite2D.animation_finished
	var tela = _cena_game_over_da_fase().instantiate()
	get_tree().current_scene.add_child(tela)
	if tela.has_method("aparecer"):
		tela.aparecer()

func _configurar_tema_da_barra():
	var nome_da_cena = get_tree().current_scene.name
	if nome_da_cena == "fase1":
		barra_vida.texture_under = fundo_poluicao
		barra_vida.texture_progress = cheio_poluicao
		texto_barra.text = "POLUIÇÃO"
	else:
		barra_vida.texture_under = fundo_termo
		barra_vida.texture_progress = cheio_termo
		texto_barra.text = "TEMPERATURA"
