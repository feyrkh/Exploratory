extends Node
class_name ImageMerger

class ImageMergeInfo:
	var img:Image
	var position:Vector2
	var modulate:Color

static func merge_images(image_merge_info:Array, noise:FastNoiseLite=null, noise_cutoff:float=1.0) -> Texture2D: # Array[ImageMergeInfo] as input
	var base_img:Image
	for merge_info in image_merge_info:
		if base_img == null:
			base_img = merge_info.img
			modulate_image(base_img, merge_info.modulate, null, 0)
		else:
			var overlay_img = merge_info.img
			modulate_image(overlay_img, merge_info.modulate, noise, noise_cutoff)
			base_img.blend_rect(overlay_img, overlay_img.get_used_rect(), merge_info.position)
	return ImageTexture.create_from_image(base_img)

static func modulate_image(img:Image, color:Color, noise:FastNoiseLite, noise_cutoff:float):
	for y in img.get_height():
		for x in img.get_width():
			var c:Color = img.get_pixel(x, y)
			if c.a > 0:
				if noise != null:
					var n = (0.5 + noise.get_noise_2d(x/5.0, y/5.0))
					if n < noise_cutoff:
						c.a = c.a * n
				img.set_pixel(x, y, c * color)
