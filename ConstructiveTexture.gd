extends Node2D

@export var baseName:String
@export var bandName:String
@export var knotName:String

func _process(_delta):
	if Input.is_action_just_pressed("add_crack"):
		for child in get_children():
			child.queue_free()
		generate_image()

func _ready():
	generate_image()

func generate_image():
	var baseImgAndCollider = load("res://art/item/"+baseName+"_collider.tscn").instantiate()
	var bandImg:Image = load("res://art/item/"+bandName+".png").get_image()
	var knot_img:Image = load("res://art/item/"+knotName+".png").get_image()
	knot_img.resize(knot_img.get_width()/2, knot_img.get_height()/2)
	var baseSprite:Sprite2D = baseImgAndCollider.find_child("Sprite2D")
	var baseImg = baseSprite.texture.get_image()
	var baseCollider:PackedVector2Array = baseImgAndCollider.find_child("CollisionPolygon2D").polygon
	baseImgAndCollider.queue_free()
	var base_rect = Rect2i(0, 0, baseImg.get_width(), baseImg.get_height())
	var band_rect = Rect2i(0, 0, bandImg.get_width(), bandImg.get_height())
	var band_target_x:int = base_rect.get_center().x - band_rect.size.x/2
	var band_target_y:int = randi_range(50, 120)
	
	modulate_image(baseImg, [Color.RED, Color.BLUE, Color.ORANGE_RED].pick_random())
	modulate_image(bandImg, [Color.GREEN, Color.BLACK, Color.WHITE_SMOKE].pick_random())
	baseImg.blend_rect(bandImg, band_rect, Vector2i(band_target_x, band_target_y))
	
	var knot_rect = Rect2i(0, 0, knot_img.get_width(), knot_img.get_height())
	var knot_target = Vector2i(base_rect.get_center().x - knot_rect.size.x/2, randi_range(band_target_y + band_rect.size.y + 10, base_rect.size.y - knot_rect.size.y - 10))
	modulate_image(knot_img, [Color.PURPLE, Color.AQUA, Color.DARK_BLUE].pick_random())
	baseImg.blend_rect(knot_img, knot_rect, knot_target)
	
	var new_texture = ImageTexture.create_from_image(baseImg)
	var sprite = Sprite2D.new()
	sprite.texture = new_texture
	add_child(sprite)
	sprite.position = Vector2(500, 400)
#
	#var combined_img:Sprite2D = $CombinedImage
	#var base_img_and_collider = load("res://art/item/"+baseName+"_collider.tscn").instantiate()
	#var base_img:Texture2D = base_img_and_collider.find_child("Sprite2D").texture
	#combined_img.draw_texture(base_img, Vector2.ZERO, Color.RED)

func modulate_image(img:Image, color:Color):
	for y in img.get_height():
		for x in img.get_width():
			img.set_pixel(x, y, img.get_pixel(x, y) * color)
