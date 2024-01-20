extends Node
class_name ImageMerger

class ImageMergeInfo:
	var img:Image
	var position:Vector2
	var modulate:Color
	var repeat_x:int = 1
	var repeat_y:int = 1

static func merge_images(image_merge_info:Array, weathering:WeatheringConfig=null, tree:SceneTree=null) -> Texture2D: # Array[ImageMergeInfo] as input
	var base_img:Image
	var noise:FastNoiseLite
	var noise_cutoff := 1.0
	var noise_floor := 0.0
	if weathering:
		noise = weathering.noise
		noise_cutoff = weathering.noise_cutoff
		noise_floor = weathering.noise_floor
	for merge_info in image_merge_info:
		if base_img == null:
			base_img = merge_info.img
			await modulate_image(base_img, merge_info.modulate, null, 0, tree)
		elif merge_info.repeat_y > 1 or merge_info.repeat_y > 0:
			var unmodified_img = merge_info.img
			for y_block in merge_info.repeat_y:
				for x_block in merge_info.repeat_x:
					var cur_pos = merge_info.position + Vector2(x_block * merge_info.img.get_size().x, y_block * merge_info.img.get_size().y)
					var overlay_img = Image.new()
					overlay_img.copy_from(unmodified_img)
					await modulate_image(overlay_img, merge_info.modulate, noise, noise_cutoff, tree, cur_pos, noise_floor)
					base_img.blend_rect(overlay_img, overlay_img.get_used_rect(), cur_pos)
		else:
			var overlay_img = merge_info.img
			await modulate_image(overlay_img, merge_info.modulate, noise, noise_cutoff, tree, merge_info.position, noise_floor)
			base_img.blend_rect(overlay_img, overlay_img.get_used_rect(), merge_info.position)

		if tree:
			await(tree.process_frame)
	if !base_img.has_mipmaps():
		base_img.generate_mipmaps()
	return ImageTexture.create_from_image(base_img)

static func modulate_image(img:Image, color:Color, noise:FastNoiseLite, noise_cutoff:float, tree:SceneTree=null, noise_offset:Vector2=Vector2.ZERO, noise_floor:float=0.0):
	for y in img.get_height():
		if tree and randf() < 0.3:
			await(tree.process_frame)
		for x in img.get_width():
			var c:Color = img.get_pixel(x, y)
			if c.a > 0:
				if noise != null:
					var n = (noise.get_noise_2d((noise_offset.x+x), (noise_offset.y+y)) + 1)/2.0
					if noise_floor < 0:
						n = (n - noise_floor) / (1.0 - noise_floor)
					if noise_floor > 0:
						if n <= noise_floor:
							n = 0
						else:
							n = (n - noise_floor) / (1.0 - noise_floor)
					if n < noise_floor:
						pass
					if n <= 0:
						n = 0.01
					if n < noise_cutoff or noise_cutoff >= 1.0:
						c.a = c.a * n
				img.set_pixel(x, y, c * color)
