extends Control

signal add_item_button_pressed()
signal movement_button_toggled(new_val:bool)
signal rotate_button_toggled(new_val:bool)
signal shuffle_button_pressed()
signal save_item_button_pressed()

func _ready():
	Global.glue_color_changed.connect(update_buttons)
	visible = false
	await get_tree().process_frame
	visible = true
	if Global.game_mode == "time":
		$AddItemButton.visible = false
		$AddItemLabel.visible = false
		$MovementButton.visible = false
		$MovementLabel.visible = false
		$RotateButton.visible = false
		$RotateLabel.visible = false
		$SaveItemButton.visible = false
		$SaveItemLabel.visible = false
	update_buttons()

func update_buttons():
	if Global.freeze_pieces:
		find_child("MovementButton").button_pressed = true
	else:
		find_child("MovementButton").button_pressed = false
	#if Global.collide:
		#find_child("CollideButton").text = "Collide: Yes"
	#else:
		#find_child("CollideButton").text = "Collide: No"
	if Global.lock_rotation:
		find_child("RotateButton").button_pressed = true
	else:
		find_child("RotateButton").button_pressed = false
	#match Global.click_mode:
		#Global.ClickMode.move: find_child("ClickModeButton").text = "Click: Move"
		#Global.ClickMode.glue: find_child("ClickModeButton").text = "Click: Glue"
		#Global.ClickMode.save_item: find_child("ClickModeButton").text = "Click: Gallery"
		##Global.ClickMode.paint: find_child("ClickModeButton").text = "Click: Paint"
		#_: find_child("ClickModeButton").text = "Click: Unknown?"
	find_child("GlueOverlay").modulate = Global.glue_color

func _on_add_item_button_pressed():
	add_item_button_pressed.emit()

func _on_movement_button_toggled(toggled_on):
	movement_button_toggled.emit(toggled_on)

func _on_rotate_button_toggled(toggled_on):
	rotate_button_toggled.emit(toggled_on)

func _on_shuffle_button_pressed():
	shuffle_button_pressed.emit()

func _on_save_item_button_pressed():
	save_item_button_pressed.emit()

func _on_game_timer_time_attack_complete(_total_seconds):
	$SaveItemButton.visible = true
	$SaveItemLabel.visible = true
	$BackgroundGlow.update_position()

func _on_glue_button_pressed():
	Global.toggle_glue_panel.emit()
	
