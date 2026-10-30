class_name StarblockTortureMinigame
extends Minigame

var fish_scene:PackedScene=load("res://source/minigames/tile_fish.tscn")

var wood_crits:=0
var plastic_crits:=0

var wood_crits_on_board:=0
var plastic_crits_on_board:=0

var letter_pool = "qjxzwkvfybhmpgudcllooottnnrraaaiiissseeeee"
var letter_bag =[]

var stopped_slot_count:=0

var rng:=RNG.new()

@export var slots:Array[SlotReel]

func _ready():
	var crits=Game.tile_board.get_tiles({status=Globals.TileStatus.CRIT})
	for tile in crits:
		if tile.is_type(Globals.TileType.DAMAGE):
			wood_crits_on_board+=1
		elif tile.is_type(Globals.TileType.DEFENSE):
			plastic_crits_on_board+=1
	#slots[0].active=true

func get_letter()->String:
	if letter_bag.is_empty():
		letter_bag=Array(letter_pool.split())
		rng.shuffle(letter_bag)
	return letter_bag.pop_back()

func slot_clicked(idx:int):
	var tile=slots[idx].active_tile
	if tile.has_status(Globals.TileStatus.CRIT):
		if tile.is_type(Globals.TileType.DAMAGE):
			wood_crits+=1
			wood_crits_on_board+=1
		elif tile.is_type(Globals.TileType.DEFENSE):
			plastic_crits+=1
			plastic_crits_on_board+=1
	
	stopped_slot_count+=1
	if stopped_slot_count>=4:
		finished.emit()

func get_selected_fish():
	var fishies:Array[Fish]
	for slot in slots:
		var fish=fish_scene.instantiate()
		Game.main.add_child(fish)
		fish.get_node("%Tile").load_save_data(slot.active_tile.get_save_data())
		fishies.append(fish)
	return fishies

func reseed(source_rng:RandomNumberGenerator):
	rng.reseed(source_rng)
