extends Area2D

@export var velocidade: float = 200.0
@export var dano: int = 10
@export var tempo_vida: float = 6.0

var direcao: Vector2 = Vector2.ZERO:
	set(valor):
		direcao = valor
		if valor != Vector2.ZERO:
			rotation = valor.angle()

var estourando := false

@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	body_entered.connect(_on_body_entered)
	animacao.animation_finished.connect(_on_animacao_terminou)
	animacao.play("esquentar")
	await get_tree().create_timer(tempo_vida).timeout
	if is_instance_valid(self):
		estourar()

func _process(delta):
	if not estourando:
		position += direcao * velocidade * delta

func _on_body_entered(body: Node2D):
	if estourando:
		return
	if body.is_in_group("player"):
		if body.has_method("receber_dano"):
			body.receber_dano(dano)
		estourar()
	elif body is TileMapLayer or body is StaticBody2D:
		estourar()

func estourar():
	if estourando:
		return
	estourando = true
	set_deferred("monitoring", false)
	rotation = 0.0
	animacao.play("estourar")

func _on_animacao_terminou():
	match animacao.animation:
		"esquentar":
			animacao.play("voando")
		"estourar":
			queue_free()
