extends Node

signal setting_changed(setting_id:String, old_val, new_val)
signal enable_sound() # be sure to call this when it's ok to start playing sounds

signal click_mode_changed()
signal camera_zoom_changed(cur_zoom:float)
signal delete_archeology_item(item:ArcheologyItem)
signal save_to_gallery(item:Node2D)
signal unpack_gallery_item(gallery_item_name:String)
signal cleanup_all_items()
signal first_click_received()

signal toggle_glue_panel()
signal glue_color_changed()

signal item_highlighted(item)
signal item_unhighlighted(item)
signal started_dragging_item(item)
signal stopped_dragging_item(item)
signal tutorial_moved_item(item)
signal tutorial_rotated_item(item)
signal tutorial_panned_camera()
signal tutorial_glued_item()
signal tutorial_move_option_toggled()

func set_global_setting(setting_name, val):
	if val != global_user_settings.get_config(setting_name, false):
		global_user_settings.set_config(setting_name, val)
		global_user_settings.save_config()

func get_global_setting(setting_name, default_val):
	return global_user_settings.get_config(setting_name, default_val)

var has_completed_relax_tutorial := false:
	get:
		return global_user_settings.get_config("has_completed_relax_tutorial", false)
	set(val):
		set_global_setting("has_completed_relax_tutorial", val)
var has_completed_struggle_tutorial := false:
	get:
		return global_user_settings.get_config("has_completed_struggle_tutorial", false)
	set(val):
		set_global_setting("has_completed_struggle_tutorial", val)
var has_completed_gallery_tutorial := false:
	get:
		return global_user_settings.get_config("has_completed_gallery_tutorial", false)
	set(val):
		set_global_setting("has_completed_gallery_tutorial", val)

var slow_initial_zoom:bool = true:
	get:
		return global_user_settings.get_config("slow_initial_zoom", true)
	set(val):
		set_global_setting("slow_initial_zoom", val)

var splash_screen_shown := false
var next_scene_settings
var shatter_width:float = 0.5
var rotate_with_shuffle = false
var glue_materials:Dictionary = {}
var glue_color:Color = Color("e8c810"):
	set(val):
		glue_color = val
		glue_material = get_glue_material(glue_color)
		glue_color_changed.emit()

var rotation_mode_direct := true
var rotation_pixels_to_radians:float = 0.003

func get_glue_material(c:Color):
		if !glue_materials.has(c):
			var new_mat:ShaderMaterial = glue_material.duplicate()
			new_mat.set_shader_parameter("normal_color", Vector4(c.r, c.g, c.b, c.a))
			glue_materials[c] = new_mat
		return glue_materials.get(c, glue_material)
	
var glue_material:ShaderMaterial = preload("res://shader/ItemShardEdgeLine.tres")

func _ready():
	glue_material = get_glue_material(glue_color)
	process_mode = Node.PROCESS_MODE_ALWAYS
	setting_changed.connect(_on_setting_changed)

func _on_setting_changed(setting, _old_val, new_val):
	match setting:
		"control_hints_visible": control_hints_visible = new_val

func change_scene(scene):
	cleanup_all_items.emit()
	if scene is String:
		get_tree().change_scene_to_file(scene)
	else:
		get_tree().change_scene_to_packed(scene)

var lock_rotation = true:
	set(val):
		#print("Toggling rotation lock to ", val)
		lock_rotation = val
		rotate_with_shuffle = !val
		get_tree().call_group("archeology", "global_lock_rotation", val)
		tutorial_move_option_toggled.emit()

var freeze_pieces = false:
	set(val):
		#print("Toggling piece freezing to ", val)
		freeze_pieces = val
		get_tree().call_group("archeology", "global_freeze_pieces", val)
		tutorial_move_option_toggled.emit()

var collide = true:
	set(val):
		#print("Toggling collide to ", val)
		collide = val
		get_tree().call_group("archeology", "global_collide", val)

enum ClickMode {move, glue, save_item}
var click_mode = ClickMode.move:
	set(val):
		if val != click_mode:
			click_mode = val
			match click_mode:
				ClickMode.move: 
					Input.set_custom_mouse_cursor(null)
				ClickMode.glue: 
					Input.set_custom_mouse_cursor(load("res://art/cursor/glue.png"), Input.CURSOR_ARROW, Vector2(15, 15))
				ClickMode.save_item:
					Input.set_custom_mouse_cursor(null)
				_: Input.set_custom_mouse_cursor(null)
			click_mode_changed.emit()

var game_mode:String
var awaiting_first_click:bool = false
var center_of_mass_indicator_size:float = 5

var global_user_settings := SettingsFile.new("user://global.cfg", {
	"control_hints_visible": true,
})
var control_hints_visible:bool = true:
	get:
		return global_user_settings.get_config("control_hints_visible", true)
	set(val):
		if val != global_user_settings.get_config("control_hints_visible", true):
			control_hints_visible = val
			global_user_settings.set_config("control_hints_visible", val)
			global_user_settings.save_config()

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
		"tut_r": has_completed_relax_tutorial,
		"tut_s": has_completed_struggle_tutorial,
		"tut_g": has_completed_gallery_tutorial,
	}

func load_save_data(data:Dictionary):
	shatter_width = data.get("sw", shatter_width)
	rotate_with_shuffle = data.get("rws", rotate_with_shuffle)
	lock_rotation = data.get("lr", lock_rotation)
	freeze_pieces = data.get("fp", freeze_pieces)
	collide = data.get("c", collide)
	click_mode = data.get("cm", click_mode)
	game_mode = data.get("m", "relax")
	center_of_mass_indicator_size = data.get("coms", center_of_mass_indicator_size)
	has_completed_relax_tutorial = data.get("tut_r", has_completed_relax_tutorial)
	has_completed_struggle_tutorial = data.get("tut_s", has_completed_struggle_tutorial)
	has_completed_gallery_tutorial = data.get("tut_g", has_completed_gallery_tutorial)

func rotate_click_mode():
	match click_mode:
		ClickMode.move: click_mode = ClickMode.glue
		ClickMode.glue: click_mode = ClickMode.move
		#ClickMode.paint: click_mode = ClickMode.move
		_: click_mode = ClickMode.move

func reset_click_mode():
	click_mode = ClickMode.move

func play_button_mouseover_sound(sfx_name:String="default"):
	match sfx_name:
		_: AudioPlayerPool.play_sfx(preload("res://sfx/clink3.mp3"), 1.0, 0.3)

func play_button_click_sound(sfx_name:String="default"):
	match sfx_name:
		"none", "": pass
		"menu_back":  
			AudioPlayerPool.play_sfx(preload("res://sfx/clink3.mp3"), 0.5, 0.8)
		_: 
			AudioPlayerPool.play_sfx(preload("res://sfx/clink3.mp3"), randf_range(0.9, 1.1), 0.8)
