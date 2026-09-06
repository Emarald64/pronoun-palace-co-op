@tool
extends "res://source/ui/menu/buttons/menu_label_button.gd"

@export var ip_join_menu:MenuPanel

func _on_button_pressed():
	if Bridge.steam_initialize_failed and not Engine.is_editor_hint():
		opens_menu=ip_join_menu
	super()
