extends ColorRect
class_name DecorationBase

## The allowed type
@export var type:String = "icon"
## If one member of a group is present, all members must be present
@export var group:String
## All decorations of the same type with the same image ID will use the same image 
@export var img_id:String

# Used by save data system
var item_dir:String
var item_name:String
#var color:Color
#var position:Vector2
#var size:Vector2
