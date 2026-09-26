@tool
class_name ClownGiftRNG
extends RNG

static var new_gifts=[CoOp.SPELLS.GIFT_COOP]

func shuffle(array: Array) -> void:
	array.append_array(new_gifts)
	super(array)
