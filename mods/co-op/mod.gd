class_name CoOp
extends Mod

var character_select
var host_name:LineEdit
const coop_version="jubilist 8"

const intent_icons:Dictionary[String,String]={
	"res://mods/co-op/intents/spell_swap.png":"spell_swap",
	"res://mods/co-op/intents/pronounpalace-sendtilesx-px.png":"phone_a_friend_send",
	"res://mods/co-op/intents/pronounpalace-receivetiles-px.png":"phone_a_friend_recive",
	"res://mods/co-op/intents/pronounpalace-sendtilescursed-px.png":"phone_a_friend_send_cursed",
	"res://mods/co-op/intents/pronounpalace-receivetilescursed-px.png":"phone_a_friend_recive_cursed",
	"res://mods/co-op/intents/echo.png":"echo",
	"res://mods/co-op/intents/echo_cursed.png":"echo_cursed"
}

var unloaded_intents:Array[String]=intent_icons.keys()

static func change_script_and_copy_properties(object:Object,script:Script):
	var properties:Dictionary[String,Variant]={}
	for property in object.get_property_list():
		if property.name!="script":
			properties[property.name]=object.get(property.name)
	object.set_script(script)
	for property in properties:
		object.set(property,properties[property])

func _on_scene_changed()->void:
	var current_scene=get_tree().current_scene
	#if current_scene is Main:
		#main_aditions(current_scene)
	if current_scene is MainMenu:
		main_menu_additions(current_scene)

func _process(delta: float) -> void:
	for path in unloaded_intents:
		var status=ResourceLoader.load_threaded_get_status(path)
		if status==ResourceLoader.THREAD_LOAD_LOADED:
			CustomIntent.custom_intent_icons[intent_icons[path]]=ResourceLoader.load_threaded_get(path)
			unloaded_intents.erase(path)
		elif status!=ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			push_error("Error threaded loading ",path," code: ",status)
			unloaded_intents.erase(path)

func _ready()->void:
	print("coop mod version:",coop_version)
	var scene_tree=get_tree()
	scene_tree.scene_changed.connect(_on_scene_changed)
	var current_scene=scene_tree.current_scene
	if current_scene is MainMenu:
		main_menu_additions(current_scene)
		
	for icon_path in intent_icons:
		ResourceLoader.load_threaded_request(icon_path)
	
	SpellLoader.spell_pool["mba"]=0.0
	SpellLoader.spell_pool["panic_button"]=0.0
	SpellLoader.spell_pool["red_tape"]=0.0
	SpellLoader.add_spell("party_telephone",3.0,Globals.SPELL_CATEGORY.OFFENSIVE)
	SpellLoader.add_spell("blue_box",3.0,Globals.SPELL_CATEGORY.SUPPORT)
	SpellLoader.add_spell("remote_object",3.0,Globals.SPELL_CATEGORY.SUPPORT)
	SpellLoader.add_spell("postage_stamp",3.0,Globals.SPELL_CATEGORY.OFFENSIVE)
	#SpellLoader.add_spell("joker",0)
	
	ProjectSettings.set_setting("application/run/flush_stdout_on_print",true)
	
	get_tree().process_frame.connect(
		func ():
			Globals.set_script(load("res://mods/co-op/overrides/custom_globals.gd"))
	)
	
	# replace game script
	get_tree().create_timer(.5).timeout.connect(
		func ():
			change_script_and_copy_properties(Game,load("res://mods/co-op/overrides/game.gd"))
	)
	
func main_menu_additions(main_menu:MainMenu)->void:
	var hud=main_menu.get_node("HUD")
	var play_menu=hud.get_node("PlayMenu")
	play_menu.get_node("ContinueButton").queue_free()
	var join_button=preload("res://mods/co-op/join_button.tscn").instantiate()
	play_menu.add_child(join_button)
	play_menu.move_child(join_button,1)
	
	var join_menu=preload("res://mods/co-op/join_menu.tscn").instantiate()
	hud.add_child(join_menu)
	join_menu.position.y=1000
	join_button.opens_menu=join_menu
	
	var lobby=preload("res://mods/co-op/lobby.tscn").instantiate()
	hud.add_child(lobby)
	lobby.position.y=1000
	join_menu.opens_menu=lobby
	
	var create_server_menu=preload("res://mods/co-op/create_server_menu.tscn").instantiate()
	hud.add_child(create_server_menu)
	create_server_menu.position.y=1000
	create_server_menu.lobby=lobby
	
	character_select=hud.get_node("CharacterSelect")
	lobby.character_select=character_select
	
	var start_button=character_select.get_node("StartButton")
	start_button.pressed.disconnect(character_select._on_start_button_pressed)
	start_button.pressed.connect(save_character_selector_info)
	start_button.opens_menu=create_server_menu
	
func save_character_selector_info()->void:
	Game.difficulty=character_select.difficulty
	Game.player_info.character=character_select.character
