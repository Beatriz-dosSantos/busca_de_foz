extends CharacterBody2D

var fundo_poluicao = preload("res://assets/barra de vida/termometro poluicao1.png")
var cheio_poluicao = preload("res://assets/barra de vida/termometro poluicao cheio.png")
var fundo_termo = preload("res://assets/barra de vida/termometro calor1.png")
var cheio_termo = preload("res://assets/barra de vida/termometro calor cheio.png")

@onready var onda = preload("res://cenas/onda.tscn")
var cena_game_over = preload("res://cenas/tela_game_over.tscn")
var cena_go_chuva = preload("res://cenas/tela_game_over_chuva.tscn")
var cena_go_neve = preload("res://cenas/tela_game_over_neve.tscn")
var cena_go_sol = preload("res://cenas/tela_game_over_sol.tscn")

@onready var barra_vida: TextureProgressBar = $CanvasLayer/ProgressBar
@onready var texto_vida: Label = $CanvasLayer/TextoVida
@onready var barra_carga: TextureProgressBar = $CanvasLayer/BarraCarga
@onready var icone_z: Label = $CanvasLayer/IconeZ

@export var SPEED : int = 170
@export var JUMP_FORCE : int = 300
@export var GRAVITY : int = 900
@export var vida_max : int = 100 

var is_attacking = false
var is_dead = false
var vida: int = 0 

var carga_item : float = 0.0
@export var velocidade_carga : float = 15.0 
var pode_usar_especial : bool = false
var fase_com_especial : bool = false

var dano_onda: int = 5
var dano_item: int = 10
var item_atual: String = ""      

func _ready():
	vida = 0 
	barra_vida.max_value = vida_max
	barra_vida.value = vida
	atualizar_texto_vida()
	_configurar_tema_da_barra()
	
	var nome_da_cena = get_tree().current_scene.name
	fase_com_especial = (nome_da_cena != "fase1") 
	
	barra_carga.visible = fase_com_especial
	icone_z.visible = false
	barra_carga.value = 0

	var gs = get_node_or_null("/root/GameState")
	if gs:
		dano_onda = gs.dano_onda
		item_atual = gs.item_atual
		dano_item = gs.dano_item()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if is_dead:
		velocity.x = 0
		move_and_slide()
		return
	
	if fase_com_especial and not pode_usar_especial:
		carga_item += velocidade_carga * delta
		barra_carga.value = carga_item
		
		if carga_item >= 100:
			carga_item = 100
			pode_usar_especial = true
			icone_z.visible = true 

	var direction = Input.get_axis("esquerda", "direita")
	if direction:
		velocity.x = direction * SPEED
		if is_on_floor() and not is_attacking:
			$Flip/AnimatedSprite2D.play("andando")
	else:
		velocity.x = 0
		if is_on_floor() and not is_attacking:
			$Flip/AnimatedSprite2D.play("parada")

	if direction != 0:
		$Flip.scale.x = 1 if direction == 1 else -1

	if Input.is_action_just_pressed("pular") and is_on_floor():
		velocity.y -= JUMP_FORCE
		$Flip/AnimatedSprite2D.play("pulo")

	if Input.is_action_just_pressed("atacar") and not is_attacking:
		atacar_onda()

	if Input.is_action_just_pressed("usar_item") and pode_usar_especial and item_atual != "":
		usar_poder_item()

	move_and_slide()

func atacar_onda():
	is_attacking = true
	$Flip/AnimatedSprite2D.play("ondular")
	var o = onda.instantiate()
	o.vel = $Flip.scale.x
	o.dano = dano_onda
	get_parent().add_child(o)
	o.global_position = $Flip/onda_pos.global_position
	await $Flip/AnimatedSprite2D.animation_finished
	is_attacking = false

func usar_poder_item():
	# Reseta a carga
	pode_usar_especial = false
	carga_item = 0.0
	barra_carga.value = 0
	icone_z.visible = false 
	
	var o = onda.instantiate()
	o.vel = $Flip.scale.x
	o.dano = dano_item
	o.scale = Vector2(1.8, 1.8)
	o.modulate = _cor_do_item()
	get_parent().add_child(o)
	o.global_position = $Flip/onda_pos.global_position

func _cor_do_item() -> Color:
	match item_atual:
		"ventilador": return Color(0.8, 1.0, 1.0)   
		"raio":       return Color(1.0, 0.95, 0.4)   
		"floco":      return Color(0.7, 0.9, 1.0)    
		_:            return Color(1, 1, 1)

func receber_dano(dano: int):
	if is_dead: return
	vida += dano
	barra_vida.value = vida
	atualizar_texto_vida()
	if vida >= vida_max:
		morrer()

func atualizar_texto_vida():
	texto_vida.text = str(vida) + "%"

func _cena_game_over_da_fase() -> PackedScene:
	match get_tree().current_scene.name:
		"fase3":
			return cena_go_neve   # neve / boneco de neve
		"fasefloreta", "fase2":
			return cena_go_chuva  # floresta / nuvem
		"fase4":
			return cena_go_sol    # praia / sol
		_:
			return cena_game_over # fase1 / lixão (padrão)

func morrer():
	is_dead = true
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
	else:
		barra_vida.texture_under = fundo_termo
		barra_vida.texture_progress = cheio_termo
