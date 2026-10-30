extends Spell

var minigame_scene = load("res://mods/co-op/source/minigames/starblock_torture_minigame.tscn")
var minigame: StarblockTortureMinigame = null
var fish_launcher := FishLauncher.new(self)
var timer: CancelableTimeout = null


func _use():
	if Game.random.randi_range(1, 5) == 1:
		trigger_hum()

	start_minigame()
	await minigame.finished

	var caught_fish = minigame.get_selected_fish()
	await fish_launcher.launch_fish(caught_fish)

	if timer != null:
		timer.cancel()
		timer = null

	minigame = null

	_post_use()


func trigger_hum() -> void:
	timer = Game.cancelable_timeout(randf_range(1.0, 3.0))
	await timer.cancel_or_timeout
	if timer.is_canceled:
		return

	timer = null

	AudioManager.effects.duck_music.set_enabled(true)
	var playback : AudioManagerSingleton.SoundPlayback= AudioManager.play_sound(Sounds.FISHER.HUM)
	playback.finished.connect(func(): AudioManager.effects.duck_music.set_enabled(false))


func start_minigame():
	minigame = minigame_scene.instantiate()
	minigame.reseed(rng.spell)
	minigame.start()


func end_minigame():
	minigame.end()

func get_texture(_spell_id: String = spell_data.get_base_id()) -> Texture2D:
	return load("res://arte/spells/fishing_rod.png")
