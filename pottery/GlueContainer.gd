extends Node2D

enum GlueMode {merging, clipping, quick_merging, cleaning}

const processing_modes:Array[GlueMode] = [GlueMode.quick_merging, GlueMode.clipping, GlueMode.cleaning, GlueMode.merging, GlueMode.clipping]

var child1_idx:int = -1
var child2_idx:int = -1
var auto_restart:bool = false
var mode_idx:int = 0

func _process(_delta):
	for i in 6:
		single_process_step()

func _reset_child_indices():
	child1_idx = 0
	if processing_modes[mode_idx] == GlueMode.cleaning:
		child2_idx = 0
	else:
		child2_idx = 1

func single_process_step():
	if get_child_count() < 2:
		stop_processing()
		return
	if child1_idx == -1:
		_reset_child_indices()
	if processing_modes[mode_idx] == GlueMode.cleaning:
		if child2_idx >= get_parent().visual_polygons.size():
			child1_idx += 1
			child2_idx = 0
	else:
		if child2_idx >= get_child_count():
			child1_idx += 1
			child2_idx = child1_idx + 1
	var max_child = get_child_count()-1
	if processing_modes[mode_idx] == GlueMode.cleaning: max_child = max_child+1
	if child1_idx >= max_child:
		if auto_restart:
			auto_restart = false
			_reset_child_indices()
		else:
			#var old_mode = processing_modes[mode_idx]
			var new_mode_idx = mode_idx + 1
			if new_mode_idx >= processing_modes.size():
				#print("Finished processing, stopping")
				stop_processing()
				return
			#var new_mode = processing_modes[new_mode_idx]
			#print("Switched from ", old_mode, " to ", new_mode)
			mode_idx = new_mode_idx	
			_reset_child_indices()
	match processing_modes[mode_idx]:
		GlueMode.merging: 
			handle_merging()
		GlueMode.quick_merging:
			child1_idx = child2_idx - 1
			handle_merging()
		GlueMode.clipping:
			handle_clipping()
		GlueMode.cleaning:
			handle_cleaning()
	child2_idx += 1

func handle_cleaning():
	#print("Cleaning ", child1_idx, " against ", child2_idx)
	var child1 = get_child(child1_idx)
	if child1.area < 1:
		#print("Child ", child1_idx, " is smaller than a pixel, deleting")
		child1.queue_free()
		child1_idx -= 1
		return
	var child2 = get_parent().visual_polygons[child2_idx]
	#print("clipping a ", child2_idx, " (visual polygon) hole out of ", child1_idx)
	var global_polygon1 = MyGeom.global_polygon(child1)
	var global_polygon2 = Geometry2D.offset_polygon(MyGeom.global_polygon(child2), -0.05)
	_clip_glue_polygon(child1, global_polygon1, global_polygon2)

func handle_clipping():
	#print("clipping a ", get_child_count()-1-child1_idx, " shaped hole out of ", get_child_count()-1-child2_idx)
	var child1:ItemGlueEdge = get_child(get_child_count()-1-child1_idx)
	var child2:ItemGlueEdge = get_child(get_child_count()-1-child2_idx)
	if child1.glue_color == child2.glue_color:
		return # don't clip between children of the same color, we'll merge later
	var global_polygon1 = Geometry2D.offset_polygon(MyGeom.global_polygon(child1), 0.05)
	var global_polygon2 = MyGeom.global_polygon(child2)
	_clip_glue_polygon(child2, global_polygon2, global_polygon1)

func _clip_glue_polygon(glue_obj:ItemGlueEdge, glue_global_poly, cutting_poly_array):
	var cutting_poly = cutting_poly_array
	if cutting_poly_array.size() == 1:
		cutting_poly = cutting_poly_array[0]
	else:
		for p in cutting_poly_array:
			if !Geometry2D.is_polygon_clockwise(p):
				cutting_poly = p
				break
	var clipped = Geometry2D.clip_polygons(glue_global_poly, cutting_poly)
	if clipped.size() == 0:
		#print(glue_obj.glue_color, " was entirely clipped away")
		auto_restart = true
		glue_obj.queue_free()
		if processing_modes[mode_idx] != GlueMode.cleaning:
			child1_idx += 1
			child2_idx += 1
		return
	if clipped.size() == 1 and Geometry2D.is_polygon_clockwise(clipped[0]):
		#print("Child polygon became a hole? ", glue_obj.glue_color)
		glue_obj.queue_free()
		return
	if clipped.size() == 1 and clipped[0] == glue_global_poly:
		#print("Child polygon is exactly the same, probably didn't get clipped, skipping...", glue_obj.glue_color)
		return
	var orig_polygon_handled = false
	for new_poly in clipped:
		if Geometry2D.is_polygon_clockwise(new_poly):
			#print("a child polygon was a hole, skipping ", glue_obj.glue_color)
			continue
		if !orig_polygon_handled:
			#print("Replacing original child polygon for ", glue_obj.glue_color)
			glue_obj.polygon = MyGeom.local_polygon(glue_obj, new_poly)
			orig_polygon_handled = true
		else:
			#print("Cloning this polygon with a new polygon ", glue_obj.glue_color)
			var new_child = glue_obj.clone(MyGeom.local_polygon(glue_obj, new_poly))
			self.add_child(new_child)
			self.move_child(new_child, glue_obj.get_index())

func handle_merging():
	var child1:ItemGlueEdge = get_child(child1_idx)
	var child2:ItemGlueEdge = get_child(child2_idx)
	if child1.glue_color == child2.glue_color:
		var global_polygon1 = MyGeom.global_polygon(child1)
		var global_polygon2 = MyGeom.global_polygon(child2)
		var merged := Geometry2D.merge_polygons(global_polygon1, global_polygon2)
		if merged.size() == 1:
			#print("Merging glues ", child1_idx, " and ", child2_idx)
			child2.polygon = MyGeom.local_polygon(child1, merged[0])
			child1.queue_free()
			auto_restart = true

func stop_processing():
	set_process(false)
	child1_idx = -1
	child2_idx = -1

#func _on_child_entered_tree(node):
func refresh_polygons():
	mode_idx = 0
	restart_processing()

func restart_processing():
	set_process(true)
	child1_idx = -1
	child2_idx = -1
