extends HSlider

@export var audio_bus_name: String = "SFX"

@export var som_preview: AudioStreamPlayer 

var audio_bus_id: int

func _ready() -> void:
	audio_bus_id = AudioServer.get_bus_index(audio_bus_name)
	
	var volume_db = AudioServer.get_bus_volume_db(audio_bus_id)
	value = db_to_linear(volume_db)
	
	value_changed.connect(_on_value_changed)

func _on_value_changed(new_value: float) -> void:
	var db = linear_to_db(new_value)
	AudioServer.set_bus_volume_db(audio_bus_id, db)
	
	if new_value == 0:
		AudioServer.set_bus_mute(audio_bus_id, true)
	else:
		AudioServer.set_bus_mute(audio_bus_id, false)
		
	if som_preview and not som_preview.playing:
		som_preview.play()
