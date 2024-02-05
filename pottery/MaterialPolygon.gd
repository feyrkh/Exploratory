extends Polygon2D
class_name MaterialPolygon

const MATERIAL := "m"
const POLYGON := "p"

enum MaterialType {clay, metal}

const CLAY_COLOR := Color("743123")
const METAL_COLOR := Color.WHITE #Color("656565")

@export var material_type:MaterialType = MaterialType.metal

func get_data()->Dictionary:
	return {MATERIAL:material_type, POLYGON:polygon}

static func material_to_color(material_id:MaterialPolygon.MaterialType) -> Color:
	match material_id:
		MaterialPolygon.MaterialType.metal: return MaterialPolygon.METAL_COLOR
		_: return CLAY_COLOR

static func color_to_material(color:Color) -> MaterialPolygon.MaterialType:
	if color.is_equal_approx(METAL_COLOR):
		return MaterialType.metal
	return MaterialType.clay

static func material_to_image(material_id:MaterialPolygon.MaterialType) -> String:
	match material_id:
		MaterialPolygon.MaterialType.metal: return "res://art/broken_metal.png"
		_: return "res://art/broken_clay.png"
