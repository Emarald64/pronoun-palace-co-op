extends "res://mods/co-op/source/ui/join_menu.gd"

func _on_start_appearing()->void:
	super()
	%LobbyInfo.text="Lobby id: "+str(Game.steam_lobby_id)

func connect_to_server() -> void:
	var peer:=SteamMultiplayerPeer.new()
	var error=peer.connect_to_lobby(Game.steam_lobby_id)
	if error:
		push_error("failed to connect to server ",error_string(error))
	else:
		multiplayer.multiplayer_peer=peer
		%Status.text="Connecting..."
