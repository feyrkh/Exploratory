extends Node2D
class_name DigGridTileUI

const WIDTH = 40
const HEIGHT = 40
const X_OFFSET = -10
const DEPTH_MULTIPLIER = 2
const PT_0 = Vector2.ZERO
const PT_1 = Vector2(WIDTH, 0)
const PT_2 = Vector2(WIDTH + X_OFFSET, HEIGHT)
const PT_3 = Vector2(X_OFFSET, HEIGHT)
static var PTS = PackedVector2Array([PT_0, PT_1, PT_2, PT_3])
static var EMPTY_LAYER := SoilComponent.new(0, 0, 0, 1.0, 0, 0, Color.DIM_GRAY, Color.BLACK, Color.BLACK)

@onready var TopPolygon:Polygon2D = find_child("TopPolygon")
@onready var NorthLayers:Node2D = find_child("NorthLayers")
@onready var WestLayers:Node2D = find_child("WestLayers")
@onready var SouthLayers:Node2D = find_child("SouthLayers")
@onready var EastLayers:Node2D = find_child("EastLayers")
@onready var TopOutline:Line2D = find_child("TopOutline")
@onready var MouseArea:Area2D = find_child("MouseArea")
@onready var MouseAreaShape:CollisionPolygon2D = find_child("MouseAreaShape")

var draw_south:bool = false
var draw_east:bool = false
var dig_grid_tile:DigGridTile
var dig_grid_tile_north:DigGridTile
var dig_grid_tile_west:DigGridTile
var dig_grid_tile_south:DigGridTile
var dig_grid_tile_east:DigGridTile
var deepest_south_dig:float
var deepest_east_dig:float

func _ready() -> void:
	var top_layer_query:SoilQueryResult = dig_grid_tile.layers.get_soil_at_depth(dig_grid_tile.depth_dug)
	var top_layer_depth_left = top_layer_query.remaining_depth_in_layer
	TopPolygon.color = top_layer_query.soil.soil_color
	TopPolygon.position.y = dig_grid_tile.depth_dug * DEPTH_MULTIPLIER
	TopPolygon.polygon = PTS
	TopOutline.position = TopPolygon.position
	TopOutline.points = TopPolygon.polygon
	MouseAreaShape.position = TopPolygon.position
	MouseAreaShape.polygon = TopPolygon.polygon
	render_layers(dig_grid_tile_north, NorthLayers, top_layer_query, get_polygon_north)
	render_layers(dig_grid_tile_west, WestLayers, top_layer_query, get_polygon_west)
	MouseArea.mouse_entered.connect(on_mouse_enter)
	MouseArea.mouse_exited.connect(on_mouse_exit)
	if draw_south: render_self_layers(SouthLayers, top_layer_query, get_polygon_south, deepest_south_dig)
	if draw_east: render_self_layers(EastLayers, top_layer_query, get_polygon_east, deepest_east_dig)
	

func on_mouse_enter() -> void:
	print("Entered")
	modulate = Color(0.8, 0.8, 0.8, 1.0)

func on_mouse_exit() -> void:
	print("Exited")
	modulate = Color.WHITE

func render_self_layers(layers_container:Node2D, start_layer_query:SoilQueryResult, get_polygon:Callable, deepest_dig:float) -> void:
	if dig_grid_tile.depth_dug >= dig_grid_tile.deepest_surrounding_depth_dug:
		# This tile is deeper than all surrounding tiles, so no need to draw any layers
		return
	for child in layers_container.get_children():
		child.queue_free()
	var start_layer_idx = start_layer_query.layer_idx
	var end_layer_query = dig_grid_tile.layers.get_soil_at_depth(dig_grid_tile.deepest_surrounding_depth_dug)
	var cur_top := dig_grid_tile.depth_dug
	var first_bottom = start_layer_query.remaining_depth_in_layer + cur_top
	for cur_layer_idx in range(start_layer_idx, end_layer_query.layer_idx+1):
		var cur_layer := dig_grid_tile.layers.get_layer(cur_layer_idx)
		var cur_bottom := minf(cur_top + cur_layer.depth, dig_grid_tile.deepest_surrounding_depth_dug)
		if first_bottom != null:
			cur_bottom = first_bottom
			first_bottom = null
		draw_layer_section(cur_top, cur_bottom, cur_layer, layers_container, get_polygon)
		cur_top = cur_bottom
	if cur_top < deepest_dig:
		draw_layer_section(cur_top, deepest_dig, EMPTY_LAYER, layers_container, get_polygon)
		

