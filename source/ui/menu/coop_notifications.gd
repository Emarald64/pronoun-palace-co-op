class_name CoopNotifications
extends Control

const max_notifications=1
var notifiction_scene:PackedScene=load("res://mods/co-op/source/ui/menu/coop_notifiction.tscn")
var notifications:Array[Control]=[]
var notification_queue:Array[Control]=[]
@onready var cooldown:Timer=$NotifictionCooldown

@rpc("any_peer")
func add_notification(spell_id:String,description_context:={}):
	@warning_ignore("shadowed_variable_base_class")
	var notification:Control=notifiction_scene.instantiate()
	#add_child(notification)
	notification.set_spell(spell_id,description_context)
	notification.set_peer_id(multiplayer.get_remote_sender_id())
	notification_queue.push_back(notification)
	if cooldown.is_stopped():
		cooldown.start()
		display_next_notifiction()
	elif cooldown.time_left>5:
		cooldown.start(5)

func display_next_notifiction():
	if notification_queue.is_empty():
		cooldown.stop()
		notifications.pop_back().disappear()
		return
	var bell_sound=Sounds.UI.ACHIEVEMENT_POPUP.duplicate()
	bell_sound.PLAY_FROM=.58
	AudioManager.play_sound(bell_sound)
	@warning_ignore("shadowed_variable_base_class")
	var notification:Control=notification_queue.pop_front()
	add_child(notification)
	notification.appear()
	
	# remove last notifiction
	if notifications.size()>=max_notifications:
		var notifiction_to_remove=notifications.pop_back()
		notifiction_to_remove.disappear()
	
	#move other notifictions down
	for existing_notification in notifications:
		var tween=existing_notification.create_tween()
		tween.tween_property(existing_notification,"position:y",position.y+notification.size.y+4,.2)
	
	notifications.push_front(notification)
	if notification_queue.is_empty():
		cooldown.start(10)

func clear_notifications():
	notifications.reverse()
	@warning_ignore("shadowed_variable_base_class")
	for notification in notifications:
		notification.disappear()
		await Game.timeout(.1)
	notifications.clear()
	for queued_notification in notification_queue:
		queued_notification.queue_free()
	notification_queue.clear()
