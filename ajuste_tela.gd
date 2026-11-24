extends Node

const CENAS_EXPAND := [
	"res://cenas/intro.tscn",
	"res://cenas/fase1.tscn",
	"res://cenas/fase2.tscn",
	"res://cenas/fase4.tscn",
]

var _cena_anterior: Node = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta):
	var cena := get_tree().current_scene
	if cena != _cena_anterior:
		_cena_anterior = cena
		if cena != null and cena.scene_file_path in CENAS_EXPAND:
			usar_modo_expand()
		else:
			usar_modo_fixo()

func usar_modo_expand():
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND

func usar_modo_fixo():
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
