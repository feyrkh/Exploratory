extends Control

var cur_page:int = 0
var items_per_page:int = 1
var available_items := []

func setup(items:Array):
	cur_page = 0
	available_items = items
	draw_page()

func draw_page():
	for entry in find_child("Entries").get_children():
		entry.queue_free()
	for i in range(cur_page * items_per_page, min(available_items.size(), (cur_page+1) * items_per_page)):
		add_entry(available_items[i])

func add_entry(item_name):
	var entry = preload("res://menu/gallery/GalleryMenuEntry.tscn").instantiate()
	entry.setup(item_name)
	find_child("Entries").add_child(entry)

func _on_previous_button_pressed():
	cur_page -= 1
	if cur_page < 0:
		cur_page = available_items.size()-1
	draw_page()

func _on_unpack_button_pressed():
	Global.unpack_gallery_item.emit(available_items[cur_page]) # NOTE: assumes 1 item per page
	visible = false

func _on_next_button_pressed():
	cur_page = (cur_page + 1) % available_items.size()
	draw_page()
