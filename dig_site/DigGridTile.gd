extends RefCounted
class_name DigGridTile

var depth_dug:float = 0
var deepest_surrounding_depth_dug:float = 0
var layers:SoilInfo

func _init(layers:SoilInfo, depth_dug:float):
	self.layers = layers
	self.depth_dug = depth_dug
