extends Control
class_name SaveItemToGalleryMenu

signal item_saved
signal closed

var image:Image
var item

func setup(img:Image, item):
	self.image = img
	self.item = item
	find_child("TextureRect").texture = ImageTexture.create_from_image(img)
	get_tree().paused = true


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()

func _on_cancel_pressed():
	get_tree().paused = false
	queue_free()
	closed.emit()

func _on_save_pressed():
	GalleryMgr.save_to_gallery(image, item, report_error)
	item.queue_free()
	find_child("SaveButton").visible = false
	find_child("CancelButton").text = "Ok"
	find_child("Label").text = "This item has been moved\nto your gallery"
	item_saved.emit()
	closed.emit()
	
func report_error(err):
	push_error(err)
	find_child("TextureRect").visible = false
	find_child("Label").text = err
