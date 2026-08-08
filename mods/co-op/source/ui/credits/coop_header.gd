@tool
extends StringKeyRichLabel

func _ready() -> void:
	var group=StringManager.get_string_group("mod/co-op/names")
	var name_variation=group.strings.keys().pick_random()
	key="mod/co-op/names/%s" % name_variation
