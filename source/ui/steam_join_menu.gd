extends "res://mods/co-op/source/ui/join_menu.gd"

var joining_game:=false

func _on_start_appearing()->void:
	super()
	joining_game=false
	var lobby_id_array=PackedByteArray()
	lobby_id_array.resize(8)
	lobby_id_array.encode_u64(0,Game.steam_lobby_id)
	%LobbyInfo.text="Lobby id: "+Marshalls.raw_to_base64(lobby_id_array)

func connect_to_server() -> void:
	var peer:=SteamMultiplayerPeer.new()
	var error=peer.connect_to_lobby(Game.steam_lobby_id)
	if error:
		push_error("failed to connect to server ",error_string(error))
	else:
		multiplayer.multiplayer_peer=peer
		%Status.text="Connecting..."

func disappear(instant: bool = false) -> void:
	if not joining_game:
		Steam.leaveLobby(Game.steam_lobby_id)
	await super()

func connection_ok():
	joining_game=true
	super()
