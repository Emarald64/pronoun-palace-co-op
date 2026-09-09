extends Control

var lobby_id:=0
signal pressed(lobby_id)
var character_icon_scene:PackedScene=load("res://source/ui/icons/character_icon.tscn")
var character_icons:Dictionary[int,CharacterIcon]
var difficulty

func set_lobby_id(_lobby_id:int):
	lobby_id=_lobby_id
	var num_lobby_members=Steam.getNumLobbyMembers(lobby_id)
	var lobby_name= Steam.getLobbyData(lobby_id,"name")
	if lobby_name.is_empty():
		%Title.text=str(lobby_id)
	else:
		%Title.text=lobby_name
	%MemberCount.text=str(num_lobby_members)+"/"+str(Steam.getLobbyMemberLimit(lobby_id))
	difficulty=Steam.getLobbyData(lobby_id,"difficulty")
	if not difficulty.is_empty():
		difficulty=int(difficulty)
		%DifficultyIcon.set_difficulty(int(difficulty))
	else:
		difficulty=0
	
	#for icon in character_icons:
		#icon.hide()
	
	#Steam.lobby_data_update.connect(_lobby_data_update)
	
	#print_debug(Steam.requestLobbyData(lobby_id))
		#var new_character_icons=[]
		#for i in mini(num_lobby_members,10):
			#
		#for icon in character_icons:
			#icon.get_parent().queue_free()
		#character_icons=new_character_icons

func _join_pressed():
	pressed.emit(lobby_id)

#func _lobby_data_update(success,lobby_id,_member_id):
	#print_debug(success," ",lobby_id," ",_member_id)
	#if success and self.lobby_id==lobby_id:
		#if _member_id!=lobby_id or true:
			#var count=Steam.getNumLobbyMembers(lobby_id)
			#var member_id=Steam.getLobbyMemberByIndex(lobby_id,0)
			#print(count," ",lobby_id," ",member_id)
			#var character=Steam.getLobbyMemberData(lobby_id,member_id,"character")
			#print("steam lobby character: ",character)
			#var character_icon
			#if member_id not in character_icons:
				#character_icon=character_icon_scene.instantiate()
				#character_icon.scale=Vector2(0.5,0.5)
				#var character_icon_control=Control.new()
				#character_icon_control.custom_minimum_size=Vector2(9,16)
				#character_icon_control.add_child(character_icon)
				#%CharacterIcons.add_child(character_icon_control)
				#character_icons[member_id]=character_icon
			#else:
				#character_icon=character_icons[member_id]
				#character_icon.show()
			#character_icon.set_character(character,difficulty>0 and difficulty<10)
			#new_character_icons.append(character_icon)
