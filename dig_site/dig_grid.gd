extends Node2D

var layers:SoilInfo
var width:int
var height:int
var grid:Array # Array[Array[DigGridTile]]
var grid_ui:Array # Array[Array[DigGridTileUI]]

func setup(width:int, height:int, layers:SoilInfo) -> void:
	self.layers = layers
	self.width = width
	self.height = height
	var extra_row = []
	var border_tile = DigGridTile.new(layers, randf_range(0, 0))
	self.grid = [extra_row]
	var deepest_dig := 0
	for x in width+2:
		extra_row.append(border_tile)
	for y in height:
		var row = []
		self.grid.append(row)
		row.append(border_tile)
		for x in width:
			var tile_data := DigGridTile.new(layers, randf_range(0, 70))
			if tile_data.depth_dug > deepest_dig:
				deepest_dig = tile_data.depth_dug
			row.append(tile_data)
		row.append(border_tile)
	self.grid.append(extra_row)
	
	self.grid_ui = []
	for y in range(0, height+1):
		var row = []
		self.grid_ui.append(row)
		for x in range(0, width+1):
			var tile_data:DigGridTile = grid[y][x]
			var deepest_surrounding_depth_dug = max(
				0 if y <= 0 else grid[y-1][x].depth_dug,
				0 if y >= height+1 else grid[y+1][x].depth_dug,
				0 if x <= 0 else grid[y][x-1].depth_dug,
				0 if x >= width+1 else grid[y][x+1].depth_dug
			)
			tile_data.deepest_surrounding_depth_dug = deepest_surrounding_depth_dug
			var tile_ui := preload("res://dig_site/DigGridTileUI.tscn").instantiate()
			tile_ui.dig_grid_tile_north = grid[y-1][x] if y > 0 else border_tile
			tile_ui.dig_grid_tile_west = grid[y][x-1] if x > 0 else border_tile
			tile_ui.dig_grid_tile_east = grid[y][x+1] if x < width else border_tile
			tile_ui.dig_grid_tile_south = grid[y+1][x] if y < height else border_tile
			tile_ui.dig_grid_tile = tile_data
			tile_ui.deepest_south_dig = deepest_dig
			tile_ui.deepest_east_dig = deepest_dig
			if x == width: tile_ui.draw_east = true
			if y == height: tile_ui.draw_south = true
			row.append(tile_ui)
			add_child(tile_ui)
			tile_ui.position = Vector2(x*DigGridTileUI.WIDTH + y*DigGridTileUI.X_OFFSET, y * DigGridTileUI.HEIGHT)

func _ready() -> void:
	var si := SoilInfo.new()
	si.soil_layers = SoilInfo.erode_soil_layers([
		SoilComponent.new(10, 0, 10, 1, 0, 0, Color(1.0, 0, 0, 1), Color.BLUE, Color.GREEN),
		SoilComponent.new(10, 10, 20, 0, 1, 0, Color.RED, Color.BLUE, Color.GREEN),
		SoilComponent.new(10, 20, 30, 0, 0, 1, Color.RED, Color.BLUE, Color.GREEN),
		SoilComponent.new(10, 30, 40, 1, 1, 0, Color.RED, Color.BLUE, Color.GREEN),
		SoilComponent.new(10, 40, 50, 1, 0, 1, Color.RED, Color.BLUE, Color.GREEN),
		SoilComponent.new(10, 50, 60, 0, 1, 1, Color.RED, Color.BLUE, Color.GREEN),
		SoilComponent.new(10, 60, 70, 1, 1, 1, Color.RED, Color.BLUE, Color.GREEN),
	],
	[])
	#[ErosionInfo.new(6, 7)])
	#[ErosionInfo.new(0, 15), ErosionInfo.new(19, 39), ErosionInfo.new(52, 56)])
	#print("5 :", si.get_soil_at_depth(5))
	#print("15:", si.get_soil_at_depth(15, erosion))
	#print("25:", si.get_soil_at_depth(25, erosion))
	#print("35:", si.get_soil_at_depth(35, erosion))
	#print("45:", si.get_soil_at_depth(45, erosion))
	#print("55:", si.get_soil_at_depth(55, erosion))
	#print("65:", si.get_soil_at_depth(65, erosion))
	#print("75:", si.get_soil_at_depth(75, erosion))
	si.print_layers()
	setup(2, 2, si)
