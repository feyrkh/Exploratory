extends Control

signal add_item_button_pressed()
signal movement_button_toggled(new_val:bool)
signal rotate_button_toggled(new_val:bool)
signal shuffle_button_pressed()
signal save_item_button_pressed()

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
