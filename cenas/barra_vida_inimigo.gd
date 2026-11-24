extends TextureProgressBar

const MINIMO_VISIVEL := 0.04

func mostrar(vida: int, vida_max: int) -> void:
	max_value = vida_max
	if vida <= 0:
		value = 0.0
	else:
		value = max(float(vida), vida_max * MINIMO_VISIVEL)
