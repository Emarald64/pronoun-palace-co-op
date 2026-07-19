class_name CoOp
extends Mod

var character_select
var host_name:LineEdit

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

func _ready()->void:
	var scene_tree=get_tree()
	scene_tree.scene_changed.connect(_on_scene_changed)
	var current_scene=scene_tree.current_scene
	if current_scene is MainMenu:
		main_menu_additions(current_scene)
	
	
	CustomIntent.custom_intent_icons["phone_a_friend_send"]=preload("res://mods/co-op/intents/pronounpalace-sendtilesx-px.png")
	CustomIntent.custom_intent_icons["phone_a_friend_recive"]=preload("res://mods/co-op/intents/pronounpalace-receivetiles-px.png")
	CustomIntent.custom_intent_icons["phone_a_friend_send_cursed"]=preload("res://mods/co-op/intents/pronounpalace-sendtilescursed-px.png")
	CustomIntent.custom_intent_icons["phone_a_friend_recive_cursed"]=preload("res://mods/co-op/intents/pronounpalace-receivetilescursed-px.png")
	
	CustomIntent.custom_intent_icons["echo"]=preload("res://mods/co-op/intents/pronounpalace-receivetiles-px.png")
	CustomIntent.custom_intent_icons["echo_cursed"]=preload("res://mods/co-op/intents/pronounpalace-receivetilescursed-px.png")
	
	SpellLoader.spell_pool.erase("mba")
	SpellLoader.spell_pool.erase("panic_button")
	SpellLoader.spell_pool.erase("red_tape")
	SpellLoader.add_spell("party_telephone",10.0,Globals.SPELL_CATEGORY.SUPPORT)
	
	await get_tree().process_frame
	Globals.set_script(preload("res://mods/co-op/overrides/custom_globals.gd"))
	
	# replace game script
	await get_tree().create_timer(.5).timeout
	change_script_and_copy_properties(Game,preload("res://mods/co-op/overrides/game.gd"))
	
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
	var start_button=character_select.get_node("StartButton")
	start_button.pressed.disconnect(character_select._on_start_button_pressed)
	start_button.pressed.connect(save_character_selector_info)
	start_button.opens_menu=create_server_menu
	
	#host_name=LineEdit.new()
	#host_name.placeholder_text="Name"
	#character_select.add_child(host_name)

#func main_aditions(main:Main)->void:
	#var damage_indecator_holder=HBoxContainer.new()
	#damage_indecator_holder.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	#damage_indecator_holder.grow_horizontal=Control.GROW_DIRECTION_BEGIN
	#main.get_node("HUDLayer").add_child(damage_indecator_holder)
	
	#var word_builder=main.get_node("GameUILayer/WordBuilder")
	#word_builder.set_script(preload("res://mods/co-op/overrides/word_builder.gd"))
	#word_builder._ready()
	#word_builder.damage_indecator_holder=damage_indecator_holder

func save_character_selector_info()->void:
	Game.difficulty=character_select.difficulty
	Game.player_info.character=character_select.character
