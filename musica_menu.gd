extends Node

const MUSICA := preload("res://menu/Rainy Day.wav")
const INICIO := 10.0

var player: AudioStreamPlayer
var _fade: Tween

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = AudioStreamPlayer.new()
	player.stream = MUSICA
	player.bus = &"Musica"
	add_child(player)

func tocar():
	if _fade:
		_fade.kill()
		_fade = null
	player.volume_db = 0.0
	if not player.playing:
		player.play(INICIO)

func parar(duracao: float = 1.0):
	if not player.playing:
		return
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(player, "volume_db", -40.0, duracao)
	_fade.tween_callback(player.stop)
