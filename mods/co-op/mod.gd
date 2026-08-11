class_name CoOp
extends Mod

var character_select
var host_name:LineEdit
const coop_version="dead's suprise propal update - 10"

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

#func _on_scene_changed()->void:
	#var current_scene=get_tree().current_scene
	##if current_scene is Main:
		##main_aditions(current_scene)
	#if current_scene is MainMenu:
		#main_menu_additions(current_scene)

func _process(_delta: float) -> void:
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
		
	for icon_path in intent_icons:
		ResourceLoader.load_threaded_request(icon_path)
	
	ProjectSettings.set_setting("application/run/flush_stdout_on_print",true)
	
	if scene_tree.current_scene is MainMenu:
		await scene_tree.process_frame
		scene_tree.reload_current_scene.call_deferred()
	
#func main_menu_additions(main_menu:MainMenu)->void:
	#var hud=main_menu.get_node("HUD")
	#var play_menu=hud.get_node("PlayMenu")
	#play_menu.get_node("ContinueButton").queue_free()
	
#func save_character_selector_info()->void:
	#Game.difficulty=character_select.difficulty
	#Game.player_info.character=character_select.character

func get_spell_ids() -> Array[String]:
	return [
		"co-op:party_telephone",
		"co-op:postage_stamp",
		"co-op:blue_box",
		"co-op:remote_object",
		"co-op:tv_snow"
	]

func modify_spell_pool(pool: Dictionary, category: String = "") -> void:
	pool.erase("mba")
	pool.erase("panic_button")
	pool.erase("red_tape")
	pool["co-op:joker"]=0.0
	
	match category:
		Globals.SPELL_CATEGORY.OFFENSIVE:
			pool["co-op:party_telephone"]=3.0
			pool["co-op:postage_stamp"]=3.0
		Globals.SPELL_CATEGORY.SUPPORT:
			pool["co-op:blue_box"]=1.0
			pool["co-op:remote_object"]=3.0
		Globals.SPELL_CATEGORY.DEFENSIVE:
			pool["co-op:tv_snow"]=3.0
