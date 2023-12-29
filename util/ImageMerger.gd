extends Node
class_name ImageMerger

class ImageMergeInfo:
	var img:Image
	var position:Vector2
	var modulate:Color

static func merge_images(image_merge_info:Array, noise:FastNoiseLite=null, noise_cutoff:float=1.0, tree:SceneTree=null) -> Texture2D: # Array[ImageMergeInfo] as input
	var base_img:Image
	for merge_info in image_merge_info:
		if base_img == null:
			base_img = merge_info.img
			await modulate_image(base_img, merge_info.modulate, null, 0, tree)
		else:
			var overlay_img = merge_info.img
			await modulate_image(overlay_img, merge_info.modulate, noise, noise_cutoff, tree, merge_info.position)
			base_img.blend_rect(overlay_img, overlay_img.get_used_rect(), merge_info.position)
		if tree:
			await(tree.process_frame)
	return ImageTexture.create_from_image(base_img)

static func modulate_image(img:Image, color:Color, noise:FastNoiseLite, noise_cutoff:float, tree:SceneTree=null, noise_offset:Vector2=Vector2.ZERO):
	for y in img.get_height():
		if tree and randf() < 0.3:
			await(tree.process_frame)
		for x in img.get_width():
			var c:Color = img.get_pixel(x, y)
			if c.a > 0:
				if noise != null:
					var n = (0.5 + noise.get_noise_2d((noise_offset.x+x)/5.0, (noise_offset.y+y)/5.0))
					if n < noise_cutoff:
						c.a = c.a * n
				img.set_pixel(x, y, c * color)
