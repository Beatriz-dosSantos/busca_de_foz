extends CharacterBody2D

enum Estado { VOANDO, DESCENDO, VULNERAVEL, SUBINDO }
enum Movimento { PARADO, PATRULHAR, PERSEGUIR }

@export var projetil_cena: PackedScene = preload("res://cenas/projetil_raio.tscn")
@export var item_cena: PackedScene = preload("res://cenas/item.tscn")
@export var vida_max: int = 80
@export var altura_descida: float = 300.0    
@export var tiros_para_descer: int = 3       
@export var tempo_no_chao: float = 3.0       
@export var duracao_movimento: float = 0.6   
@export var margem: float = 40.0             

@export var modo_movimento: Movimento = Movimento.PATRULHAR
@export var velocidade_lateral: float = 120.0 
@export var alcance_patrulha: float = 560.0  

@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D
@onready var ponto_de_tiro: Marker2D = $Marker2D
@onready var barra_vida = $ProgressBar

var vida: int = 80
var estado: int = Estado.VOANDO
var tiros_dados: int = 0
var y_alto: float
var y_baixo: float
var x_inicial: float
var dir_patrulha: int = 1   

func _ready():
	vida = vida_max
	animacao.play("movimento")
	barra_vida.max_value = vida_max
	barra_vida.value = vida

	x_inicial = global_position.x
	y_alto = global_position.y
	y_baixo = y_alto + altura_descida 

func area_visivel() -> Rect2:
	var cam = get_viewport().get_camera_2d()
	if cam == null:
		return Rect2()
	var tamanho = get_viewport_rect().size / cam.zoom
	var centro = cam.get_screen_center_position()
	var canto = centro - tamanho * 0.5 + Vector2(margem, margem)
	return Rect2(canto, tamanho - Vector2(margem, margem) * 2.0)

func _physics_process(delta):
	if estado == Estado.VOANDO:
		mover_lados(delta)

	var area = area_visivel()
	if area != Rect2():
		global_position.x = clamp(global_position.x, area.position.x, area.end.x)
		
		if estado == Estado.VOANDO:
			global_position.y = clamp(global_position.y, area.position.y, area.end.y)

	var player = get_tree().get_first_node_in_group("player")
	if player:
		animacao.flip_h = player.global_position.x < global_position.x

func mover_lados(delta):
	match modo_movimento:
		Movimento.PATRULHAR:
			global_position.x += velocidade_lateral * dir_patrulha * delta
			if global_position.x > x_inicial + alcance_patrulha:
				dir_patrulha = -1
			elif global_position.x < x_inicial - alcance_patrulha:
				dir_patrulha = 1
		Movimento.PERSEGUIR:
			var player = get_tree().get_first_node_in_group("player")
			if player:
				global_position.x = move_toward(
					global_position.x, player.global_position.x, velocidade_lateral * delta)
		Movimento.PARADO:
			pass

func _on_timer_timeout():
	atirar()

func atirar():
	if estado != Estado.VOANDO:
		return
	var player = get_tree().get_first_node_in_group("player")
	if projetil_cena == null or player == null:
		return
	var projetil = projetil_cena.instantiate()
	projetil.top_level = true
	get_tree().current_scene.add_child(projetil)
	projetil.global_position = ponto_de_tiro.global_position
	var centro_do_player = player.global_position + Vector2(0, -20)
	projetil.direcao = (centro_do_player - ponto_de_tiro.global_position).normalized()
	tiros_dados += 1
	if tiros_dados >= tiros_para_descer:
		descer()

func descer():
	estado = Estado.DESCENDO
	var t = create_tween()
	t.tween_property(self, "global_position:y", y_baixo, duracao_movimento).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await t.finished
	if is_queued_for_deletion(): return
	estado = Estado.VULNERAVEL
	await get_tree().create_timer(tempo_no_chao).timeout
	if is_queued_for_deletion(): return
	subir()

func subir():
	estado = Estado.SUBINDO
	var t = create_tween()
	t.tween_property(self, "global_position:y", y_alto, duracao_movimento).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	if is_queued_for_deletion(): return
	tiros_dados = 0
	estado = Estado.VOANDO

func receber_dano(dano: int):
	if estado == Estado.VOANDO or estado == Estado.SUBINDO:
		return
	vida -= dano
	barra_vida.value = vida
	if vida <= 0:
		morrer()

func morrer():
	if item_cena != null:
		var novo_item = item_cena.instantiate()
		novo_item.top_level = true
		novo_item.global_position = global_position
		get_parent().call_deferred("add_child", novo_item)
	queue_free()
