@tool
class_name ClownGiftRNG
extends RNG

static var new_gifts=["co-op:gift_coop"]

func shuffle(array: Array) -> void:
	array.append_array(new_gifts)
	super(array)
