extends CanvasItem

#var tile:Tile
#var overlay:Node2D
#var material:=preload("res://mods/co-op/source/effects/tv_static_material.tres")
var time:=0.0
var applied_frozen:=false
func _ready() -> void:
	AudioManager.play_sound({
		SOUND=preload("res://mods/co-op/sounds/staticclick.wav"),
		PITCH_VARIANCE=.2}
	)

func _process(delta: float) -> void:
	time+=delta
	if time>.4:
		queue_free()
	if time>.2 and not applied_frozen:
		get_parent().add_status(Globals.TileStatus.FROZEN)
		applied_frozen=true
	set_instance_shader_parameter("time",time)
