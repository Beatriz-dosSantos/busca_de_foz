extends Control 

@onready var progressBar: ProgressBar = $ProgressBar

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
func updateProgressBar(newVal: float):
	progressBar.set_value_no_signal(newVal * 100)
