extends RefCounted
class_name SoilInfo

var soil_layers:Array[SoilComponent] = []

func size() -> int:
	return soil_layers.size()

func get_layer(idx:int) -> SoilComponent:
	if soil_layers.size() <= idx: 
		return null
	return soil_layers[idx]

func random_layer_adjustment(seed:int) -> void:
	var rand:RandomNumberGenerator = RandomNumberGenerator.new()
	rand.seed = seed
	var new_layers:Array[SoilComponent] = soil_layers.map(func(layer:SoilComponent): return layer.clone())
	for layer in new_layers:
		layer.depth *= rand.randf_range(0.6, 1.4)
	soil_layers = new_layers
	
static func erode_soil_layers(_soil_layers:Array[SoilComponent], _erosion_layers:Array[ErosionInfo]) -> Array[SoilComponent]:
	var retval:Array[SoilComponent] = []
	var erosion_layers:Array[ErosionInfo] = _erosion_layers.slice(0)
	var soil_layers:Array[SoilComponent] = []
	for layer in _soil_layers:
		soil_layers.append(layer.clone())
	var cur_erosion:ErosionInfo = erosion_layers.pop_front()
	var cur_depth = 0
	var cur_soil:SoilComponent = soil_layers.pop_front()
	while cur_erosion and cur_soil:
		if cur_depth >= cur_erosion.start_depth:
			# the current layer starts inside the erosion zone
			if cur_depth + cur_soil.depth <= cur_erosion.end_depth:
				# the current layer is entirely contained by the erosion zone - delete the whole soil layer
				cur_depth += cur_soil.depth
				cur_soil = soil_layers.pop_front()
				if cur_depth >= cur_erosion.end_depth:
					# the current soil layer ended exactly on the current erosion layer, move to the next erosion layer
					cur_erosion = erosion_layers.pop_front()
			else:
				# the current layer starts inside the erosion zone, but the erosion zone ends inside the current layer - delete the first part of the soil layer
				var local_depth_of_cut = cur_erosion.end_depth - cur_depth
				var local_age_of_cut = (cur_soil.age_end - cur_soil.age_start) * (local_depth_of_cut / cur_soil.depth)
				cur_soil.age_start = local_age_of_cut + cur_soil.age_start
				cur_soil.depth -= local_depth_of_cut
				cur_depth += local_depth_of_cut
				# Move to the next erosion layer, but keep the current soil as the working layer because a layer erosion layer might still affect it
				cur_erosion = erosion_layers.pop_front()
		elif cur_depth + cur_soil.depth > cur_erosion.start_depth:
			# the current layer starts outside the erosion zone, but ends inside or after it
			if cur_depth + cur_soil.depth <= cur_erosion.end_depth:
				# the current layer starts outside the erosion zone, but ends inside the zone - delete the last part of the soil layer
				var local_depth_of_cut = cur_erosion.start_depth - cur_depth
				var local_age_of_cut = (cur_soil.age_end - cur_soil.age_start) * (local_depth_of_cut / cur_soil.depth)
				cur_soil.age_end = local_age_of_cut + cur_soil.age_start
				cur_depth += cur_soil.depth
				cur_soil.depth = local_depth_of_cut
				# we are done with this soil layer so append it to our result and move to the next layer, but keep the current erosion layer because it will affect
				# the next soil layer
				retval.append(cur_soil)
				cur_soil = soil_layers.pop_front()
			else:
				# the current layer starts outside the erosion zone, and ends after the zone - split the soil layer in two
				var local_start_depth_of_cut = cur_erosion.start_depth - cur_depth
				var local_start_age_of_cut = (cur_soil.age_end - cur_soil.age_start) * (local_start_depth_of_cut / cur_soil.depth)
				var local_end_depth_of_cut = cur_erosion.end_depth - cur_depth
				var local_end_age_of_cut = (cur_soil.age_end - cur_soil.age_start) * (local_end_depth_of_cut / cur_soil.depth)
				var first_soil_chunk = cur_soil.clone()
				first_soil_chunk.depth = local_start_depth_of_cut
				first_soil_chunk.age_end = local_start_age_of_cut + cur_soil.age_start
				retval.append(first_soil_chunk)
				cur_soil.depth = cur_soil.depth - local_end_depth_of_cut
				cur_soil.age_start = local_end_age_of_cut + cur_soil.age_start
				# Move to the next erosion layer, but keep the current soil as the working layer because a layer erosion layer might still affect it
				cur_erosion = erosion_layers.pop_front()
				cur_depth += local_end_depth_of_cut
		else:
			# the current soil layer doesn't overlap with the current erosion
			cur_depth += cur_soil.depth
			retval.append(cur_soil)
			cur_soil = soil_layers.pop_front()
	if cur_soil:
		retval.append(cur_soil)
	while !soil_layers.is_empty():
		retval.append(soil_layers.pop_front())
	return retval

