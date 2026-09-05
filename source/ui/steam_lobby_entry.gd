extends Control

var lobby_id:=0
signal pressed(lobby_id)
var character_icon_scene:PackedScene=load("res://source/ui/icons/character_icon.tscn")
var character_icons:=[]

func set_lobby_id(_lobby_id:int):
	lobby_id=_lobby_id
	var num_lobby_members=Steam.getNumLobbyMembers(lobby_id)
	var lobby_name= Steam.getLobbyData(lobby_id,"name")
	if lobby_name.is_empty():
		%Title.text=str(lobby_id)
	else:
		%Title.text=lobby_name
	%MemberCount.text=str(num_lobby_members)+"/"+str(Steam.getLobbyMemberLimit(lobby_id))
	var difficulty=Steam.getLobbyData(lobby_id,"difficulty")
	if not difficulty.is_empty():
		difficulty=int(difficulty)
		%DifficultyIcon.set_difficulty(int(difficulty))
	else:
		difficulty=0
	
	for icon in character_icons:
		icon.hide()
	
	var new_character_icons=[]
	for i in mini(Steam.getNumLobbyMembers(lobby_id),10):
		var member_id=Steam.getLobbyMemberByIndex(lobby_id,i)
		var character=Steam.getLobbyMemberData(lobby_id,member_id,"character")
		print("steam lobby character: ",character)
		var character_icon
		if character_icons.is_empty():
			character_icon=character_icon_scene.instantiate()
			character_icon.scale=Vector2(0.5,0.5)
			var character_icon_control=Control.new()
			character_icon_control.custom_minimum_size=Vector2(9,16)
			character_icon_control.add_child(character_icon)
			%CharacterIcons.add_child(character_icon_control)
		else:
			character_icon=character_icons.pop_back()
			character_icon.show()
		character_icon.set_character(character,difficulty>0 and difficulty<10)
		new_character_icons.append(character_icon)
	for icon in character_icons:
		icon.get_parent().queue_free()
	character_icons=new_character_icons

func _join_pressed():
	pressed.emit(lobby_id)
