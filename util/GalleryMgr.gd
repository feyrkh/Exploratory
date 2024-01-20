extends Node
class_name GalleryMgr

static func save_to_gallery(image, item, report_error:Callable):
	DirAccess.make_dir_absolute("user://gallery")
	var filename = "user://gallery/"+str(Time.get_unix_time_from_system())
	var err:Error = image.save_png(filename+".png")
	if err == OK:
		print("Saved image to ", filename+".png")
		var image_save_data = {}
		var weathering_save_data = {}
		var item_save_data = item.get_save_data(image_save_data, weathering_save_data)
		var reversed_image_save_data = {}
		var save_file := FileAccess.open_compressed(filename+".dat", FileAccess.WRITE)
		if save_file == null:
			report_error.call("Failed to open image save file "+filename+".dat, error="+str(FileAccess.get_open_error()))
			return
		for k in image_save_data.keys():
			reversed_image_save_data[image_save_data[k]] = k
		for k in weathering_save_data.keys():
			weathering_save_data[weathering_save_data[k]] = k.get_save_data()
		save_file.store_var((reversed_image_save_data))
		save_file.store_var((weathering_save_data))
		save_file.store_var((item_save_data))
		save_file.close()
	else:
		report_error.call("Failed to save image to "+filename+".png, error="+str(err))

static func unpack_from_gallery(item_name:String, report_error:Callable, texture_cache:Dictionary = {}) -> ArcheologyItem:
	var save_file := FileAccess.open_compressed("user://gallery/"+item_name+".dat", FileAccess.READ)
	if save_file == null:
		report_error.call("Failed to unpack item ", "user://gallery/"+item_name+".dat", "; error=", FileAccess.get_open_error())
		return null
	var reversed_image_save_data = save_file.get_var()
	var reversed_weathering_save_data = save_file.get_var()
	var item_save_data = save_file.get_var()
	save_file.close()
	var result = await ArcheologyItem.load_save_data(item_save_data, reversed_image_save_data, reversed_weathering_save_data, texture_cache)
	result.gallery_id = item_name
	return result
