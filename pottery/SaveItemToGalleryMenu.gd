extends Control

var image:Image

func setup(img:Image):
	self.image = img
	find_child("TextureRect").texture = ImageTexture.create_from_image(img)
