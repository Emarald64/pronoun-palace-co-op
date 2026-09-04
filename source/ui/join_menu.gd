extends MenuPanel

@export var lobby:MenuPanel
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
			icon.get_node("%CharacterIcon").show_locked_character=true
			icon.set_character(id, true)
			icons.append(icon)

		var selector_icons: Array[SelectorIcon] = []
		selector_icons.assign(icons)
		%IconSelector.set_icons(selector_icons)


func connect_to_server() -> void:
	var address:String=%IP.text
	if address.is_empty():
		address="127.0.0.1"
	var port:=int(%Port.value)
	var peer:=ENetMultiplayerPeer.new()
	var error=peer.create_client(address,port)
	if error:
		push_error("failed to connect to server ",error_string(error))
	else:
		multiplayer.multiplayer_peer=peer
		%Status.text="Connecting..."

func connection_failed()->void:
	if active:
		print("connection failed")
		multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
		%Status.text="Connection Failed"

func connection_ok()->void:
	if active:
		AudioManager.play_sound(Sounds.UI.FORWARD_PAPER)
		%Status.text=""
		menu_controller.set_menu(lobby)


func _on_icon_selector_selected(icon: SelectorIcon) -> void:
	%CharacterTitle.key="character/%s/select_title" % icon.character
	if icon.character==Globals.CHARACTERS.ADDICT:
		$AddictDeselectTimer.start()
	else:
		$AddictDeselectTimer.stop()
		Game.player_info.character=icon.character


func _on_name_changed(new_text: String) -> void:
	Game.player_info.name=new_text


func select_lexicographer() -> void:
	%IconSelector.select(Globals.CHARACTER_ORDER.find(Game.player_info.character))
