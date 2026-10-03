extends MenuPanel
@export var steam_join_menu:MenuPanel

func animate_appear(instant: bool = false) -> void:
	await sequenced_appear([$LobbySearch,$LobbyFilterMenu,$RefreshButton],instant,.05,true)

func animate_disappear(instant: bool = false) -> void:
	await sequenced_disappear([$LobbySearch,$LobbyFilterMenu,$RefreshButton],instant,.05)

func open_steam_join_menu()->void:
	menu_controller.set_menu(steam_join_menu)
