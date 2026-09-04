extends Control

var lobby_id:=0
signal pressed(lobby_id)

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
		%DifficultyIcon.set_difficulty(int(difficulty))

func _join_pressed():
	pressed.emit(lobby_id)