func render_layers(neighbor:DigGridTile, layers_container:Node2D, start_layer_query:SoilQueryResult, get_polygon:Callable) -> void:
	if neighbor.depth_dug >= dig_grid_tile.depth_dug:
		# We are >= in elevation compared to our neighbor, just skip
		return
	for child in layers_container.get_children():
		child.queue_free()
	var start_layer_idx = start_layer_query.layer_idx
	var end_layer_query := neighbor.layers.get_soil_at_depth(neighbor.depth_dug)
	var cur_top := neighbor.depth_dug
	for cur_layer_idx in range(end_layer_query.layer_idx, start_layer_idx+1):
		var cur_layer := neighbor.layers.get_layer(cur_layer_idx)
		var cur_bottom := minf(cur_top + cur_layer.depth, dig_grid_tile.depth_dug)
		draw_layer_section(cur_top, cur_bottom, cur_layer, layers_container, get_polygon)
		cur_top = cur_bottom

func draw_layer_section(cur_top:float, cur_bottom:float, cur_layer:SoilComponent, layers_container:Node2D, get_polygon:Callable) -> void:
		var layer_rect := Polygon2D.new()
		var layer_outline:Line2D = preload("res://dig_site/TopOutline.tscn").instantiate()
		layers_container.add_child(layer_rect)
		layers_container.add_child(layer_outline)
		layer_rect.position = Vector2(0, cur_top * DigGridTileUI.DEPTH_MULTIPLIER)
		layer_rect.polygon = get_polygon.call(cur_bottom, cur_top)
		layer_outline.position = layer_rect.position
		layer_outline.points = layer_rect.polygon
		layer_rect.color = cur_layer.soil_color
		cur_top = cur_bottom

func get_polygon_north(cur_bottom:float, cur_top:float) -> PackedVector2Array:
	return [
			Vector2.ZERO, 
			Vector2(DigGridTileUI.WIDTH, 0), 
			Vector2(DigGridTileUI.WIDTH, (cur_bottom-cur_top) * DigGridTileUI.DEPTH_MULTIPLIER), 
			Vector2(0, (cur_bottom-cur_top) * DigGridTileUI.DEPTH_MULTIPLIER)
		]

func get_polygon_south(cur_bottom:float, cur_top:float) -> PackedVector2Array:
	return [
			Vector2(DigGridTileUI.X_OFFSET, DigGridTileUI.HEIGHT), 
			Vector2(DigGridTileUI.WIDTH + DigGridTileUI.X_OFFSET, DigGridTileUI.HEIGHT), 
			Vector2(DigGridTileUI.WIDTH + DigGridTileUI.X_OFFSET, (cur_bottom-cur_top) * DigGridTileUI.DEPTH_MULTIPLIER + DigGridTileUI.HEIGHT), 
			Vector2(DigGridTileUI.X_OFFSET, (cur_bottom-cur_top) * DigGridTileUI.DEPTH_MULTIPLIER + DigGridTileUI.HEIGHT)
		]

func get_polygon_west(cur_bottom:float, cur_top:float) -> PackedVector2Array:
	return [
			Vector2.ZERO, 
			Vector2(0, (cur_bottom-cur_top) * DigGridTileUI.DEPTH_MULTIPLIER), 
			Vector2(DigGridTileUI.X_OFFSET, ((cur_bottom-cur_top)  * DigGridTileUI.DEPTH_MULTIPLIER) + DigGridTileUI.HEIGHT), 
			Vector2(DigGridTileUI.X_OFFSET, (DigGridTileUI.HEIGHT))
		]
		
func get_polygon_east(cur_bottom:float, cur_top:float) -> PackedVector2Array:
	return [
			Vector2(DigGridTileUI.WIDTH, 0), 
			Vector2(DigGridTileUI.WIDTH, (cur_bottom-cur_top) * DigGridTileUI.DEPTH_MULTIPLIER), 
			Vector2(DigGridTileUI.X_OFFSET + DigGridTileUI.WIDTH, ((cur_bottom-cur_top)  * DigGridTileUI.DEPTH_MULTIPLIER) + DigGridTileUI.HEIGHT), 
			Vector2(DigGridTileUI.X_OFFSET + DigGridTileUI.WIDTH, (DigGridTileUI.HEIGHT))
		]
