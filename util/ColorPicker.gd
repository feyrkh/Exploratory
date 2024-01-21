extends PanelContainer

signal color_chosen(c:Color)
signal color_changed(c:Color)

@export_multiline var save_button_text := "Save\nColor"

var r_gradient := Gradient.new()
var g_gradient := Gradient.new()
var b_gradient := Gradient.new()

var r_stylebox:StyleBox
var g_stylebox:StyleBox
var b_stylebox:StyleBox

@onready var r_slider:HSlider = find_child("RedSlider")
@onready var g_slider:HSlider = find_child("GreenSlider")
@onready var b_slider:HSlider = find_child("BlueSlider")

var manually_updating := false
var color:Color

func _ready():
	config_slider(r_slider, r_stylebox, r_gradient, Color.RED)
	config_slider(g_slider, g_stylebox, g_gradient, Color.GREEN)
	config_slider(b_slider, b_stylebox, b_gradient, Color.BLUE)
	r_slider.value_changed.connect(_slider_value_changed)
	g_slider.value_changed.connect(_slider_value_changed)
	b_slider.value_changed.connect(_slider_value_changed)
	find_child("SaveButton").pressed.connect(func(): color_chosen.emit(find_child("ChosenColor").color))
	find_child("ChosenColor").gui_input.connect(func(event:InputEvent): 
		if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			color_chosen.emit(find_child("ChosenColor").color))
	find_child("SaveButton").text = save_button_text
	update_colors()

func config_slider(slider, stylebox, gradient, new_color):
	stylebox = StyleBoxTexture.new()
	stylebox.texture = GradientTexture1D.new()
	gradient.colors = [Color.BLACK, new_color]
	stylebox.texture.gradient = gradient
	stylebox.texture_margin_bottom = 10
	slider.add_theme_stylebox_override("grabber_area", StyleBoxEmpty.new())
	slider.add_theme_stylebox_override("grabber_highlight_area", StyleBoxEmpty.new())
	slider.add_theme_stylebox_override("slider", stylebox)

func _slider_value_changed(_value):
	update_colors()

func update_colors(update_text:=true):
	if manually_updating:
		return
	r_gradient.colors[0] = Color(0, g_slider.value, b_slider.value)
	r_gradient.colors[1] = Color(1, g_slider.value, b_slider.value)
	g_gradient.colors[0] = Color(r_slider.value, 0, b_slider.value)
	g_gradient.colors[1] = Color(r_slider.value, 1, b_slider.value)
	b_gradient.colors[0] = Color(r_slider.value, g_slider.value, 0)
	b_gradient.colors[1] = Color(r_slider.value, g_slider.value, 1)
	var c:Color = Color(r_slider.value, g_slider.value, b_slider.value)
	if update_text:
		find_child("ColorCode").text = c.to_html(false)
	find_child("ChosenColor").color = c
	self.color = c
	color_changed.emit(c)


func _on_color_code_text_changed(new_text):
	manually_updating = true
	var c:Color = Color.from_string(new_text, Color.BLACK)
	r_slider.value = c.r
	g_slider.value = c.g
	b_slider.value = c.b
	manually_updating = false
	update_colors(false)
