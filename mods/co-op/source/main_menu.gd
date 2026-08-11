extends MainMenu

func _ready():
	%ContinueButton.queue_free()
	
	%CharacterSelect.start_button.pressed.disconnect(%CharacterSelect._on_start_button_pressed)
	%CharacterSelect.start_button.pressed.connect(func ():
		Game.difficulty=%CharacterSelect.difficulty
		Game.player_info.character=%CharacterSelect.character
	)
	%CharacterSelect.start_button.opens_menu=%CreateServerMenu
	super()
