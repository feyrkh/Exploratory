extends Control

@onready var weathering_options = WeatheringMgr.get_sorted_weathering_options()
var cur_weathering_option = 0

func _ready():
	find_child("NextButton").pressed.connect(_on_next_example_pressed)
	find_child("PrevButton").pressed.connect(_on_prev_example_pressed)
	find_child("EnabledCheckbox").toggled.connect(_on_enabled_checkbox_toggled)
	generate_weathering_examples()

func refresh():
	generate_weathering_examples()

func _on_next_example_pressed():
	cur_weathering_option = (cur_weathering_option + 1) % weathering_options.size()
	generate_weathering_examples()

func _on_prev_example_pressed():
	cur_weathering_option = (cur_weathering_option - 1)
	if cur_weathering_option < 0:
		cur_weathering_option = weathering_options.size() - 1
	generate_weathering_examples()

func generate_weathering_examples():
	var weathering_name = weathering_options[cur_weathering_option]
	var l = WeatheringMgr.get_specific_option(weathering_name, 0.1)
	var m = WeatheringMgr.get_specific_option(weathering_name, 0.5)
	var h = WeatheringMgr.get_specific_option(weathering_name, 0.9)
	find_child("WeatheringName").text = l.weathering_name
	var li = load("res://art/item/shield_knot1.png").get_image()
	var mi = load("res://art/item/shield_knot1.png").get_image()
	var hi = load("res://art/item/shield_knot1.png").get_image()
	ImageMerger.modulate_image(li, Color.WHITE, l.noise, l.noise_cutoff, null, Vector2.ZERO, l.noise_floor)
	ImageMerger.modulate_image(mi, Color.WHITE, m.noise, m.noise_cutoff, null, Vector2.ZERO, m.noise_floor)
	ImageMerger.modulate_image(hi, Color.WHITE, h.noise, h.noise_cutoff, null, Vector2.ZERO, h.noise_floor)
	find_child("LowExample").texture = ImageTexture.create_from_image(li)
	find_child("MedExample").texture = ImageTexture.create_from_image(mi)
	find_child("HighExample").texture = ImageTexture.create_from_image(hi)
	find_child("EnabledCheckbox").button_pressed = WeatheringMgr.get_random_allowed(find_child("WeatheringName").text)

func _on_enabled_checkbox_toggled(toggled_on):
	WeatheringMgr.set_random_allowed(find_child("WeatheringName").text, toggled_on)