#func get_soil_at_depth(depth:float, erosions:Array[ErosionInfo]) -> Array: # [SoilComponent, absolute_depth, absolute_age]:
	#if soil_layers.size() == 0:
		#soil_layers.append(new_soil_layer(0))
	#var cur_layer_idx = 0
	#var cur_layer := soil_layers[cur_layer_idx]
	#var cur_erosion_idx = 0
	#var cur_erosion:ErosionInfo
	#var remaining_erosion_depth:float
	#if erosions.size() > 0:
		#cur_erosion = erosions[cur_erosion_idx]
		#remaining_erosion_depth = cur_erosion.end_depth - cur_erosion.start_depth
	#var abs_depth:float = 0
	#while depth > 0:
		#var start_depth = depth
		#var start_abs_depth = abs_depth
		## Check if we are entering the next erosion area
		#if cur_erosion and remaining_erosion_depth <= 0 and start_abs_depth <= cur_erosion.start_depth and start_abs_depth + cur_layer.depth >= cur_erosion.start_depth:
			#remaining_erosion_depth = cur_erosion.end_depth - cur_erosion.start_depth
		#if remaining_erosion_depth > 0:
			#var consumed_erosion = max(0, min(start_abs_depth + cur_layer.depth, cur_erosion.end_depth) - max(start_abs_depth, cur_erosion.start_depth))
			#remaining_erosion_depth -= consumed_erosion
			#depth += consumed_erosion
			#if remaining_erosion_depth <= 0:
				#cur_erosion_idx += 1
				#if cur_erosion_idx < erosions.size():
					#cur_erosion = erosions[cur_erosion_idx]
				#else:
					#cur_erosion = null
		#if depth > cur_layer.depth:
			#depth -= cur_layer.depth
			#abs_depth += cur_layer.depth
			#cur_layer_idx += 1
			#if cur_layer_idx >= soil_layers.size():
				#soil_layers.append(new_soil_layer(cur_layer.age_end + 1))
			#cur_layer = soil_layers[cur_layer_idx]
		#else:
			#break
	#abs_depth += depth
	#var cur_age = (depth / cur_layer.depth) * (cur_layer.age_end - cur_layer.age_start) + cur_layer.age_start
	#return [cur_layer, abs_depth, cur_age]
			
func get_soil_at_depth(depth:float) -> SoilQueryResult: # [SoilComponent, absolute_depth, absolute_age]:
	if soil_layers.size() == 0:
		soil_layers.append(new_soil_layer(0))
	var cur_layer_idx = 0
	var cur_layer := soil_layers[cur_layer_idx]
	var abs_depth:float = 0
	var remaining_depth_in_layer:float = cur_layer.depth
	while depth > 0:
		var start_depth = depth
		var start_abs_depth = abs_depth
		if depth > cur_layer.depth:
			depth -= cur_layer.depth
			abs_depth += cur_layer.depth
			cur_layer_idx += 1
			if cur_layer_idx >= soil_layers.size():
				soil_layers.append(new_soil_layer(cur_layer.age_end + 1))
			cur_layer = soil_layers[cur_layer_idx]
		else:
			remaining_depth_in_layer = cur_layer.depth - depth
			break
	abs_depth += depth
	var cur_age = (depth / cur_layer.depth) * (cur_layer.age_end - cur_layer.age_start) + cur_layer.age_start
	return SoilQueryResult.new(cur_layer, cur_age, abs_depth, remaining_depth_in_layer, cur_layer_idx)
	
func new_soil_layer(start_age:int)->SoilComponent:
	return SoilComponent.random(start_age, start_age + randi_range(5, 40))

func print_layers()->void:
	for layer in soil_layers:
		print(layer)
