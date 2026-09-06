extends MenuPanel

func apply_filters():
	Steam.addRequestLobbyListDistanceFilter(%Distance.get_selected_id())
	Steam.addRequestLobbyListStringFilter("seed",SaveManager.get_save().metadata.seed if %CheckSeed.button_pressed else "",Steam.LobbyComparison.LOBBY_COMPARISON_EQUAL)
