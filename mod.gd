class_name CoOp
extends Mod

var character_select
var host_name:LineEdit
const coop_version="Strawman <3 - 12"

const intent_icon_path:="res://mods/co-op/arte/intents/"
const intent_icons:Dictionary[String,String]={
	"spell_swap.png":"spell_swap",
	"pronounpalace-sendtilesx-px.png":"phone_a_friend_send",
	"pronounpalace-receivetiles-px.png":"phone_a_friend_recive",
	"pronounpalace-sendtilescursed-px.png":"phone_a_friend_send_cursed",
	"pronounpalace-receivetilescursed-px.png":"phone_a_friend_recive_cursed",
	"echo.png":"echo",
	"echo_cursed.png":"echo_cursed"
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

func _process(_delta: float) -> void:
	for file_name in unloaded_intents:
		var path=intent_icon_path+file_name
		var status=ResourceLoader.load_threaded_get_status(path)
		if status==ResourceLoader.THREAD_LOAD_LOADED:
			CustomIntent.custom_intent_icons[intent_icons[file_name]]=ResourceLoader.load_threaded_get(path)
			unloaded_intents.erase(file_name)
		elif status!=ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			push_error("Error threaded loading ",path," code: ",status)
			unloaded_intents.erase(file_name)

func _ready()->void:
	print("coop mod version:",coop_version)
	#var scene_tree=get_tree()
		
	for file_name in intent_icons:
		ResourceLoader.load_threaded_request(intent_icon_path+file_name)
	
	ProjectSettings.set_setting("application/run/flush_stdout_on_print",true)
	
func get_spell_ids() -> Array[String]:
	return [
		"co-op:party_telephone",
		"co-op:postage_stamp",
		"co-op:blue_box",
		"co-op:remote_object",
		"co-op:tv_snow"
	]

const spell_weights:Dictionary[String,float]={
	"co-op:party_telephone":3.0,
	"co-op:postage_stamp":3.0,
	"co-op:blue_box":1.0,
	"co-op:remote_object":3.0,
	"co-op:tv_snow":3.0
}

const spell_catagories={
	Globals.SPELL_CATEGORY.OFFENSIVE:[
		"co-op:party_telephone",
		"co-op:postage_stamp",
	],
	Globals.SPELL_CATEGORY.SUPPORT:[
		"co-op:blue_box",
		"co-op:remote_object"
	],
	Globals.SPELL_CATEGORY.DEFENSIVE:[
		"co-op:tv_snow"
	]
}

func get_spell_pool(category: String = "") -> Dictionary[String, float]:
	if category.is_empty():
		return spell_weights
	if category not in spell_catagories:
		return {}
	return SpellData.get_filtered_spell_pool(spell_weights,spell_catagories[category])

func modify_spell_pool(pool: Dictionary, category: String = "") -> void:
	pool.erase("mba")
	pool.erase("panic_button")
	pool.erase("red_tape")
	
	pool.merge(get_spell_pool(category))
	

func get_run_save_data() -> Dictionary:
	return {
		others_submitted_words=Game.word_builder.others_submitted_words,
		player_total_damage=Game.word_builder.player_total_damage
		}
	
func load_run_save_data(data: Dictionary) -> void:
	Game.word_builder.others_submitted_words=data.others_submitted_words
	Game.word_builder.player_total_damage=data.player_total_damage
