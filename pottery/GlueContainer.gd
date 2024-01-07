extends Node2D

signal glue_changed

var child1_idx:int = -1
var child2_idx:int = -1
var auto_restart:bool = false

func _process(delta):
	if get_child_count() < 2:
		stop_processing()
		return
	if child1_idx == -1:
		child1_idx = 0
		child2_idx = 1
	if child2_idx >= get_child_count():
		child1_idx += 1
		child2_idx = child1_idx + 1
	if child1_idx >= get_child_count()-1:
		if auto_restart:
			auto_restart = false
			child1_idx = 0
			child2_idx = 1
		else:
			glue_changed.emit()
			stop_processing()
			return
	var child1:ItemGlueEdge = get_child(child1_idx)
	var child2:ItemGlueEdge = get_child(child2_idx)
	var global_polygon1 = global_polygon(child1)
	var global_polygon2 = global_polygon(child2)
	var merged := Geometry2D.merge_polygons(global_polygon1, global_polygon2)
	if merged.size() == 1:
		#print("Merging glues ", child1_idx, " and ", child2_idx)
		child1.polygon = local_polygon(child1, merged[0])
		child2.queue_free()
		auto_restart = true
	else:
		#print("No merge for glue ", child1_idx, " and ", child2_idx)
		child2_idx += 1

func global_polygon(polygon_holder:Node2D):
	var result := PackedVector2Array()
	for pt in polygon_holder.polygon:
		result.append(polygon_holder.to_global(pt))
	return result

func local_polygon(polygon_holder:Node2D, polygon):
	var result := PackedVector2Array()
	for pt in polygon:
		result.append(polygon_holder.to_local(pt))
	return result

func stop_processing():
	set_process(false)
	child1_idx = -1
	child2_idx = -1

func _on_child_entered_tree(node):
	restart_processing()

func restart_processing():
	set_process(true)
	child1_idx = -1
	child2_idx = -1
