extends Control
class_name TimeAttackCompleteMenu

const IMG_IDX := 0
const ITEM_IDX := 1
const SAVED_IDX := 2

signal item_saved
signal closed

var item_arr:Array
var image:Image
var item
var cur_idx:int = 0

func setup(_item_arr:Array): # Array of [Image, ArcheologyItem]
	self.item_arr = Array(_item_arr)
	for _item in self.item_arr:
		_item.append(false) # 3rd field
	if is_inside_tree():
		get_tree().paused = true
		render_item(0)

func render_empty_set():
	find_child("ItemLabel").text = "No items"
	find_child("ScoreContainer").visible = false
	find_child("NextButton").text = "Finished"
	find_child("SaveButton").disabled = true
	find_child("PrevButton").disabled = true

func render_item(idx:int):
	find_child("ItemLabel").text = "Completed piece"
	find_child("ScoreContainer").visible = true
	if item_arr.size() == 0:
		render_empty_set()
		return
	var piece:ArcheologyItem = item_arr[idx][ITEM_IDX]
	var saved = item_arr[idx][SAVED_IDX]
	var header_label = find_child("ItemLabel")
	find_child("PrevButton").disabled = idx == 0
	find_child("NextButton").text = "Finished" if (idx+1) >= item_arr.size() else "Next"
	find_child("SaveButton").disabled = saved
	if saved:
		header_label.text = "Artifact saved to gallery"
	else:
		header_label.text = "A completed artifact"
	self.image = item_arr[idx][IMG_IDX]
	self.item = item_arr[idx][ITEM_IDX]
	find_child("TextureRect").texture = ImageTexture.create_from_image(self.image)
		
	find_child("ValuePieceCount").text = str(piece.original_fragment_count)
	var piece_count_score = calc_piece_count_score(piece.original_fragment_count)
	find_child("ScorePieceCount").text = "%d" % piece_count_score
	
	find_child("ValueItemCount").text = str(piece.original_item_count)
	var item_count_score = calc_item_count_score(piece.original_item_count)
	find_child("ScoreItemCount").text = "x%.1f" % item_count_score
	
	find_child("ValueComplete").text = "%.1f%%" % [piece.area_pct * 100]
	var area_pct_score = calc_area_pct_score(piece.area_pct)
	find_child("ScoreComplete").text = "x%.1f" % area_pct_score
	
	find_child("ValueShatter").text = calc_shatter_desc(piece.shatter_size)
	var shatter_score = calc_shatter_score(piece.shatter_size)
	find_child("ScoreShatter").text = "x%.1f" % shatter_score
	
	var displacement = piece.get_displacement_score()
	find_child("ValueAccuracy").text = "%.1f" % [displacement]
	var displacement_score = calc_displacement_score(displacement)
	find_child("ScoreAccuracy").text = "x%.1f" % displacement_score
	piece.final_displacement_score = displacement_score
	
	find_child("ValueTime").text = TimeUtil.format_timer(piece.time_attack_seconds)
	var time_attack_seconds_score = calc_time_attack_seconds_score(piece.time_attack_seconds)
	find_child("ScoreTime").text = "x%.1f" % time_attack_seconds_score
	
	find_child("ValueBump").text = "Yes" if piece.bump_enabled else "No" 
	var bump_enabled_score = calc_bump_enabled_score(piece.bump_enabled)
	find_child("ScoreBump").text = "x%.1f" % bump_enabled_score
	
	find_child("ValueRotate").text = "Yes" if piece.rotate_enabled else "No" 
	var rotate_enabled_score = calc_rotate_enabled_score(piece.rotate_enabled)
	find_child("ScoreRotate").text = "x%.1f" % rotate_enabled_score
	
	var total_score = roundi(piece_count_score * item_count_score * area_pct_score * displacement_score * time_attack_seconds_score * shatter_score * bump_enabled_score * rotate_enabled_score)
	find_child("ScoreTotal").text = "%d" % total_score
	piece.final_score = total_score

func calc_time_attack_seconds_score(v:int) -> float:
	if v <= 0:
		return 0
	if v <= 30:
		return 2.0
	elif v <= 60:
		return 2.0 - (v-30)/30.0
	return 1 / ((v+120) / 180.0)

func calc_bump_enabled_score(v:bool) -> float:
	return 1.5 if v else 1.0

func calc_rotate_enabled_score(v:bool) -> float:
	return 2.5 if v else 1.0

func calc_piece_count_score(v:int) -> int:
	return v*100

func calc_item_count_score(v:int) -> float:
	return (v * 1.0) - max(0, v * 0.1 - 0.1)

func calc_area_pct_score(v:float) -> float:
	if v > 0.99 and v < 1.01:
		return 1.0
	if v > 1.0:
		v = (v-1)*3+1
	return min(v, 1.0) / max(v, 1.0)

func calc_shatter_desc(v:float) -> String:
	if v < 0.1:
		return 'hairline'
	if v < 0.3:
		return 'thin'
	if v < 1:
		return 'medium'
	return 'thick'
	

func calc_shatter_score(v:float) -> float:
	if v < 0.1:
		return 1.0
	if v < 0.3:
		return 1.1
	if v < 1:
		return 1.2
	return 1.3

func calc_displacement_score(v:float) -> float:
	if v < 0.1: 
		return 1.0
	if v < 1:
		return 0.9
	if v < 5:
		return 0.8
	if v < 15:
		return 0.7
	if v < 30:
		return 0.6
	if v < 50:
		return 0.5
	if v < 75:
		return 0.4
	if v < 100:
		return 0.3
	if v < 150:
		return 0.2
	if v < 250:
		return 0.1
	return 0

#func _unhandled_input(event):
	#if event.is_action_pressed("ui_cancel"):
		#_on_cancel_pressed()
		#get_viewport().set_input_as_handled()
#
#func _on_cancel_pressed():
	#get_tree().paused = false
	#queue_free()
	#closed.emit()

func _on_save_pressed():
	GalleryMgr.save_to_gallery(image, item, report_error)
	#item.queue_free()
	item_arr[cur_idx][SAVED_IDX] = true
	render_item(cur_idx)
	#find_child("SaveButton").visible = false
	#find_child("CancelButton").text = "Ok"
	#find_child("Label").text = "This item has been moved\nto your gallery"
	#item_saved.emit()
	#closed.emit()
	
func report_error(err):
	push_error(err)
	find_child("TextureRect").visible = false
	find_child("Label").text = err


func _on_prev_button_pressed():
	cur_idx = max(0, cur_idx - 1)
	render_item(cur_idx)

func _on_next_button_pressed():
	cur_idx = min(item_arr.size(), cur_idx + 1)
	if cur_idx == item_arr.size():
		for _item in item_arr:
			if _item[SAVED_IDX]:
				_item[ITEM_IDX].queue_free()
		get_tree().paused = false
		queue_free()
	else:
		render_item(cur_idx)
