extends CharacterBody2D

@export var projetil_cena: PackedScene
@export var item_cena: PackedScene = preload("res://cenas/item.tscn")
@export var vida_max: int = 120
@export var velocidade: float = 70.0
@export var alcance: float = 260.0       
@export var flocos_por_rajada: int = 3  
@export var GRAVIDADE: int = 900

@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D
@onready var ponto_de_tiro: Marker2D = $Marker2D
@onready var barra_vida = $ProgressBar

var vida: int = 120
var x_inicial: float
var dir: int = 1

func _ready():
	vida = vida_max
	animacao.play("movimento")
	barra_vida.max_value = vida_max
	barra_vida.value = vida
	x_inicial = global_position.x

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVIDADE * delta
	else:
		velocity.y = 0

	velocity.x = velocidade * dir
	if global_position.x > x_inicial + alcance:
		dir = -1
	elif global_position.x < x_inicial - alcance:
		dir = 1

	var player = get_tree().get_first_node_in_group("player")
	if player:
		animacao.flip_h = player.global_position.x < global_position.x

	move_and_slide()

func _on_timer_timeout():
	atirar()

func atirar():
	var player = get_tree().get_first_node_in_group("player")
	if projetil_cena == null or player == null:
		return
	var centro = player.global_position + Vector2(0, -20)
	var base = (centro - ponto_de_tiro.global_position).normalized()
	var base_ang = base.angle()
	# leque de flocos
	var espalhar := 0.30
	var inicio := -espalhar * (flocos_por_rajada - 1) / 2.0
	for i in range(flocos_por_rajada):
		var ang = base_ang + inicio + espalhar * i
		var floco = projetil_cena.instantiate()
		floco.global_position = ponto_de_tiro.global_position
		floco.direcao = Vector2(cos(ang), sin(ang))
		get_tree().current_scene.add_child(floco)

func receber_dano(dano: int):
	vida -= dano
	barra_vida.value = vida
	if vida <= 0:
		morrer()

func morrer():
	if item_cena != null:
		var novo_item = item_cena.instantiate()
		novo_item.global_position = global_position
		get_parent().call_deferred("add_child", novo_item)
	queue_free()
