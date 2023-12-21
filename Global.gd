extends Node

var lock_rotation = false:
	set(val):
		print("Toggling rotation lock to ", val)
		lock_rotation = val
		get_tree().call_group("archeology", "global_lock_rotation", val)

var freeze_pieces = false:
	set(val):
		print("Toggling piece freezing to ", val)
		freeze_pieces = val
		get_tree().call_group("archeology", "global_freeze_pieces", val)

var collide = true:
	set(val):
		print("Toggling collide to ", val)
		collide = val
		get_tree().call_group("archeology", "global_collide", val)
