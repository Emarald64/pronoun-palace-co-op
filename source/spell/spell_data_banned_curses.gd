class_name SpellDataBannedCurses
extends SpellData

var banned_curses:Array[String]=[]

func can_have_curse(curse):
	return curse not in banned_curses and super(curse)

func load_data() -> void:
	var group:=get_string_group()
	if group.has_string("banned_curses"):
		banned_curses=group.get_string("banned_curses").split(" ")
