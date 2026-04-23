extends CharacterBody2D

@export var projetil_cena: PackedScene 
@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D
@onready var ponto_de_tiro: Marker2D = $Marker2D
@onready var barra_vida = $ProgressBar
@onready var item_cena = preload("res://cenas/item.tscn")

var vida: int = 3 

func _ready():
	animacao.play("movimento")
	barra_vida.max_value = vida
	barra_vida.value = vida
	
func _on_timer_timeout():
	atirar()

func atirar():
	var player = get_tree().get_first_node_in_group("player")
	
	if projetil_cena == null or player == null:
		return
		
	var projetil = projetil_cena.instantiate()
	projetil.global_position = ponto_de_tiro.global_position
	
	var centro_do_player = player.global_position + Vector2(0, -20)
	var direcao_para_player = (centro_do_player - ponto_de_tiro.global_position).normalized()
	
	projetil.direcao = direcao_para_player
	get_tree().current_scene.add_child(projetil)

func receber_dano(dano: int):
	vida -= dano
	barra_vida.value = vida
	
	if vida <= 0:
		print("Inimigo Derrotado!")
		
		if item_cena != null:
			var novo_item = item_cena.instantiate()
			novo_item.global_position = self.global_position 
			get_parent().call_deferred("add_child", novo_item)
		
		queue_free()
