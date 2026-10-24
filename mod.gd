class_name CoOp
extends Mod

const ID="co-op"
#const id=ID
const NAMESPACE=ID+":"
const AUTHOR="Xanderath"
const COOP_VERSION="1.3.2 - 10/16"

const PEER_SELECTION_TYPE=3

signal updated_extra_time(value:bool)

var version_number:String
#var extra_hate_time:=false

const intent_icon_path:="res://mods/co-op/arte/intents/"

const INTENTS:Dictionary[String,String]={
	SPELL_SWAP="spell_swap",
	PHONE_A_FRIEND_SEND="send_tiles",
	PHONE_A_FRIEND_RECEIVE="receive_tiles",
	PHONE_A_FRIEND_SEND_CURSED="send_tiles_cursed",
	PHONE_A_FRIEND_RECIVE_CURSED="receive_tiles_cursed",
	ECHO="echo",
	ECHO_CURSED="echo_cursed",
	CANDY_ROUND_HEALING="candy_round_healing",
}

### Spells
const SPELLS:Dictionary[StringName,String]={
	PARTY_TELEPHONE=NAMESPACE+"party_telephone",
	POSTAGE_STAMP=NAMESPACE+"postage_stamp",
	BLUE_BOX=NAMESPACE+"blue_box",
	REMOTE_OBJECT=NAMESPACE+"remote_object",
	TV_SNOW=NAMESPACE+"tv_snow",
	GIFT_COOP=NAMESPACE+"gift_coop",
	MIRACLE_CACHE_COOP=NAMESPACE+"miracle_cache_coop",
	MINUTE_OF_HATE=NAMESPACE+"minute_of_hate",
	SSN_PRINTER=NAMESPACE+"ssn_printer",
	PRINTED_SSN=NAMESPACE+"printed_ssn",
	SNEAKERNET=NAMESPACE+"sneakernet",
	BUG_SPRAY=NAMESPACE+"bug_spray",
}

const SPELL_WEIGHTS:Dictionary[String,float]={
	SPELLS.PARTY_TELEPHONE:2.0,
	SPELLS.POSTAGE_STAMP:1.75,
	SPELLS.BLUE_BOX:1.0,
	SPELLS.REMOTE_OBJECT:2.0,
	SPELLS.TV_SNOW:2.0,
	SPELLS.SSN_PRINTER:2.0,
	SPELLS.MINUTE_OF_HATE:2.0,
	SPELLS.SNEAKERNET:1.5,
}

const GIFT_SPELLS:Array[String]=[
	SPELLS.GIFT_COOP,
	SPELLS.MIRACLE_CACHE_COOP
]

const SPELL_UPGRADES={
	SPELLS.GIFT_COOP:SPELLS.MIRACLE_CACHE_COOP
}

const REMOVED_SPELLS:PackedStringArray=[
	Globals.SPELLS.RED_TAPE,
]

const STATUS={
	STAMPED=NAMESPACE+"stamped",
	TIMED=NAMESPACE+"timed",
}

## Callbacks
const CALLBACKS={
	REVIVE_EARLY=NAMESPACE+"player_pre_revived",
	REVIVE_LATE=NAMESPACE+"player_post_revived",
	
	CONNECT_EARLY=NAMESPACE+"connect_early",
	CONNECT_MAIN=NAMESPACE+"connect_main",
	CONNECT_LATE=NAMESPACE+"connect_late",
}

## awaited void REVIVE()
const REVIVE_CALLBACKS=[
	CALLBACKS.REVIVE_EARLY,
	CALLBACKS.REVIVE_LATE
]

## void CONNECT(hosting:bool,lobby_id:int) [br]
## [param lobby_id]: the steam id for the lobby joined. 0 if joining an IP lobby. [br][br]
## Emitted when connected to the host / hosting a game and going to the lobby screen
const CONNECT_CALLBACKS=[
	CALLBACKS.CONNECT_EARLY,
	CALLBACKS.CONNECT_MAIN,
	CALLBACKS.CONNECT_LATE,
]

