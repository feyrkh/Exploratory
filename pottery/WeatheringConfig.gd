extends Resource
class_name WeatheringConfig

@export var sort_order:int = 0
@export var weathering_name:String
@export var noise_type:int
@export var noise_floor:float
@export var noise_cutoff:float
@export var frequency:float
@export var fractal_type:int
@export var fractal_lacunarity:float
@export var fractal_gain:float
@export var fractal_octaves:int
@export var cell_distance:int
@export var cell_return:int
@export var cell_jitter:float
@export var seed:int = 0

const SAVE_FIELDS = [
		"noise_type", "noise_floor", "noise_cutoff", "frequency", "fractal_type", "fractal_lacunarity", "fractal_gain",
		"fractal_octaves", "cell_distance", "cell_return", "cell_jitter", "seed"
	]
func get_save_data() -> Array:
	return SAVE_FIELDS.map(func(field): return self.get(field))

static func load_save_data(data) -> WeatheringConfig:
	if data is Array:
		var result = WeatheringConfig.new()
		for i in range(SAVE_FIELDS.size()):
			result.set(SAVE_FIELDS[i], data[i])
		return result
	elif data is WeatheringConfig:
		return data
	else:
		push_error("Unexpected weathering save data: ", data)
		return null

var noise:FastNoiseLite:
	get:
		if !noise:
			noise = FastNoiseLite.new()
			noise.noise_type = noise_type
			noise.frequency = frequency
			noise.fractal_type = fractal_type
			noise.fractal_lacunarity = fractal_lacunarity
			noise.fractal_gain = fractal_gain
			noise.fractal_octaves = fractal_octaves
			noise.cellular_distance_function = cell_distance
			noise.cellular_return_type = cell_return
			noise.cellular_jitter = cell_jitter
			noise.seed = seed
		return noise

static func interpolate(low:WeatheringConfig, high:WeatheringConfig, degree:float) -> WeatheringConfig:
	var result = WeatheringConfig.new()
	result.sort_order = low.sort_order
	result.weathering_name = low.weathering_name
	result.noise_type = low.noise_type
	result.noise_floor = _interpolate(low.noise_floor, high.noise_floor, degree)
	result.noise_cutoff = _interpolate(low.noise_cutoff, high.noise_cutoff, degree)
	result.frequency = _interpolate(low.frequency, high.frequency, degree)
	result.fractal_type = low.fractal_type
	result.fractal_lacunarity = _interpolate(low.fractal_lacunarity, high.fractal_lacunarity, degree)
	result.fractal_gain = _interpolate(low.fractal_gain, high.fractal_gain, degree)
	result.fractal_octaves = int(_interpolate(low.fractal_octaves, high.fractal_octaves, degree))
	result.cell_distance = low.cell_distance
	result.cell_return = low.cell_return
	result.cell_jitter = _interpolate(low.cell_jitter, high.cell_jitter, degree)
	result.seed = randi()
	return result

static func _interpolate(v1, v2, degree:float)->float:
	return v1 + (v2-v1) * degree


