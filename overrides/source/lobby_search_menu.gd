extends MenuPanel

func animate_appear(instant: bool = false) -> void:
	await sequenced_appear([$LobbySearch,$LobbyFilterMenu],instant,.05,true)

func animate_disappear(instant: bool = false) -> void:
	await sequenced_disappear([$LobbySearch,$LobbyFilterMenu],instant,.05)
