extends SpellSprite

@export var coop_curse_material:ShaderMaterial

func update_material():
	if spell.curse in CoOp.CURSES.values():
		sprite.material=coop_curse_material
	else:
		super()
