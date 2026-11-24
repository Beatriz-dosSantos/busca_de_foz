extends Node

var ONDA: AudioStream
var MORTE_FOZ: AudioStream
var SUCESSO: AudioStream

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	ONDA = load("res://assets/som/onda_curta.wav")
	MORTE_FOZ = load("res://assets/som/morte_foz_curta.wav")
	SUCESSO = load("res://assets/som/sucesso.mp3")

func tocar(som: AudioStream, volume_db: float = 0.0, bus: StringName = &"SFX") -> void:
	if som == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = som
	p.volume_db = volume_db
	p.bus = bus
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
