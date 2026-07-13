extends MenuPanel

var opens_menu:MenuPanel
const ICON_SCENE: PackedScene = preload("res://source/ui/menu/character_select/character_selector_icon.tscn")
var icons:Array[CharacterSelectorIcon]=[]
#var character:=Globals.CHARACTERS.LEXICOGRAPHER

func _ready()->void:
	start_appearing.connect(_on_start_appearing)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.connected_to_server.connect(connection_ok)


#func appear(instant: bool = false, reset_position: bool = true)->void:
	#super(instant,reset_position)

func _on_start_appearing()->void:
	if icons.is_empty():
		for id in Globals.CHARACTER_ORDER:
			var icon: CharacterSelectorIcon = ICON_SCENE.instantiate()
			icon.set_character(id, true)
			icons.append(icon)

		var selector_icons: Array[SelectorIcon] = []
		selector_icons.assign(icons)
		%IconSelector.set_icons(selector_icons)


func connect_to_server() -> void:
	var address:String=%IP.text
	if address.is_empty():
		address="127.0.0.1"
	var port_string:String=%Port.text
	var port:=7000
	if port_string.is_valid_int():
		port=port_string.to_int()
	var peer:=ENetMultiplayerPeer.new()
	var error=peer.create_client(address,port)
	if error:
		push_error("failed to connect to server ",error_string(error))
	else:
		multiplayer.multiplayer_peer=peer
		%Status.text="Connecting..."

func connection_failed()->void:
	print("connection failed")
	multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	%Status.text="Connection Failed"

func connection_ok()->void:
	%Status.text=""
	menu_controller.set_menu(opens_menu)


func _on_icon_selector_selected(icon: SelectorIcon) -> void:
	Game.player_info.character=icon.character


func _on_name_changed(new_text: String) -> void:
	Game.player_info.name=new_text
