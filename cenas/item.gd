extends Area2D

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		print("SUCESSO: Item coletado!")
		
		var tela_sucesso = get_tree().get_first_node_in_group("telasucesso")
		
		if tela_sucesso != null:
			tela_sucesso.aparecer()
		else:
			print("ERRO CRÍTICO: A tela de sucesso não está na fase ou faltou a tag do grupo!")
			
		queue_free()
