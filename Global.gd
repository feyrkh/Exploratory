extends Node

signal click_mode_changed()
signal camera_zoom_changed(cur_zoom:float)
signal save_to_gallery(item:Node2D)
signal unpack_gallery_item(gallery_item_name:String)

var next_scene_settings
var shatter_width:float = 0.5
var rotate_with_shuffle = false

var lock_rotation = true:
	set(val):
		print("Toggling rotation lock to ", val)
		lock_rotation = val
		rotate_with_shuffle = !val
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

enum ClickMode {move, glue, save_item}
var click_mode = ClickMode.move:
	set(val):
		if val != click_mode:
			click_mode = val
			match click_mode:
				ClickMode.move: Input.set_custom_mouse_cursor(null)
				ClickMode.glue: Input.set_custom_mouse_cursor(load("res://art/cursor/glue.png"), Input.CURSOR_ARROW, Vector2(15, 15))
				#ClickMode.paint: Input.set_custom_mouse_cursor(load("res://art/cursor/glue.png"), Input.CURSOR_ARROW, Vector2(15, 15))
				_: Input.set_custom_mouse_cursor(null)
			click_mode_changed.emit()

func rotate_click_mode():
	match click_mode:
		ClickMode.move: click_mode = ClickMode.glue
		ClickMode.glue: click_mode = ClickMode.move
		#ClickMode.paint: click_mode = ClickMode.move
		_: click_mode = ClickMode.move

func reset_click_mode():
	click_mode = ClickMode.move
