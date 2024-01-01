extends Control
class_name SaveItemToGalleryMenu

var image:Image
var item

func setup(img:Image, item):
	self.image = img
	self.item = item
	find_child("TextureRect").texture = ImageTexture.create_from_image(img)


func _on_cancel_pressed():
	queue_free()

func _on_save_pressed():
	GalleryMgr.save_to_gallery(image, item, report_error)
	item.queue_free()
	find_child("SaveButton").visible = false
	find_child("CancelButton").text = "Ok"
	find_child("Label").text = "This item has been moved\nto your gallery"
	
func report_error(err):
	push_error(err)
	find_child("TextureRect").visible = false
	find_child("Label").text = err
