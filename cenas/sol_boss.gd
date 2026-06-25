extends CharacterBody2D

@export var projetil_cena: PackedScene
@export var vida_max: int = 320
@export var raios_por_rajada: int = 5     
@export var amplitude_flutua: float = 24.0
@export var velocidade_flutua: float = 1.5

@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D
@onready var ponto_de_tiro: Marker2D = $Marker2D
@onready var barra_vida = $ProgressBar

var vida: int = 320
var y_base: float
var t: float = 0.0
var morto: bool = false

func _ready():
	vida = vida_max
	animacao.play("movimento")
	barra_vida.max_value = vida_max
	barra_vida.value = vida
	y_base = global_position.y

func _physics_process(delta):
	t += delta * velocidade_flutua
	global_position.y = y_base + sin(t) * amplitude_flutua

func _on_timer_timeout():
	if morto:
		return
	atirar()

func atirar():
	var player = get_tree().get_first_node_in_group("player")
	if projetil_cena == null or player == null:
		return
	var centro = player.global_position + Vector2(0, -20)
	var base_ang = (centro - ponto_de_tiro.global_position).normalized().angle()
	var espalhar := 0.28
	var inicio := -espalhar * (raios_por_rajada - 1) / 2.0
	for i in range(raios_por_rajada):
		var ang = base_ang + inicio + espalhar * i
		var r = projetil_cena.instantiate()
		r.global_position = ponto_de_tiro.global_position
		r.direcao = Vector2(cos(ang), sin(ang))
		get_tree().current_scene.add_child(r)

func receber_dano(dano: int):
	if morto:
		return
	vida -= dano
	barra_vida.value = vida
	if vida <= 0:
		vencer()

func vencer():
	morto = true
	var tela = get_tree().get_first_node_in_group("telasucesso")
	if tela != null and tela.has_method("aparecer"):
		tela.aparecer()
	queue_free()
