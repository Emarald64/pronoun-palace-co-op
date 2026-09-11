extends MenuPanel

var run_seed:String
signal refresh

func _ready():
	var metadata=SaveManager.get_save().get_saved_run(false).metadata
	if SaveFile.get_run_playable(metadata,false):
		run_seed=metadata.seed
	else:
		%RejoinGame.hide()
	start_appearing.connect(_on_start_appearing)

func _on_start_appearing():
	apply_filters()

func apply_filters():
	Steam.addRequestLobbyListDistanceFilter(%Distance.get_selected_id())
	#var metadata=SaveManager.get_save().get_saved_run(false)
	if not Input.is_key_pressed(KEY_SHIFT):
		Steam.addRequestLobbyListStringFilter("seed",run_seed if %CheckSeed.button_pressed else "",Steam.LobbyComparison.LOBBY_COMPARISON_EQUAL)
	refresh.emit()
