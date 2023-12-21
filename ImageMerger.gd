extends Node

class ImageMergeInfo:
	var img:Image
	var position:Vector2
	var modulate:Color

static func merge_images(image_merge_info:Array[ImageMergeInfo]) -> Texture2D:
	var base_img:Image
	for merge_info in image_merge_info:
		if base_img == null:
			base_img = merge_info.img
			modulate_image(base_img, merge_info.modulate)
		else:
			var overlay_img = merge_info.img
			modulate_image(overlay_img, merge_info.modulate)
			base_img.blend_rect(overlay_img, overlay_img.get_used_rect(), merge_info.position)
	return ImageTexture.create_from_image(base_img)

static func modulate_image(img:Image, color:Color):
	for y in img.get_height():
		for x in img.get_width():
			img.set_pixel(x, y, img.get_pixel(x, y) * color)
