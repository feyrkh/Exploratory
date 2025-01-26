extends RefCounted
class_name SoilComponent

var depth:float = 1.0
var age_start:float
var age_end:float
var clay:float # Percent of soil that is clay, range 0.0 to 1.0
var silt:float
var sand:float
var clay_color:Color
var silt_color:Color
var sand_color:Color
var soil_color:Color:
	get:
		return clay_color*clay + silt_color*silt + sand_color*sand

func _init(depth:float, age_start:float, age_end:float, clay:float, silt:float, sand:float, clay_color:=Color.ORANGE, silt_color:=Color.SADDLE_BROWN, sand_color:=Color.SANDY_BROWN):
	var total:float = clay+silt+sand
	self.clay = clay / total
	self.silt = silt / total
	self.sand = sand / total
	self.depth = depth
	self.age_start = age_start
	self.age_end = age_end
	self.clay_color = clay_color
	self.silt_color = silt_color
	self.sand_color = sand_color
	self.soil_color = (clay_color * self.clay) + (silt_color * self.silt) + (sand_color * self.sand)

func clone() -> SoilComponent:
	return SoilComponent.new(depth, age_start, age_end, clay, silt, sand, clay_color, silt_color, sand_color)

static func random(age_start:float, age_end:float) -> SoilComponent:
	var depth = randf_range(1.0, 40.0)
	var clay = randi_range(1, 100)
	var silt = randi_range(1, 100)
	var sand = randi_range(1, 100)
	var sc = SoilComponent.new(depth, age_start, age_end, clay, silt, sand, 
		Color.from_hsv(randf_range(0, 1), randf_range(0, 1), randf_range(0.2, 0.7)),
		Color.from_hsv(randf_range(0, 1), randf_range(0, 1), randf_range(0.2, 0.7)),
		Color.from_hsv(randf_range(0, 1), randf_range(0, 1), randf_range(0.2, 0.7)))
	return sc

func _to_string() -> String:
	return "[d: %.1f, cld: %.2f/%.2f/%.2f, age: %f-%f]" % [depth, clay, silt, sand, age_start, age_end]
