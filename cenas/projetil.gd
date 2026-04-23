extends Area2D

var direcao: Vector2 = Vector2.ZERO
var velocidade: float = 200.0

func _process(delta):
	position += direcao * velocidade * delta

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		if body.has_method("receber_dano"):
			body.receber_dano(1) 
		
		queue_free() 
	
	# Destrói o tiro se bater no chão ou paredes
	elif body is TileMapLayer or body is StaticBody2D:
		queue_free()
