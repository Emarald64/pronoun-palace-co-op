extends TileDecor

@onready var timer_label=%TimerLabel

func get_layer() -> Layer:
	return Layer.FACE


func get_priority() -> int:
	return Callbacks.BASE_GAME_PRIORITY.SECOND


func _tile_sprite_updated() -> void:
	timer_label.color=tile_sprite.tile_face.get_face_color()
	timer_label.deboss_color=tile_sprite.tile_face.get_deboss_color()

func set_text(text:String)->void:
	timer_label.text=text