const BUGS=[
	#76561198057895955,#Starblock
	#76561198041843538,#Ciirulean
	76561198172774482,#DeadInfinity
	#76561198273453230,#RENREN
	76561198150996567,#Finley
	76561198025169706,#SeaCharmeleon
	76561198796950574,#Pearl
]

const CUSTOM_CHARACTER_ICONS:Dictionary[int,Texture2D]={
	76561198041843538:preload("res://mods/co-op/arte/ui/player_icons/cadence.png"),#Ciirulean
	76561198172774482:preload("res://mods/co-op/arte/ui/player_icons/hazel.png"),#DeadInfinity
	76561198273453230:preload("res://mods/co-op/arte/ui/player_icons/renren.png"),#RENREN
	76561198984198927:preload("res://mods/co-op/arte/ui/player_icons/xander.png"),#Xanderath
	76561198057895955:preload("res://mods/co-op/arte/ui/player_icons/starblock.png"),#Starblock
	76561199096565403:preload("res://mods/co-op/arte/ui/player_icons/teoc.png"),#TeoC
	76561199089530630:preload("res://mods/co-op/arte/ui/player_icons/tenex.png"),#Tenex
	76561198365921509:preload("res://mods/co-op/arte/ui/player_icons/Neco-Arc.png"),#wifflenany
	76561199379043101:preload("res://mods/co-op/arte/ui/player_icons/krispotrait.png"),#niko
}

var unloaded_intents:Array[String]=INTENTS.values()


func _process(_delta: float) -> void:
	for intent in unloaded_intents:
		var path=intent_icon_path+intent+".png"
		var status=ResourceLoader.load_threaded_get_status(path)
		if status==ResourceLoader.THREAD_LOAD_LOADED:
			CustomIntent.custom_intent_icons[intent]=ResourceLoader.load_threaded_get(path)
			unloaded_intents.erase(intent)
		elif status!=ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			push_error("Error threaded loading ",path," code: ",status)
			unloaded_intents.erase(intent)


func _ready()->void:
	ProjectSettings.set_setting("application/run/flush_stdout_on_print",true) # not sure if this actually does anything
	
	# unbind z so you can use it in your name
	var key_to_remove=InputEventKey.new()
	for key in [KEY_Z,KEY_SPACE]:
		key_to_remove.physical_keycode=key
		InputMap.action_erase_event("ui_accept",key_to_remove)
	
	version_number=mod_data.json.data.version
	if mod_data.json.data.author!=AUTHOR:
		push_error("some shenanagens are afoot >:(\n Please don't remove my name from the mod!")
		Game.set_script(ResourceLoader.load("res://source/autoload/game.gd","",ResourceLoader.CACHE_MODE_IGNORE))
		return
	
	print("coop mod version:",COOP_VERSION)
	#var scene_tree=get_tree()
		
	for intent in INTENTS.values():
		ResourceLoader.load_threaded_request(intent_icon_path+intent+".png")
	
	await get_tree().process_frame
	Game.coop=self

	var cmdline_args:=OS.get_cmdline_args()
	var connect_arg_pos:=cmdline_args.find("+connect_lobby")
	if connect_arg_pos>=0 and cmdline_args.size()>connect_arg_pos+1:
		#connect to steam lobby
		var steam_lobby_id=int(cmdline_args[connect_arg_pos+1])
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


func reserve_callbacks() -> void:
	for callback_id in CALLBACKS.values():
		CallbackManager.reserve_callback(self,callback_id)
		


func register_callbacks(helper: CallbackHelper) -> void:
	helper.add_callback(Callbacks.REGISTER_SPELLS.MOD,register_spells,0)
	helper.add_callback(Callbacks.REGISTER_EFFECTS.MOD,register_statuses,0)


