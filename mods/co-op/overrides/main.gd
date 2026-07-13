extends Main

func start_battle(skipping_transition = false):
	super(skipping_transition)
	enemy.max_health*=Game.players.size()
	enemy.health=enemy.max_health

func save_and_exit():
	multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	super()
