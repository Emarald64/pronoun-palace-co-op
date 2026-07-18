class_name CustomIntent extends "res://source/ui/intents/intent.gd"

static var custom_intent_icons:Dictionary[String,Texture2D]={}
static var custom_status_intent_icons:Dictionary[String,Texture2D]={}

func get_key() -> String:
	if intent is String:
		return intent
	else:
		return super.get_key()

func update_sprite():
	if intent is String:
		if intent in custom_intent_icons:
			sprite.vframes=1
			sprite.hframes=1
			sprite.texture=custom_intent_icons[intent]
	else:
		super.update_sprite()
	if "name_override" in context and context.name_override in SpecialIntentFrame:
		sprite.frame = SpecialIntentFrame[context.name_override]
	
	elif intent in IntentFrame:
		sprite.frame = IntentFrame[intent]
	elif intent in WORD_CATEGORY_INTENTS:
		sprite.frame = CategoryFrames[context.word_category]
	elif intent in CONTEXT_STATUS_INTENTS:
		for status in get_statuses():
			if status is String and status in custom_status_intent_icons:
				sprite.vframes=1
				sprite.hframes=1
				sprite.texture=custom_status_intent_icons[status]
				break
			elif status in StatusIntentFrame:
				sprite.frame = StatusIntentFrame[status]
				break

func matches(other_intent, other_context):
	if typeof(other_intent)!=typeof(intent):
		return false
	return super(other_intent,other_context)
