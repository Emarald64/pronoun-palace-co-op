extends MenuPanel

var lobby_entries:Array[Control]=[]
var lobby_entry_scene:PackedScene=load("res://mods/co-op/source/ui/steam_lobby_entry.tscn")
@export var steam_join_menu:MenuPanel

func _ready():
	Steam.lobby_match_list.connect(_on_lobby_match_list)

func refresh_lobbies():
	Steam.requestLobbyList()

func _on_lobby_match_list(lobby_ids:Array[int]):
	print(lobby_ids)
	var new_lobby_entries=[]
	for lobby_entry in lobby_entries:
		lobby_entry.hide()
	
	for lobby_id in lobby_ids:
		var lobby_entry:Control
		if lobby_entries.is_empty():
			lobby_entry=lobby_entry_scene.instantiate()
			%Lobbies.add_child(lobby_entry)
			lobby_entry.pressed.connect(join_lobby)
		else:
			lobby_entry=lobby_entries.pop_front()
			lobby_entry.show()
		
		lobby_entry.set_lobby_id(lobby_id)
	
	lobby_entries=new_lobby_entries

func join_lobby(lobby_id:int):
	Game.lobby_id=lobby_id
	Steam.joinLobby(lobby_id)
	var lobby_joined=await Steam.lobby_joined
	var lobby_joined_response=lobby_joined[3]
	if lobby_joined_response==Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		print("joined lobby ",lobby_id," successfuly")
		menu_controller.set_menu(steam_join_menu)
	else:
		push_error("error joining lobby, code: ",lobby_joined_response)
