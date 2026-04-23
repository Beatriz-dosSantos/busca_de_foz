extends Area2D

var SPEED = 300
var vel : float = 1.0

func _ready():
	$AnimatedSprite2D.play("aonda")
	$AnimatedSprite2D.animation_finished.connect(deletar_onda)

func _process(delta):
	position.x += vel * SPEED * delta

func deletar_onda():
	queue_free()

func _on_body_entered(body: Node2D):
	if body.is_in_group("inimigo"):
		if body.has_method("receber_dano"):
			body.receber_dano(1) # Dá 1 de dano
			
		queue_free() 
