class_name CoopNotifications
extends Control

const max_notifications=1
var notifiction_scene:PackedScene=load("res://mods/co-op/source/ui/menu/coop_notifiction.tscn")
var notifications:Array[Control]=[]

@rpc("any_peer")
func add_notification(spell_id:String,description_context:={}):
	#AudioManager.play_sound(Sounds.UI.ACHIEVEMENT_POPUP)
	@warning_ignore("shadowed_variable_base_class")
	var notification:Control=notifiction_scene.instantiate()
	add_child(notification)
	notification.set_spell(spell_id,description_context)
	notification.set_peer_id(multiplayer.get_remote_sender_id())
	#notification.description.text=StringManager
	notification.appear()
	
	# remove last notifiction
	if notifications.size()>=max_notifications:
		var notifiction_to_remove=notifications.pop_back()
		notifiction_to_remove.disappear()
	
	#move other notifictions down
	for existing_notification in notifications:
		var tween=existing_notification.create_tween()
		tween.tween_property(existing_notification,"postion",position+Vector2(0,notification.size.y+4),.5)
	
	notifications.push_front(notification)

func clear_notifications():
	notifications.reverse()
	@warning_ignore("shadowed_variable_base_class")
	for notification in notifications:
		notification.disappear()
		await Game.timeout(.1)
	notifications.clear()
