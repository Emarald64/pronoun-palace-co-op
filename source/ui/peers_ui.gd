extends Control

var pushed_off:=false
const TILES_TO_MOVE=12
var tween:Tween

var damage_indecators:Dictionary[int,Control]={}
var disable_sorting:=false

@onready var word_builder=Game.word_builder
@onready var total_attack_label=%TotalAttackLabel
@onready var damage_indecator_holder=%DamageIndecatorHolder
@onready var total_attack_container=%TotalAttackContainer

func _ready():
	await get_tree().process_frame
	Game.player.selection_started.connect(start_selecting)
	Game.player.selection_finished.connect(stop_selecting)

func _on_game_state_updated():
	if word_builder.tiles.size()>=TILES_TO_MOVE and not pushed_off:
		if tween:
			tween.kill()
		tween=get_tree().create_tween()
		tween.tween_property(self,"position",Vector2(-20,0),.2)
		pushed_off=true
		#position.x=-20
	elif word_builder.tiles.size()<TILES_TO_MOVE and pushed_off:
		if tween:
			tween.kill()
		tween=get_tree().create_tween()
		pushed_off=false
		tween.tween_property(self,"position",Vector2.ZERO,.2)
		#position.x=0

func update_damage_indecator(id:int,data:Dictionary):
	var damage_indecator:Control
	if id in damage_indecators:
		damage_indecator=damage_indecators[id]
		damage_indecator.show()
	else:
		#create new damage indecator
		damage_indecator=preload("res://mods/co-op/source/ui/peer_damage_indecator.tscn").instantiate()
		damage_indecators[id]=damage_indecator
		damage_indecator_holder.add_child(damage_indecator)
		damage_indecator.setup(id)
	damage_indecator.update(data)
	
	if not disable_sorting:
		# move damage indecator to match attack
		var ordered_damage_indecators=damage_indecator_holder.get_children()
		ordered_damage_indecators.erase(damage_indecator)
		var index=ordered_damage_indecators.bsearch_custom(damage_indecator,order_peer_ui)
		if index>damage_indecator.get_index():
			index+=1
		damage_indecator_holder.move_child(damage_indecator,index)

func update_total_damage_counter(total_damage:int):
	#var total_damage=damage
	if Game.enemy!=null and Game.enemy.id==Enemies.HOUSEBROKEN and Game.enemy.passcode in Game.word_builder.get_words().words:
		var health_scaling=Game.enemy._get_health_scaling()
		total_damage+=health_scaling[clampi(Game.balance.enemy_health,0,health_scaling.size()-1)]
	
	total_damage=word_builder.peer_attacks.values().reduce(
		func (accum:int,peer_attack)->int:
			return accum+peer_attack.damage
	,total_damage)
	
	#if total_damage>0:
	total_attack_container.show()
	total_attack_label.text=str(total_damage)

func reset_peers():
	for indecator in damage_indecators.values():
		indecator.set_dead(false)
		indecator.hide()
	total_attack_container.hide()

func set_dead(id:int,dead:bool=true):
	damage_indecators[id].set_dead(dead)

func remove_peer(id:int):
	damage_indecators[id].queue_free()
	damage_indecators.erase(id)

func start_selecting():
	if Game.main.player.is_selecting(CoOp.PEER_SELECTION_TYPE):
		disable_sorting=true

func stop_selecting():
	if disable_sorting:
		sort_peers()
		disable_sorting=false

func sort_peers():
	var sorted_idecators=damage_indecators.values()
	sorted_idecators.sort_custom(order_peer_ui)
	for i in sorted_idecators.size():
		damage_indecator_holder.move_child(sorted_idecators[i],i)

func order_peer_ui(a,b)->bool:
	if not a.visible:
		return false
	if not b.visible:
		return true
	return word_builder.get_peer_priority(a.peer_id)>word_builder.get_peer_priority(b.peer_id)
