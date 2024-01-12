extends Node

signal click_mode_changed()
signal camera_zoom_changed(cur_zoom:float)
signal delete_archeology_item(item:ArcheologyItem)
signal save_to_gallery(item:Node2D)
signal unpack_gallery_item(gallery_item_name:String)
signal cleanup_all_items()
signal first_click_received()

signal toggle_glue_panel()
signal glue_color_changed()

var next_scene_settings
var shatter_width:float = 0.5
var rotate_with_shuffle = false
var glue_materials:Dictionary = {}
var glue_material:ShaderMaterial = preload("res://shader/ItemShardEdgeLine.tres")
var glue_color:Color = Color.GOLD:
	set(val):
		glue_color = val
		glue_material = get_glue_material(glue_color)
		glue_color_changed.emit()

func get_glue_material(glue_color:Color):
		if !glue_materials.has(glue_color):
			var new_mat:ShaderMaterial = glue_material.duplicate()
			new_mat.set_shader_parameter("normal_color", Vector4(glue_color.r, glue_color.g, glue_color.b, glue_color.a))
			glue_materials[glue_color] = new_mat
		return glue_materials.get(glue_color, glue_material)
	

func change_scene(scene):
	cleanup_all_items.emit()
	if scene is String:
		get_tree().change_scene_to_file(scene)
	else:
		get_tree().change_scene_to_packed(scene)

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

var game_mode:String
var awaiting_first_click:bool = false
var center_of_mass_indicator_size:float = 5

func get_save_data() -> Dictionary:
	return {
		"sw":shatter_width,
		"rws":rotate_with_shuffle,
		"lr":lock_rotation,
		"fp":freeze_pieces,
		"c": collide,
		"cm": click_mode,
		"m": game_mode,
		"coms": center_of_mass_indicator_size,
	}

func load_save_data(data:Dictionary):
	shatter_width = data.get("sw", shatter_width)
	rotate_with_shuffle = data.get("rws", rotate_with_shuffle)
	lock_rotation = data.get("lr", lock_rotation)
	freeze_pieces = data.get("fp", freeze_pieces)
	collide = data.get("c", collide)
	click_mode = data.get("cm", click_mode)
	game_mode = data.get("m")
	center_of_mass_indicator_size = data.get("coms")

func rotate_click_mode():
	match click_mode:
		ClickMode.move: click_mode = ClickMode.glue
		ClickMode.glue: click_mode = ClickMode.move
		#ClickMode.paint: click_mode = ClickMode.move
		_: click_mode = ClickMode.move

func reset_click_mode():
	click_mode = ClickMode.move