func register_spells():
	SpellRegistry.register(self,SPELLS.values())
	#SpellRegistry.register(self,BANNED_CURSES_SPELL_DATA,load("res://mods/co-op/source/spell/spell_data_banned_curses.gd"))
	SpellRegistry.add_spells_to_pool(SPELL_WEIGHTS)
	for spell in REMOVED_SPELLS:
		SpellRegistry.spell_pool[spell]=0
	SpellRegistry.spell_pool[SPELLS.BUG_SPRAY]=SpellRegistry.spell_pool[Globals.SPELLS.BUG_SPRAY]
	SpellRegistry.spell_pool[Globals.SPELLS.BUG_SPRAY]=0


func register_statuses():
	EffectRegistry.register(self,STATUS.values())


func get_spell_ids() -> Array[String]:
	return SPELLS.values()


func get_run_save_data() -> Dictionary:
	var data= {
		others_submitted_words=Game.word_builder.others_submitted_words,
		player_total_damage=Game.word_builder.player_total_damage,
		candy_round=Game.main.candy_round,
		original_id=Game.main.original_id,
		all_player_names=Game.all_player_names,
		
		# summary stats
		strawman_taps=Game.main.strawman_taps,
		screenshots_taken=Game.main.screenshots_taken,
		deaths=Game.main.deaths,
		}
	if not Game.main.phone_board.is_slid_out:
		data.phone_board=Game.main.phone_board.get_save_data()
	
	return data


func load_run_save_data(data: Dictionary) -> void:
	Game.word_builder.others_submitted_words=data.others_submitted_words
	Game.word_builder.player_total_damage=data.player_total_damage
	Game.main.original_id=data.get("original_id",multiplayer.get_unique_id())
	Game.main.candy_round=data.candy_round
	if data.candy_round:
		Game.main.peer_died.rpc()
	Game.set_original_id.rpc(Game.main.original_id)
	Game.all_player_names.merge(data.all_player_names)
	
	
	# summary stats
	Game.main.screenshots_taken=data.screenshots_taken
	Game.main.strawman_taps=data.strawman_taps
	Game.main.deaths=data.deaths
	
	if "phone_board" in data:
		await get_tree().process_frame
		Game.main.phone_board.load_save_data(data.phone_board)
		Game.tile_board.prepare_to_animate()
		Game.tile_board.position.x=180
		Game.tile_board.finish_animating()


func get_options_save_data() -> Dictionary:
	return {
		dont_bug_me=Game.player_info.dont_bug_me
	}


func load_options_save_data(data: Dictionary) -> void:
	Game.player_info.dont_bug_me=data.get("dont_bug_me",false)


static func is_bug(peer_id:int)->bool:
	return Game.players[peer_id].steam_id in BUGS and not Game.players[peer_id].dont_bug_me


static func get_character_icon(peer_id:int,use_steam_avatar:=false)->Texture2D:
	var steam_id=Game.players[peer_id].steam_id
	if steam_id in CUSTOM_CHARACTER_ICONS and not Game.players[peer_id].dont_bug_me:
		return CUSTOM_CHARACTER_ICONS[steam_id]
	elif steam_id in BUGS and not Game.players[peer_id].dont_bug_me:
		return load("res://mods/co-op/arte/ui/bug.png")
	else:
		if use_steam_avatar and steam_id>0:
			#set steam avatar
			var steam_avatar=await Bridge.get_avatar(steam_id)
			if steam_avatar.get_size()!=Vector2.ZERO:
				return steam_avatar
		
		var character_texture=load("res://mods/co-op/source/ui/character_icon_texture.tres").duplicate()
		character_texture.set_character(Game.players[peer_id].character, (Globals.is_character_trans(Game.players[peer_id].character,Game.difficulty,false)))
		return character_texture


static func get_mod_callback_ids(indetifiers:Array[String])->Array[int]:
	return indetifiers.map(CallbackManager.get_mod_callback_id)
