extends MainMenu

func _ready():
	%DailyButton.queue_free()
	
	%CharacterSelect.start_button.pressed.disconnect(%CharacterSelect._on_start_button_pressed)
	%CharacterSelect.start_button.pressed.connect(func ():
		Game.difficulty=%CharacterSelect.difficulty
		Game.player_info.character=%CharacterSelect.character
		%CreateServerMenu.continuing_game=false
	)
	%CharacterSelect.start_button.opens_menu=%CreateServerMenu
	super()

func _on_continue_button_pressed():
	
	%CreateServerMenu.continuing_game=true

func update_daily_button():
	pass
