extends SelectorIcon

var lobby_type:Steam.LobbyType=Steam.LOBBY_TYPE_PRIVATE

func set_lobby_type(type:Steam.LobbyType):
	lobby_type=type
	%VisibilityIcon.frame=type as int
