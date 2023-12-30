extends SubViewport
class_name ScreenshotViewport

func take_screenshot(root_camera:Camera2D, pos:Vector2, dim:Vector2, rot:float = 0) -> Image:
	world_2d = root_camera.get_world_2d()
	await RenderingServer.frame_post_draw
	size = dim
	$ScreenshotCamera.global_position = pos
	$ScreenshotCamera.global_rotation = rot
	msaa_2d = root_camera.get_viewport().msaa_2d
	screen_space_aa = root_camera.get_viewport().screen_space_aa
	use_taa = root_camera.get_viewport().use_taa
	canvas_item_default_texture_filter = root_camera.get_viewport().canvas_item_default_texture_filter
	#var prev_paused = root_camera.get_tree().paused
	#root_camera.get_tree().paused = true
	await RenderingServer.frame_post_draw
	#root_camera.get_tree().paused = prev_paused
	return get_texture().get_image()
