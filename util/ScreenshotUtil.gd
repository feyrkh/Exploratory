extends Node
class_name ScreenshotUtil

static var screenshot_container_scene

static func take_screenshot(root_camera:Node, pos:Vector2, size:Vector2, rotation:float=0) -> Image:
	if screenshot_container_scene == null:
		screenshot_container_scene = load("res://util/ScreenshotViewport.tscn")
	var ssvp:ScreenshotViewport = screenshot_container_scene.instantiate()
	root_camera.get_parent().add_child(ssvp)
	var img := await ssvp.take_screenshot(root_camera, pos, size, rotation)
	ssvp.queue_free()
	return img
