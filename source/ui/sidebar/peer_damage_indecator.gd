extends Control

@export var color_changing_shadow_cloners:Array[ShadowCloner]
@onready var button:Button=$Button
var peer_id:=0

func _ready() -> void:
	%AttackSprite.texture=%AttackSprite.texture.duplicate()
	$HoverHandler.disabled=true
	$TooltipCollision.enabled=false


func setup(id:int)->void:
	Game.player.selection_started.connect(start_selecting)
	Game.player.selection_finished.connect(stop_selecting)
	if Game.is_playtester(id):
		%CharacterIcon.texture=load("res://mods/co-op/arte/ui/bug.png")
		%CharacterIcon.hframes=1
		%CharacterIcon.vframes=1
	else:
		set_character(Game.players[id].character)
	%Name.text=Game.players[id].name
	peer_id=id

func update(damage_info:Dictionary):
	%AttackSprite.texture.region.position=Vector2(73,91) if damage_info.valid else Vector2(90,145)

	%AttackLabel.text=str(damage_info.damage)
	
	%DefendLabel.text=str(damage_info.defense)
	
	%HealthLabel.text=str(damage_info.health)
	
	#print(damage_info)
	$Panel.self_modulate=Color("aaff96") if damage_info.submitted else Color.WHITE
	var shadow_color=Color("74b054") if damage_info.submitted else Color("c4a1a1")
	for shadow_cloner in color_changing_shadow_cloners:
		shadow_cloner.solid_shadow_color=shadow_color
	#get_tree().set_group(&"shadow_cloner_change_color","solid_shadow_color",)

func set_character(character:String)->void:
	%CharacterIcon.set_character(character,true)

func set_dead(dead:bool):
	%Dead.visible=dead

func _on_button_pressed() -> void:
	if Game.main.player.is_selecting(CoOp.PEER_SELECTION_TYPE):
		Game.main.player.selected.emit(peer_id)
		AudioManager.play_sound(Sounds.SPELLS.SPELL_CLICK)

func start_selecting()->void:
	if Game.main.player.is_selecting(CoOp.PEER_SELECTION_TYPE):
		var selection_valid=Game.player.passes_selection_condition(peer_id)
		$Button.disabled=not selection_valid
		$HoverHandler.set_disabled(not selection_valid)
		modulate=Color.WHITE if selection_valid else Color.GRAY
		$TooltipCollision.enabled=Game.player.active_spell.has_method("_generate_peer_tooltip")


func stop_selecting():
	$TooltipCollision.enabled=false
	$TooltipCollision.clear_tooltip()
	$Button.disabled=true
	$HoverHandler.set_disabled(true)
	modulate=Color.WHITE

func _on_generate_tooltip(tooltip:GameTooltip):
	#print("peer ui tried making tooltip")
	Game.player.active_spell._generate_peer_tooltip(tooltip,peer_id)
