extends RefCounted
class_name SoilQueryResult

var soil:SoilComponent
var absolute_age:float
var absolute_depth:float
var remaining_depth_in_layer:float
var layer_idx:int

func _init(soil:SoilComponent, absolute_age:float, absolute_depth:float, remaining_depth_in_layer:float, layer_idx:int) -> void:
	self.soil = soil
	self.absolute_age = absolute_age
	self.absolute_depth = absolute_depth
	self.remaining_depth_in_layer = remaining_depth_in_layer
	self.layer_idx = layer_idx
