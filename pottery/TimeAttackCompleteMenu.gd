extends Control
class_name TimeAttackCompleteMenu

const IMG_IDX := 0
const ITEM_IDX := 1
const SAVED_IDX := 2

signal item_saved
signal closed

var item_arr:Array
var image:Image
var item
var cur_idx:int = 0

func setup(item_arr:Array): # Array of [Image, ArcheologyItem]
	self.item_arr = Array(item_arr)
	for item in self.item_arr:
		item.append(false) # 3rd field
	get_tree().paused = true
	render_item(0)

func render_item(idx:int):
	var saved = item_arr[idx][SAVED_IDX]
	var header_label = find_child("Label")
	find_child("PrevButton").disabled = idx == 0
	find_child("NextButton").text = "Finished" if (idx+1) >= item_arr.size() else "Next"
	find_child("SaveButton").disabled = saved
	if saved:
		header_label.text = "Artifact saved to gallery"
	else:
		header_label.text = "A completed artifact"
		self.image = item_arr[idx][IMG_IDX]
		self.item = item_arr[idx][ITEM_IDX]
		find_child("TextureRect").texture = ImageTexture.create_from_image(self.image)

#func _unhandled_input(event):
	#if event.is_action_pressed("ui_cancel"):
		#_on_cancel_pressed()
		#get_viewport().set_input_as_handled()
#
#func _on_cancel_pressed():
	#get_tree().paused = false
	#queue_free()
	#closed.emit()

func _on_save_pressed():
	GalleryMgr.save_to_gallery(image, item, report_error)
	item.queue_free()
	item_arr[cur_idx][SAVED_IDX] = true
	render_item(cur_idx)
	#find_child("SaveButton").visible = false
	#find_child("CancelButton").text = "Ok"
	#find_child("Label").text = "This item has been moved\nto your gallery"
	#item_saved.emit()
	#closed.emit()
	
func report_error(err):
	push_error(err)
	find_child("TextureRect").visible = false
	find_child("Label").text = err


func _on_prev_button_pressed():
	cur_idx = max(0, cur_idx - 1)
	render_item(cur_idx)

func _on_next_button_pressed():
	cur_idx = min(item_arr.size(), cur_idx + 1)
	if cur_idx == item_arr.size():
		get_tree().paused = false
		queue_free()
	else:
		render_item(cur_idx)
