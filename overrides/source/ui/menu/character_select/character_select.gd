extends "res://source/ui/menu/character_select/character_select.gd"


func _on_character_selector_selected() -> void :
	SaveManager.get_save_data().selected_character = character
	difficulty_selector.set_character(character)
	start_button.set_disabled( not Globals.is_character_unlocked(character) or character==Globals.CHARACTERS.ADDICT)
