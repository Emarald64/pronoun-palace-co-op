class_name SlotReel
extends Node2D

@export var tiles:Array[Tile]

var active_tile:Tile:
	get():
		return tiles[2]

@export var speed:=1.0
var time_until_advance:=1.0
@export var acceleration=0.25
#var active:=false

@export var minigame:StarblockTortureMinigame

signal clicked

const DEFENSE_CRIT_CHANCE=.05
const DAMAGE_CRIT_CHANCE=.033

const broken_enemies=[Enemies.UMAMI,Enemies.SALT]

func _ready() -> void:
	for i in 5:
		advance()

func _physics_process(delta: float) -> void:
	time_until_advance-=speed*delta
	if time_until_advance<=0:
		advance()
		time_until_advance+=1
	if speed>0:
		speed+=acceleration*delta
	if speed>15:
		on_click()

func advance():
	for i in range(tiles.size()-1,0,-1):
		tiles[i].load_save_data(tiles[i-1].get_save_data())
	
	var tile=tiles[0]
	if minigame.rng.randf() < Game.balance.defense_fish_chance:
		tiles[0].set_type(Globals.TileType.DEFENSE)
	else:
		tiles[0].set_type(Globals.TileType.DAMAGE)
	
	tiles[0].set_face(minigame.get_letter())
	var crit_chance:float
	if tiles[0].is_type(Globals.TileType.DEFENSE):
		crit_chance=DEFENSE_CRIT_CHANCE
		if minigame.plastic_crits>1 or minigame.plastic_crits_on_board>2:
			crit_chance/=2
		elif minigame.plastic_crits>2 or minigame.plastic_crits_on_board>3:
			crit_chance=0
	elif tiles[0].is_type(Globals.TileType.DAMAGE):
		crit_chance=DEFENSE_CRIT_CHANCE
		if minigame.wood_crits>1 or minigame.wood_crits_on_board>2:
			crit_chance/=2
		elif minigame.wood_crits>2 or minigame.wood_crits_on_board>3:
			crit_chance=0
	
	var fish=Fish.new()
	fish.tile=tiles[0]
	fish.reseed(minigame.rng)
	
	tile.remove_statuses()
	if minigame.rng.randf()<crit_chance:
		tiles[0].add_status(Globals.TileStatus.CRIT)
	elif Game.enemy.id not in broken_enemies:
		Game.enemy.apply_fish(tiles[0],fish)
	
	if Game.enemy.id not in broken_enemies:
		Game.enemy.apply_any_fish(tiles[0],fish)
	
	if (
		tile.faces.size() == 1
		and tile.faces[0] in Letters.ALPHABET
		and not tile.has_status(Globals.TileStatus.LINKED)
	):
		if minigame.rng.randf() < Game.balance.capital_period_chance_fishing:
			if minigame.rng.randi_range(0, 1) == 0:
				tile.set_face(Letters.get_random_capital_letter(minigame.rng))
				tile.add_status(Globals.TileStatus.CAPITAL)
			else:
				tile.set_face(Letters.get_random_period_letter(minigame.rng))
				tile.add_status(Globals.TileStatus.PERIOD)
		elif minigame.rng.randf() < Game.balance.bigram_chance_fishing:
			if minigame.rng.randf() < Game.balance.bigram_become_trigram_chance:
				tile.set_face(Letters.get_random_trigram(minigame.rng))
			else:
				tile.set_face(Letters.get_random_bigram(null, minigame.rng))
	
	fish.queue_free()

func on_click():
	#if active:
	speed=0
	#active=false
	modulate=Color(0.6, 0.6, 0.6)
	clicked.emit()
