extends Node2D

func _ready():
	connect_values([
		"NoiseCutoff",  "Frequency", "NoiseFloor", "FractalLacunarity",
		"FractalGain", "FractalOctaves", "Seed", "CellJitter"
	])
	_on_noise_type_value_changed(find_child("NoiseType").value)
	_on_fractal_type_value_changed(find_child("FractalType").value)

func connect_values(names:Array[String]):
	for n in names:
		var child = find_child(n)
		child.value_changed.connect(func(val): 
			find_child(n+"Value").text = str(val)
			update_noise()
		)
		child.value_changed.emit(child.value)

func get_noise()->FastNoiseLite:
	var result := FastNoiseLite.new()
	result.noise_type = find_child("NoiseType").value
	result.frequency = find_child("Frequency").value
	result.fractal_type = find_child("FractalType").value
	result.fractal_lacunarity = find_child("FractalLacunarity").value
	result.fractal_gain = find_child("FractalGain").value
	result.fractal_octaves = find_child("FractalOctaves").value
	result.cellular_distance_function = find_child("CellDistance").value
	result.cellular_return_type = find_child("CellReturn").value
	result.cellular_jitter = find_child("CellJitter").value
	result.seed = find_child("Seed").value
	return result

func get_noise_cutoff()->float:
	return find_child("NoiseCutoff").value

func update_noise():
	find_child("ConstructiveTexture").generate_image(build_weathering_config())
	#noise.seed = randf()

func _on_noise_type_value_changed(value):
	var val = "Noise Type"
	match int(value):
		0: val = "simplex"
		1: val = "simplex_smooth"
		2: val = "cellular"
		3: val = "perlin"
		4: val = "value_cubic"
		5: val = "value"
	find_child("NoiseTypeValue").text = val
	var cell_settings_visible = int(value) == 2
	var cell_fields = [
		"Label10", "CellDistance", "CellDistanceValue", "Label11", "CellReturn",
		"CellReturnValue", "Label12", "CellJitter", "CellJitterValue"
	]
	for c in cell_fields:
		find_child(c).visible = cell_settings_visible
	update_noise()

func _on_fractal_type_value_changed(value):
	var val = "Fractal Type"
	match int(value):
		0: val = "none"
		1: val = "fbm"
		2: val = "ridged"
		3: val = "ping-pong"
	find_child("FractalTypeValue").text = val
	var fractal_settings_visible = int(value) != 0
	var children = [
		"Label5", "FractalLacunarity", "FractalLacunarityValue", "Label6",
		"FractalGain", "FractalGainValue", "Label7", "FractalOctaves", "FractalOctavesValue",
	]
	for c in children:
		find_child(c).visible = fractal_settings_visible
	update_noise()


func _on_cell_distance_value_changed(value):
	var val = "Cell Distance"
	match int(value):
		0: val = "euclid"
		1: val = "euclid^2"
		2: val = "manhattan"
		3: val = "hybrid"
	find_child("CellDistanceValue").text = val
	update_noise()


func _on_cell_return_value_changed(value):
	var val = "Cell Return"
	match int(value):
		0: val = "value"
		1: val = "distance"
		2: val = "distance^2"
		3: val = "distance add"
		4: val = "distance sub"
		5: val = "distance mul"
		6: val = "distance div"
	find_child("CellReturnValue").text = val
	update_noise()

func _on_save_button_pressed():
	var data = build_weathering_config()
	var path := ProjectSettings.globalize_path("res://weathering/")
	print("Saving to ", path)
	DirAccess.make_dir_absolute(path)
	var result = ResourceSaver.save(data, path+data.weathering_name+".tres")
	if result == OK:
		find_child("SavedLabel").text = "Saved"
	else:
		find_child("SavedLabel").text = "Error: "+str(result)
		push_error("Failed to save "+path+data.weathering_name+".tres: ", result)
	find_child("SavedLabel").visible = true
	await get_tree().create_timer(3.0).timeout
	find_child("SavedLabel").visible = false

func build_weathering_config():
	var data = WeatheringConfig.new()
	data.weathering_name = find_child("SaveFileName").text
	data.cell_distance = find_child("CellDistance").value
	data.cell_jitter = find_child("CellJitter").value
	data.cell_return = find_child("CellReturn").value
	data.fractal_gain = find_child("FractalGain").value
	data.fractal_lacunarity = find_child("FractalLacunarity").value
	data.fractal_octaves = find_child("FractalOctaves").value
	data.fractal_type = find_child("FractalType").value
	data.frequency = find_child("Frequency").value
	data.noise_cutoff = find_child("NoiseCutoff").value
	data.noise_floor = find_child("NoiseFloor").value
	data.noise_type = find_child("NoiseType").value
	data.seed = find_child("Seed").value
	return data
