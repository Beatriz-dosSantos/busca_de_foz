extends Node

var fase_atual: int = 1
var dano_onda: int = 10        
var item_atual: String = ""  

func iniciar_jogo() -> void:
	fase_atual = 1
	dano_onda = 10
	item_atual = ""

func avancar_fase(item_recompensa: String) -> void:
	fase_atual += 1
	dano_onda *= 2
	if item_recompensa != "":
		item_atual = item_recompensa

func dano_item() -> int:
	return dano_onda * 2
