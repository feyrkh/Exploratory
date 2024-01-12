extends Node

@export var max_players_in_pool:int = 10
var volume_adjustment = 0

var players = []
var audioConfig := SettingsFile.new("user://audio.cfg", {
	"sfx_volume": 100
})

func _ready():
	get_first_free_player()
	volume_adjustment = get_decibels_for_volume_percentage(audioConfig.get_config("sfx_volume"))
	Global.setting_changed.connect(on_setting_change)

func on_setting_change(setting, old_val, new_val):
	if setting == "sfx_volume":
		volume_adjustment = get_decibels_for_volume_percentage(new_val)
		for player in players:
			player.volume_db = volume_adjustment

static func get_decibels_for_volume_percentage(volume_percent): # 0 - 100.0 range, usually
	if volume_percent <= 0:
		return -80
	volume_percent = volume_percent / 100.0
	return (60.0 * volume_percent) - 60 # range goes from -80 decibels (silent?) to 0 (normal) or higher (really loud)
	
func play(stream_file, pitch=1.0):
	var player:AudioStreamPlayer = get_first_free_player()
	player.pitch_scale = pitch
	player.volume_db = volume_adjustment
	if stream_file is String:
		player.stream = load(stream_file)
	else:
		player.stream = stream_file
	player.play()

func get_first_free_player():
	for player in players:
		if !player.playing:
			return player
	if players.size() >= max_players_in_pool:
		return players[0]
	var new_player = AudioStreamPlayer.new()
	players.append(new_player)
	add_child(new_player)
	return new_player
