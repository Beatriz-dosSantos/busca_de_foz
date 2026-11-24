extends Area2D

@export var velocidade: float = 230.0
@export var dano: int = 10
@export var tempo_vida: float = 6.0

var direcao: Vector2 = Vector2.ZERO:
	set(valor):
		direcao = valor
		if valor != Vector2.ZERO:
			rotation = valor.angle() + PI

var sumindo := false

@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	body_entered.connect(_on_body_entered)
	animacao.animation_finished.connect(_on_animacao_terminou)
	animacao.play("surgir")
	await get_tree().create_timer(tempo_vida).timeout
	if is_instance_valid(self):
		sumir()

func _process(delta):
	if not sumindo:
		position += direcao * velocidade * delta

func _on_body_entered(body: Node2D):
	if sumindo:
		return
	if body.is_in_group("player"):
		if body.has_method("receber_dano"):
			body.receber_dano(dano)
		sumir()
	elif body is TileMapLayer or body is StaticBody2D:
		sumir()

func sumir():
	if sumindo:
		return
	sumindo = true
	set_deferred("monitoring", false)
	animacao.play("sumir")

func _on_animacao_terminou():
	match animacao.animation:
		"surgir":
			animacao.play("viajando")
		"sumir":
			queue_free()
