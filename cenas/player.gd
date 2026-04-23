extends CharacterBody2D

@onready var onda = preload("res://cenas/onda.tscn")
var cena_game_over = preload("res://cenas/tela_game_over.tscn")

@onready var barra_vida = $ProgressBar

@export var SPEED : int = 150
@export var JUMP_FORCE : int = 300
@export var GRAVITY : int = 900

var is_attacking = false
var is_dead = false 
var vida: int = 5

func _ready():
	barra_vida.max_value = vida
	barra_vida.value = vida

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		
	if is_dead:
		velocity.x = 0 
		move_and_slide()
		return

	var direction = Input.get_axis("esquerda", "direita")
	
	if direction:
		velocity.x = direction * SPEED
		if is_on_floor() and is_attacking == false:
			$Flip/AnimatedSprite2D.play("andando")
	else:
		velocity.x = 0
		if is_on_floor() and is_attacking == false:
			$Flip/AnimatedSprite2D.play("parada")
	
	if direction == 1:
		$Flip.scale.x = 1
	elif direction == -1:
		$Flip.scale.x = -1
		
	if Input.is_action_just_pressed("pular") and is_on_floor():
		velocity.y -= JUMP_FORCE
		$Flip/AnimatedSprite2D.play("pulo")
		
	if Input.is_action_just_pressed("atacar") and is_attacking == false:
		is_attacking = true
		$Flip/AnimatedSprite2D.play("ondular")
		
		var o = onda.instantiate()
		o.vel = $Flip.scale.x 
		o.global_position = $Flip/onda_pos.global_position
		get_parent().add_child(o)
		
		await $Flip/AnimatedSprite2D.animation_finished
		is_attacking = false
		
	move_and_slide()


func receber_dano(dano: int):
	if is_dead:
		return 

	vida -= dano
	barra_vida.value = vida
	
	if vida <= 0:
		morrer()

func morrer():
	is_dead = true
	velocity.x = 0
	$Flip/AnimatedSprite2D.play("morte")
	
	await $Flip/AnimatedSprite2D.animation_finished
	
	var tela = cena_game_over.instantiate()
	
	get_tree().current_scene.add_child(tela)
	
	if tela.has_method("aparecer"):
		tela.aparecer()
