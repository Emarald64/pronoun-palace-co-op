extends MenuPanel

var lobby_entries:Array[Control]=[]
var lobby_entry_scene:PackedScene=load("res://mods/co-op/source/ui/steam_lobby_entry.tscn")
@export var steam_join_menu:MenuPanel

#signal apply_filters

func _ready():
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	start_appearing.connect(_on_start_appear)

func _on_start_appear() -> void:
	refresh_lobbies()

func refresh_lobbies():
	for lobby_entry in lobby_entries:
		lobby_entry.hide()
	%SectionedPanel.update_panels()
	#apply_filters.emit()
	#Steam.addRequestLobbyListStringFilter("seed","",Steam.LobbyComparison.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()
	print("requested lobbies refresh")

func _on_lobby_match_list(lobby_ids:Array):
	#print_debug(lobby_ids)
	var new_lobby_entries:Array[Control]=[]
	
	for lobby_id in lobby_ids:
		var lobby_entry:Control
		if lobby_entries.is_empty():
			lobby_entry=lobby_entry_scene.instantiate()
			%SectionedPanel.contents_box.add_child(lobby_entry)
			lobby_entry.pressed.connect(join_lobby)
		else:
			lobby_entry=lobby_entries.pop_front()
			lobby_entry.show()
		lobby_entry.set_lobby_id(lobby_id)
		new_lobby_entries.append(lobby_entry)
	
	lobby_entries=new_lobby_entries
	%SectionedPanel.update_panels()

func join_lobby(lobby_id:int):
	AudioManager.play_sound(Sounds.UI.MENU_BUTTON)
	Steam.joinLobby(lobby_id)
	Game.steam_lobby_id=lobby_id
	var lobby_joined=await Steam.lobby_joined
	var lobby_joined_response=lobby_joined[3]
	if lobby_joined_response==Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		print("joined lobby ",lobby_id," successfuly")
		AudioManager.play_sound(Sounds.UI.FORWARD_PAPER)
		menu_controller.set_menu(steam_join_menu)
	else:
		push_error("error joining lobby, code: ",lobby_joined_response)
