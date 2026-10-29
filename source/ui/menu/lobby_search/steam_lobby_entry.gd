extends Control

var lobby_id:=0
signal pressed(lobby_id)
var character_icon_scene:PackedScene=load("res://source/ui/icons/character_icon.tscn")
var character_icons:Array[CharacterIcon]
var difficulty

func set_lobby_id(_lobby_id:int):
	lobby_id=_lobby_id
	var lobby_name= Steam.getLobbyData(lobby_id,"name")
	if lobby_name.is_empty():
		%Title.text=str(lobby_id)
	else:
		%Title.text=lobby_name
	difficulty=Steam.getLobbyData(lobby_id,"difficulty")
	if not difficulty.is_empty():
		difficulty=int(difficulty)
		%DifficultyIcon.set_difficulty(int(difficulty))
	else:
		difficulty=0

func _join_pressed():
	pressed.emit(lobby_id)

func lobby_updated():
	var num_lobby_members=Steam.getNumLobbyMembers(lobby_id)
	%MemberCount.text=str(num_lobby_members)+"/"+str(Steam.getLobbyMemberLimit(lobby_id))
	
	update_characters(Steam.getLobbyData(lobby_id,"characters"))

func update_characters(characters:String):
	var new_character_icons:Array[CharacterIcon];
	for character in characters.split(","):
		var character_icon=character_icons.pop_front()
		if character_icon==null:
			character_icon=character_icon_scene.instantiate()
			%CharacterIcons.add_child(character_icon)
		character_icon.set_character(character,difficulty>0)
		new_character_icons.append(character_icon)
	for old_character_icon in character_icons:
		old_character_icon.queue_free()
	character_icons=new_character_icons
