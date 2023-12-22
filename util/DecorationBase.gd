extends ColorRect
class_name DecorationBase

## The allowed type
@export var type:String = "icon"
## If one member of a group is present, all members must be present
@export var group:String
## All decorations of the same type with the same image ID will use the same image 
@export var img_id:String

