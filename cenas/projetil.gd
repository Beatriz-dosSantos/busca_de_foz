extends Area2D

var direcao: Vector2 = Vector2.ZERO
@export var velocidade: float = 200.0
@export var dano: int = 10       
@export var tempo_vida: float = 6.0  

func _ready():
	await get_tree().create_timer(tempo_vida).timeout
	if is_instance_valid(self):
		queue_free()

func _process(delta):
	position += direcao * velocidade * delta

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		if body.has_method("receber_dano"):
			body.receber_dano(dano)
		queue_free()
	elif body is TileMapLayer or body is StaticBody2D:
		queue_free()
