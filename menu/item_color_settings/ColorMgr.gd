extends Node

var color_config := SettingsFile.new("user://colors.cfg", {})

func get_recently_used_colors()->Array[String]:
	return color_config.get_config("___recently_used___", [] as Array[String])

func add_recently_used_color(c:Color, max_colors:int):
	var html_color := c.to_html(false)
	var colors := get_recently_used_colors()
	var pos = colors.find(html_color)
	if pos >= 0:
		colors.erase(html_color)
	colors.push_front(html_color)
	if colors.size() > max_colors:
		colors.pop_back()
	color_config.set_config("___recently_used___", colors)

func get_colors_for_item(item_name:String):
	var colors = color_config.get_config(item_name, false)
	if colors:
		return colors
	else:
		var item_data:ItemBuilder.ItemConfig = ItemBuilder.all_items.get(item_name)
		return item_data.get_default_colors().map(func(c):
			if c is String: return c
			return c.to_html(false))

func remove_color_from_item(item_name:String, color:Color):
	var html_color:String = color.to_html(false)
	var colors = get_colors_for_item(item_name)
	colors.erase(html_color)
	color_config.set_config(item_name, colors)

func add_color_to_item(item_name:String, color:Color):
	var html_color:String = color.to_html(false)
	var colors = get_colors_for_item(item_name)
	if colors.find(html_color) < 0:
		colors.append(html_color)
	color_config.set_config(item_name, colors)

func clear_colors_for_item(item_name:String):
	color_config.erase_config(item_name)

func save():
	color_config.save_config()
