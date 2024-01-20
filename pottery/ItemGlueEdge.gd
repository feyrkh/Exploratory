extends Node2D
class_name ItemGlueEdge

@onready var polygon2d:Polygon2D = $Polygon2D
var glue_color:Color

var polygon:
	get:
		return polygon2d.polygon
	set(val):
		polygon2d.polygon = val

var area:
	get:
		return MyGeom.calculate_area(polygon)

func get_save_data():
	return [polygon, glue_color]

static func load_save_data(save_data) -> ItemGlueEdge:
	var result:ItemGlueEdge = preload("res://pottery/ItemGlueEdge.tscn").instantiate()
	var glue_material:ShaderMaterial = Global.get_glue_material(save_data[1])
	result.setup(save_data[0], glue_material)
	return result
	
func setup(poly, shine_material:ShaderMaterial):
	$Polygon2D.polygon = poly
	$Polygon2D.material = shine_material
	var cv4:Vector4 = shine_material.get_shader_parameter("normal_color")
	glue_color = Color(cv4.x, cv4.y, cv4.z, cv4.w)

func clone(new_polygon) -> ItemGlueEdge:
	var result:ItemGlueEdge = preload("res://pottery/ItemGlueEdge.tscn").instantiate()
	result.glue_color = glue_color
	result.find_child("Polygon2D").color = Color.WHITE
	result.find_child("Polygon2D").material = $Polygon2D.material
	result.find_child("Polygon2D").polygon = new_polygon
	return result

func adjust_scale(scale_change:float):
	var child = polygon2d
	for i in range(child.polygon.size()):
		child.polygon[i] = child.polygon[i] * scale_change
