extends Control

@export var fase_1_cena: String = "res://cenas/fase1.tscn"

@export var caracteres_por_segundo: float = 15.0

@export var frequencia_som: int = 1.0

var dialogos: Array[String] = [
	"A água no mar está em seu lar. É seu domínio, onde é mais popular! Porém, ela não permanece ali sempre...",
	"Debaixo do sol quente, ela sai do seu estado sólido, e se torna gasosa! Chamamos essa fase de Evaporação.",
	"Nesse estado, a água sai de seu lar e vai aos céus! Ocorre sua Ascensão, logo seguida de Resfriamento e Condensação, onde se torna nuvem!",
	"Por fim, ela volta a sua forma original, líquida, através da Precipitação, que chamamos de chuva!",
	"Uma gotinha de chuva deseja voltar ao ser lar, o oceano! Vamos acompanhar sua jornada e enfrentar seus desafios!"
]

var cena_atual: int = 0

var fundo_de_cada_dialogo: Array[int] = [0, 1, 2, 3, 3]
var tween_texto: Tween
var ultimo_caractere_visivel: int = 0

var tocando_para_frente_cena1: bool = true
var tocando_para_frente_cena2: bool = true

@onready var texto_dialogo: RichTextLabel = $CaixaDialogo/RichTextLabel
@onready var botao_pular: Button = $Skip
@onready var som_digitacao: AudioStreamPlayer = $SomDigitacao 

func _ready():
	botao_pular.pressed.connect(_iniciar_jogo)
	
	_preparar_fundos()

	_ajustar_fundos()
	get_viewport().size_changed.connect(_ajustar_fundos)
	
	MusicaMenu.tocar()

	_atualizar_tela()

func _process(_delta):
	if _esta_digitando():
		var atual = texto_dialogo.visible_characters
		if atual > ultimo_caractere_visivel:
			ultimo_caractere_visivel = atual
			
			if atual % frequencia_som == 0:
				var texto_completo = texto_dialogo.text
				if atual > 0 and atual <= texto_completo.length():
					if texto_completo[atual - 1] != " ":
						som_digitacao.play()

func _input(event):
	if event is InputEventKey or event is InputEventJoypadButton:
		if event.is_pressed() and not event.is_echo():
			_avancar_cena()
			
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		if not botao_pular.get_global_rect().has_point(get_global_mouse_position()):
			_avancar_cena()

func _avancar_cena():
	if _esta_digitando():
		_completar_texto()
		return
	
	cena_atual += 1
	
	if cena_atual >= dialogos.size():
		_iniciar_jogo()
	else:
		_atualizar_tela()

func _atualizar_tela():
	_digitar_texto(dialogos[cena_atual])
	
	for i in range(5):
		var no_fundo = get_node_or_null("cena" + str(i))
		if no_fundo != null:
			no_fundo.visible = false
			
	var indice_fundo: int = fundo_de_cada_dialogo[cena_atual]
	var cena_visivel = get_node_or_null("cena" + str(indice_fundo))
	if cena_visivel != null:
		cena_visivel.visible = true
		
		if cena_visivel is AnimatedSprite2D:
			if indice_fundo == 1:
				tocando_para_frente_cena1 = true
			elif indice_fundo == 2:
				tocando_para_frente_cena2 = true
			
			if not cena_visivel.is_playing():
				cena_visivel.play()

func _preparar_fundos():
	var material_pixel := ShaderMaterial.new()
	material_pixel.shader = preload("res://assets/intro/pixel_suave.gdshader")
	for i in range(5):
		var no_fundo = get_node_or_null("cena" + str(i))
		if no_fundo is AnimatedSprite2D:
			no_fundo.material = material_pixel
			no_fundo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _ajustar_fundos():
	var tamanho_tela: Vector2 = get_viewport_rect().size
	
	for i in range(5):
		var no_fundo = get_node_or_null("cena" + str(i))
		if no_fundo is AnimatedSprite2D and no_fundo.sprite_frames != null:
			var textura: Texture2D = no_fundo.sprite_frames.get_frame_texture(no_fundo.animation, 0)
			if textura == null:
				continue
			
			var tamanho_img: Vector2 = textura.get_size()
			var escala: float = max(tamanho_tela.x / tamanho_img.x, tamanho_tela.y / tamanho_img.y)
			
			no_fundo.scale = Vector2(escala, escala)
			no_fundo.position = tamanho_tela / 2.0

func _digitar_texto(texto: String):
	if tween_texto != null:
		tween_texto.kill()
	
	texto_dialogo.text = texto
	texto_dialogo.visible_ratio = 0.0
	ultimo_caractere_visivel = 0
	
	var total: int = texto_dialogo.get_total_character_count()
	var duracao: float = total / caracteres_por_segundo
	
	tween_texto = create_tween()
	tween_texto.tween_property(texto_dialogo, "visible_ratio", 1.0, duracao)

func _esta_digitando() -> bool:
	return tween_texto != null and tween_texto.is_valid() and tween_texto.is_running()

func _completar_texto():
	if tween_texto != null:
		tween_texto.kill()
	texto_dialogo.visible_ratio = 1.0
	som_digitacao.stop()

func _iniciar_jogo():
	_encerrar_musica_do_menu()
	LoadManager.loadScene(fase_1_cena)

func _encerrar_musica_do_menu():
	MusicaMenu.parar(1.0)

func _on_cena_1_animation_finished() -> void:
	if tocando_para_frente_cena1:
		$cena1.play_backwards()
		tocando_para_frente_cena1 = false
	else:
		$cena1.play()
		tocando_para_frente_cena1 = true

func _on_cena_2_animation_finished() -> void:
	if tocando_para_frente_cena2:
		$cena2.play_backwards()
		tocando_para_frente_cena2 = false
	else:
		$cena2.play()
		tocando_para_frente_cena2 = true
