extends CustomMenuButton
class_name DifficultyMode

@export var settings:GameSettings

func _ready():
	super._ready()
	text = settings.name
