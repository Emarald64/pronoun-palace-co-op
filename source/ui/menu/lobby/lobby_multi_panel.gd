extends MenuPanel

func animate_appear(instant: bool = false) -> void:
	var panels:Array[MenuPanel]=[$LobbyMainPanel]
	if multiplayer.is_server():
		panels.append($MenuButtonRight)
	await sequenced_appear(panels,instant,.05,true)

func animate_disappear(instant: bool = false) -> void:
	var panels:Array[MenuPanel]=[$LobbyMainPanel,$MenuButtonRight]
	#if multiplayer.is_server():
		#panels.append($MenuButtonRight)
	await sequenced_disappear(panels,instant,.05)
