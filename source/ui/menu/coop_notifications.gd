class_name CoopNotifications
extends Control

const max_notifications=1
const queue_notification_cooldown=5
const clear_notification_cooldown=10
var notifiction_scene:PackedScene=load("res://mods/co-op/source/ui/menu/coop_notifiction.tscn")
var notifications:Array[Control]=[]
var notification_queue:Array[Control]=[]
@onready var cooldown:Timer=$NotifictionCooldown

@rpc("any_peer")
func add_spell_notification(spell_id:String,description_context:={}):
	var new_notification:Control=notifiction_scene.instantiate()
	new_notification.set_peer_id(multiplayer.get_remote_sender_id())
	new_notification.set_spell(spell_id,description_context)
	add_notification(new_notification)

#@rpc("any_peer")
func add_notification_direct(description_key:String,player_name:String,description_context:={},icon_texture_path:="res://arte/spells/missing.png",icon_reigon=Rect2(0,0,32,32),player_texture_path:="res://arte/spells/missing.png",player_reigon=Rect2(0,0,32,32)):
	var new_notification:Control=notifiction_scene.instantiate()
	var icon_texture:=AtlasTexture.new()
	if ResourceLoader.exists(icon_texture_path):
		icon_texture.atlas=load(icon_texture_path)
		icon_texture.region=icon_reigon
	else:
		push_error("tried to create a notification with an invalid texture")
		icon_texture.atlas=load("res://arte/spells/missing.png")
		icon_texture.region=Rect2(0,0,32,32)
	new_notification.get_node("%SpellIcon").texture=icon_texture
	
	var player_texture:=AtlasTexture.new()
	if ResourceLoader.exists(player_texture_path):
		player_texture.atlas=load(player_texture_path)
		player_texture.region=player_reigon
	else:
		push_error("tried to create a notification with an invalid texture")
		player_texture.atlas=load("res://arte/spells/missing.png")
		player_texture.region=Rect2(0,0,32,32)
	new_notification.get_node("%PlayerIcon").texture=player_texture
	
	new_notification.get_node("%Description").text=StringManager.get_string(description_key,description_context)
	add_notification(new_notification)

func add_notification(new_notification:CoopNotification):
	notification_queue.push_back(new_notification)
	if cooldown.is_stopped() or cooldown.time_left<=queue_notification_cooldown:
		cooldown.start(clear_notification_cooldown)
		display_next_notifiction()
	else:
		cooldown.start(cooldown.time_left-queue_notification_cooldown)

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
		cooldown.start(clear_notification_cooldown)

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
