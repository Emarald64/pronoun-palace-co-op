class_name CoOp
extends Mod

var character_select
var host_name:LineEdit
const AUTHOR="Xanderath"
const COOP_VERSION="1.1.6 - 9/17"
var version_number:String

const intent_icon_path:="res://mods/co-op/arte/intents/"
const intent_icons:Dictionary[String,String]={
	"spell_swap.png":"spell_swap",
	"pronounpalace-sendtilesx-px.png":"phone_a_friend_send",
	"pronounpalace-receivetiles-px.png":"phone_a_friend_recive",
	"pronounpalace-sendtilescursed-px.png":"phone_a_friend_send_cursed",
	"pronounpalace-receivetilescursed-px.png":"phone_a_friend_recive_cursed",
	"echo.png":"echo",
	"echo_cursed.png":"echo_cursed",
	"candy_round_healing.png":"candy_round_healing"
}

const SPELLS:Dictionary[StringName,String]={
	PARTY_TELEPHONE="party_telephone",
	POSTAGE_STAMP="postage_stamp",
	BLUE_BOX="blue_box",
	REMOTE_OBJECT="remote_object",
	TV_SNOW="tv_snow",
	GIFT_COOP="gift_coop",
	MIRACLE_CACHE_COOP="miracle_cache_coop",
	MINUTE_OF_HATE="minute_of_hate",
	SSN_PRINTER="ssn_printer",
	PRINTED_SSN="printed_ssn"
}

const SPELL_WEIGHTS:Dictionary[String,float]={
	SPELLS.PARTY_TELEPHONE:1.5,
	SPELLS.POSTAGE_STAMP:2.5,
	SPELLS.BLUE_BOX:1.5,
	SPELLS.REMOTE_OBJECT:2.0,
	SPELLS.TV_SNOW:2.0,
	SPELLS.SSN_PRINTER:2.0
}

const SPELL_CATAGORIES={
	#Globals.SPELL_CATEGORY.OFFENSIVE:[
		#"co-op:party_telephone",
		#"co-op:postage_stamp",
	#],
	#Globals.SPELL_CATEGORY.SUPPORT:[
		#"co-op:blue_box",
		#"co-op:remote_object"
	#],
	#Globals.SPELL_CATEGORY.DEFENSIVE:[
		#"co-op:tv_snow"
	#]
}

const GIFT_SPELLS:Array[String]=[
	SPELLS.GIFT_COOP,
	SPELLS.MIRACLE_CACHE_COOP
]

const SPELL_UPGRADES={
	SPELLS.GIFT_COOP:SPELLS.MIRACLE_CACHE_COOP
}

var unloaded_intents:Array[String]=intent_icons.keys()

#static func change_script_and_copy_properties(object:Object,script:Script):
	#var properties:Dictionary[String,Variant]={}
	#for property in object.get_property_list():
		#if property.name!="script":
			#properties[property.name]=object.get(property.name)
	#object.set_script(script)
	#for property in properties:
		#object.set(property,properties[property])

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
	ProjectSettings.set_setting("application/run/flush_stdout_on_print",true)
	
	version_number=mod_data.json.data.version
	if mod_data.json.data.author!=AUTHOR:
		push_error("some shenanagens are afoot >:(\n Please don't remove my name from the mod!")
		return
	
	print("coop mod version:",COOP_VERSION)
	#var scene_tree=get_tree()
		
	for file_name in intent_icons:
		ResourceLoader.load_threaded_request(intent_icon_path+file_name)

	var cmdline_args:=OS.get_cmdline_args()
	var connect_arg_pos:=cmdline_args.find("+connect_lobby")
	if connect_arg_pos>=0 and cmdline_args.size()>connect_arg_pos+1:
		#connect to steam lobby
		var steam_lobby_id=int(cmdline_args[connect_arg_pos+1])
		await get_tree().process_frame
		Game.steam_lobby_id=steam_lobby_id
		Steam.joinLobby(steam_lobby_id)
		var lobby_joined=await Steam.lobby_joined
		var lobby_joined_response=lobby_joined[3]
		if lobby_joined_response==Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
			print("joined lobby ",steam_lobby_id," successfuly")
			await Game.main_menu.screen_wipe.anim_player.animation_finished
			await Game.main_menu.menu_controller.menu_appear_finish
			Game.main_menu.menu_controller.set_menu(Game.main_menu.get_node("HUD/Steam Join Menu"))
			#else:
				#push_error("error connecting peer to lobby: ",error_string(peer_error))
		else:
			push_error("error joining lobby, code: ",lobby_joined_response)
	
	Steam.join_requested.connect(_on_join_lobby_requested)
	
	

func _on_join_lobby_requested(lobby_id:int, _friend_id:int):
	Steam.joinLobby(lobby_id)
	if Game.is_in_run():
		print("returning to main menu to join lobby")
		Game.return_to_menu()
		await get_tree().scene_changed
		await get_tree().process_frame
	print("joining lobby ",lobby_id)
	Game.steam_lobby_id=lobby_id
	var lobby_joined=await Steam.lobby_joined
	var lobby_joined_response=lobby_joined[3]
	if lobby_joined_response==Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		print("joined lobby ",lobby_id," successfuly")
		#await Game.main_menu.screen_wipe.anim_player.animation_finished
		Game.main_menu.menu_controller.set_menu(Game.main_menu.get_node("HUD/Steam Join Menu"))
		#else:
			#push_error("error connecting peer to lobby: ",error_string(peer_error))
	else:
		push_error("error joining lobby, code: ",lobby_joined_response) 


func get_spell_ids() -> Array[String]:
	return namespace_ids(SPELLS.values())

func get_spell_pool(category: String = "") -> Dictionary[String, float]:
	if category.is_empty():
		return namespace_dictionary_ids(SPELL_WEIGHTS)
	if category not in SPELL_CATAGORIES:
		return {}
	return namespace_dictionary_ids(SpellData.get_filtered_spell_pool(SPELL_WEIGHTS,SPELL_CATAGORIES[category]))

const REMOVED_SPELLS:PackedStringArray=[
	Globals.SPELLS.MBA,
	Globals.SPELLS.PANIC_BUTTON,
	Globals.SPELLS.RED_TAPE
]

func modify_spell_pool(pool: Dictionary, category: String = "") -> void:
	for id in REMOVED_SPELLS:
		pool.erase(id)
	
	pool.merge(get_spell_pool(category))
	

func get_run_save_data() -> Dictionary:
	return {
		others_submitted_words=Game.word_builder.others_submitted_words,
		player_total_damage=Game.word_builder.player_total_damage,
		candy_round=Game.main.candy_round,
		original_id=Game.main.original_id,
		all_player_names=Game.all_player_names
		}
	
func load_run_save_data(data: Dictionary) -> void:
	Game.word_builder.others_submitted_words=data.others_submitted_words
	Game.word_builder.player_total_damage=data.player_total_damage
	Game.main.candy_round=data.candy_round
	Game.main.original_id=data.get("original_id",multiplayer.get_unique_id())
	if data.candy_round:
		Game.main.peer_died.rpc()
	Game.set_original_id.rpc(Game.main.original_id)
	Game.all_player_names.merge(data.all_player_names)

const BANNED_CURSES_SPELL_DATA=[
	SPELLS.SSN_PRINTER
]

func get_spell_data(spell_id: String) -> SpellData:
	if spell_id in BANNED_CURSES_SPELL_DATA:
		return SpellDataBannedCurses.new()
	else:
		return super(spell_id)
