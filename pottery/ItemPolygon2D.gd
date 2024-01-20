extends Polygon2D
class_name ItemPolygon2D

#var bbox_poly:Polygon2D
var save_data:Array #[ItemBuilder.ImageSaveData]
func get_save_data(weathering_save_data:Dictionary)->Array:
	return save_data.map(func(image_save_data): 
		return image_save_data.get_save_data(weathering_save_data))

var bounding_box:
	get:
		if bounding_box != null and bounding_box.size != Vector2.ZERO:
			return bounding_box
		if polygon == null:
			return Rect2(0, 0, 0, 0)
		var x1 = polygon[0].x
		var x2 = x1
		var y1 = polygon[0].y
		var y2 = y1
		for i in range(1, polygon.size()):
			var pt = polygon[i]
			if pt.x < x1: x1 = pt.x
			if pt.x > x2: x2 = pt.x
			if pt.y < y1: y1 = pt.y
			if pt.y > y2: y2 = pt.y
		bounding_box = Rect2(x1, y1, x2-x1, y2-y1)
		#bbox_poly.polygon = [Vector2(x1, y1), Vector2(x2, y1), Vector2(x2, y2), Vector2(x1, y2)]
		return bounding_box
var total_edge_length:float:
	get:
		if total_edge_length == null:
			total_edge_length = _calc_total_edge_length()
		return total_edge_length

func _ready():
	pass
	#bbox_poly = Polygon2D.new()
	#bbox_poly.color = Color(1, 1, 1, 0.5)
	#add_child(bbox_poly)
	
func _calc_total_edge_length()->float:
	var result = 0
	for i in range(polygon.size()):
		var j = (i+1) % polygon.size()
		result += polygon[i].distance_to(polygon[j])
	return result
	
	
	
