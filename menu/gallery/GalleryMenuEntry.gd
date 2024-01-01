extends Container

func setup(item_name):
	var img = Image.load_from_file("user://gallery/"+item_name+".png")
	if img != null:
		var texture := ImageTexture.create_from_image(img)
		$TextureRect.texture = texture
	else:
		push_error("Failed to load thumbnail from file: ", "user://gallery/"+item_name+".png")
