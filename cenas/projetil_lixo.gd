extends CharacterBody2D

var direcao: Vector2 = Vector2.ZERO
@export var velocidade: float = 200.0
@export var dano: int = 15
@export var tempo_vida: float = 6.0

func _ready():
	$AnimatedSprite2D.play("default")  
	await get_tree().create_timer(tempo_vida).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta):
	var colisao = move_and_collide(direcao * velocidade * delta)
	if colisao:
		var body = colisao.get_collider()
		if body.is_in_group("player") and body.has_method("receber_dano"):
			body.receber_dano(dano)
		queue_free()
