extends Spell


var minigame_scene = preload("res://mods/co-op/overrides/fishing_minigame.tscn")
var minigame: FishingMinigame = null
var fish_launcher = FishLauncher.new(self)
var timer: CancelableTimeout = null


func _use():
	if Game.random.randi_range(1, 5) == 1:
		trigger_hum()

	start_minigame()
	await minigame.finished

	var caught_fish = minigame.caught_fish.duplicate(true)
	await fish_launcher.launch_fish(caught_fish)

	if timer != null:
		timer.cancel()
		timer = null

	minigame = null

	_post_use()


func trigger_hum() -> void :
	timer = Game.cancelable_timeout(randf_range(1.0, 3.0))
	await timer.cancel_or_timeout
	if timer.is_canceled:
		return

	timer = null

	AudioManager.effects.duck_music.set_enabled(true)
	var playback: = AudioManager.play_sound(Sounds.FISHER.HUM)
	playback.finished.connect( func(): AudioManager.effects.duck_music.set_enabled(false))


func start_minigame():
	minigame = minigame_scene.instantiate()
	minigame.reseed(rng.spell)
	minigame.start()


func end_minigame():
	minigame.end()
