extends TextureButton

const HOVER_COLOR := Color.WHITE
const NON_HOVER_COLOR := Color(1, 1, 1, 0.6)
const FLASH_COLOR := Color(1, 1, 1, 1)

var glow_sprite:Sprite2D
var flash_tween:Tween

func _ready():
	glow_sprite = get_parent().find_child("GlowSprite")
	modulate = NON_HOVER_COLOR
	self.mouse_entered.connect(on_hover)
	self.mouse_exited.connect(on_non_hover)
	self.button_down.connect(start_flash)
	var next_sib = get_parent().get_child(get_index() + 1)
	if next_sib is ExpandLabel:
		mouse_entered.connect(next_sib.reveal_text)
		mouse_exited.connect(next_sib.hide_text)

func on_hover():
	cleanup_flash_tween()
	modulate = HOVER_COLOR
	scale = Vector2(1.1, 1.1)

func start_flash():
	if glow_sprite == null:
		return
	cleanup_flash_tween()
	glow_sprite.visible = true
	glow_sprite.modulate = FLASH_COLOR
	glow_sprite.position = position + pivot_offset
	flash_tween = glow_sprite.create_tween()
	flash_tween.tween_property(glow_sprite, "modulate", Color.TRANSPARENT, 0.3)
	flash_tween.tween_property(glow_sprite, "visible", false, 0.0)

func cleanup_flash_tween():
	if glow_sprite == null:
		return
	glow_sprite.visible = false
	if flash_tween and flash_tween.is_running():
		flash_tween.stop()

func on_non_hover():
	cleanup_flash_tween()
	modulate = NON_HOVER_COLOR
	scale = Vector2(1.0, 1.0)
