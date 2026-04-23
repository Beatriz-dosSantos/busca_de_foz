extends Node

var loadScreenPath: String = "res://cenas/loading.tscn"
var loadScreen = load(loadScreenPath)
var loadedResource : PackedScene
var scenePath: String
var localProgress: Array = []
const useSubThreads: bool = true

var can_change_scene: bool = false 
var is_loading: bool = false
var currentLoadingScreen: Node 

signal progressChanged(progress)

func loadScene(scene_path: String):
	if is_loading:
		return
	is_loading = true
	
	scenePath = scene_path
	
	currentLoadingScreen = loadScreen.instantiate()
	get_tree().get_root().add_child(currentLoadingScreen)
	
	progressChanged.connect(currentLoadingScreen.updateProgressBar)
	
	can_change_scene = false
	get_tree().create_timer(1.5).timeout.connect(func(): can_change_scene = true)
	
	startLoad()
	
func startLoad():
	var state = ResourceLoader.load_threaded_request(scenePath, "", useSubThreads)
	if state == OK:
		set_process(true) 
	
func _process(_delta):
	var load_status = ResourceLoader.load_threaded_get_status(scenePath, localProgress)
	
	match load_status:
		0, 2: 
			set_process(false)
			is_loading = false
			return
		1: 
			emit_signal("progressChanged", localProgress[0])
		3: 
			emit_signal("progressChanged", 1.0)
			
			if not can_change_scene:
				return
				
			set_process(false)
			loadedResource = ResourceLoader.load_threaded_get(scenePath)
			
			if currentLoadingScreen != null:
				currentLoadingScreen.queue_free()
				
			is_loading = false 
			
			get_tree().change_scene_to_packed(loadedResource)
