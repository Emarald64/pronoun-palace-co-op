extends "res://source/ui/menu/settings/settings_menu.gd"

func _ready():
	super()
	var coop=ModLoader.get_node("coop")
	%ExtraHateTime.set_setting_methods(
		coop.get.bind("extra_hate_time"),
		coop.set_extra_hate_time
		)
