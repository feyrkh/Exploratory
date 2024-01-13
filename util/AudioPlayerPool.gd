extends Node

@export var max_players_in_pool:int = 10
@export var background_music_list:Array[String] = ["res://music/Namaste.mp3", "res://music/OnWaldenPond.mp3", "res://music/Transcend.mp3", "res://music/Beautiful Daughter.mp3"]

@onready var musicPlayer1 = $MusicPlayer1
@onready var musicPlayer2 = $MusicPlayer2

const OVERALL_VOLUME_PCT := "overall_volume"
const SFX_VOLUME_PCT := "sfx_volume"
const MUSIC_VOLUME_PCT := "music_volume"
const MIN_VOLUME := 0.0
const MAX_VOLUME := 1.0

var players = []
var audio_config := SettingsFile.new("user://audio.cfg", {
	OVERALL_VOLUME_PCT: 1.0,
	SFX_VOLUME_PCT: 1.0,
	MUSIC_VOLUME_PCT: 0.5,
})

# music crossfading stuff
var fade_counter:float = 0
var seconds_to_fade = 3
var fading = false
var music_positions = {}
var musicPlayer1_file = ""
var musicPlayer2_file
var fade_up_per_sec = 0
var fade_down_per_sec = 0
var expected_next_volume = 0
var expected_cur_volume = 0
var next_background_music_index = 0
var crossfade_time = 5
var config_needs_saving := false

var sfx_volume:float:
	get:
		return audio_config.get_config(SFX_VOLUME_PCT)
	set(val):
		config_needs_saving = true
		audio_config.set_config(SFX_VOLUME_PCT, val)
		apply_sfx_volume()
var music_volume:float:
	get:
		return audio_config.get_config(MUSIC_VOLUME_PCT)
	set(val):
		config_needs_saving = true
		audio_config.set_config(MUSIC_VOLUME_PCT, val)
		apply_music_volume()
var overall_volume:float:
	get:
		return audio_config.get_config(OVERALL_VOLUME_PCT)
	set(val):
		config_needs_saving = true
		audio_config.set_config(OVERALL_VOLUME_PCT, val)
		apply_music_volume()
		apply_sfx_volume()

func _ready():
	background_music_list.shuffle()
	get_first_free_player()
	Global.setting_changed.connect(on_setting_change)
	await Global.enable_sound
	cross_fade(background_music_list[0], 2, true)
	var settings_saver = Timer.new()
	add_child(settings_saver)
	settings_saver.one_shot = false
	settings_saver.timeout.connect(func():
		if config_needs_saving:
			config_needs_saving = false
			audio_config.save_config()
		)
	settings_saver.start(5)

func on_setting_change(setting, old_val, new_val):
	match setting:
		OVERALL_VOLUME_PCT: overall_volume = new_val
		SFX_VOLUME_PCT: sfx_volume = new_val
		MUSIC_VOLUME_PCT: music_volume = new_val

func apply_sfx_volume():
	var volume = get_decibels_for_sfx()
	for player in players:
		player.volume_db = volume

func apply_music_volume():
	musicPlayer1.volume_db = get_decibels_for_music(expected_cur_volume)
	musicPlayer2.volume_db = get_decibels_for_music(expected_next_volume)

func get_decibels_for_sfx(volume_adjustment:float=1.0)->float:
	return get_decibels_for_volume_percentage(volume_adjustment * sfx_volume)

func get_decibels_for_music(volume_adjustment:float=1.0)->float:
	var music_pct = music_volume
	var overall_pct = volume_adjustment * music_volume
	return get_decibels_for_volume_percentage(overall_pct)

func get_decibels_for_volume_percentage(volume_percent:float=1.0)->float: # 0 - 1.0 range for pct, translates to -80 to 0 decibel adjustment
	if volume_percent <= 0:
		return -80
	return (50.0 * volume_percent * overall_volume) - 50 # range goes from -80 decibels (silent?) to 0 (normal) or higher (really loud)
	
func play_sfx(stream_file, pitch:=1.0, single_play_volume_adjustment:=1.0):
	var player:AudioStreamPlayer = get_first_free_player()
	player.pitch_scale = pitch
	player.volume_db = get_decibels_for_sfx(single_play_volume_adjustment)
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

func cross_fade(new_music_file, crossfade_time, new_music_saves_position=true):
	if fading:
		swap_players()
	musicPlayer2_file = new_music_file
	music_positions[musicPlayer1_file] = musicPlayer1.get_playback_position()
	fade_counter = crossfade_time
	musicPlayer2.stop()
	musicPlayer2.stream = load(new_music_file)
	musicPlayer2.volume_db = -80
	set_next_volume(0.0)
	fade_up_per_sec = (MAX_VOLUME - MIN_VOLUME)/crossfade_time
	fade_down_per_sec = (expected_cur_volume - MIN_VOLUME)/crossfade_time
	var start_position = 0.0
	if new_music_saves_position:
		start_position = music_positions.get(new_music_file, 0.0)
		print("Resuming ", new_music_file, " at ", start_position)
	else:
		print("Resuming ", new_music_file, " from the beginning, always")
	musicPlayer2.play(start_position)
	fading = true
	set_process(true)

func check_background_music():
	if background_music_list.size() == 0:
		return
	else:
		if !musicPlayer1.playing and !musicPlayer2.playing:
			cross_fade(background_music_list[next_background_music_index], 2, false)
			next_background_music_index = (next_background_music_index + 1) % background_music_list.size()
		elif musicPlayer1.playing and !fading and musicPlayer1.get_playback_position() > musicPlayer1.stream.get_length() - crossfade_time:
			next_background_music_index = (next_background_music_index + 1) % background_music_list.size()
			cross_fade(background_music_list[next_background_music_index], crossfade_time, false)

func _process(delta):
	set_next_volume(min(MAX_VOLUME, expected_next_volume + fade_up_per_sec * delta))
	set_cur_volume(max(MIN_VOLUME, expected_cur_volume - fade_down_per_sec * delta))
	if expected_next_volume == MAX_VOLUME:
		music_positions[musicPlayer1_file] = musicPlayer1.get_playback_position()
		print("Crossfade finished, pausing ", musicPlayer1_file, " at ", musicPlayer1.get_playback_position())
		musicPlayer1.stop()
		swap_players()
		fading = false
		set_process(false)

func set_next_volume(amt):
	if expected_next_volume != amt:
		expected_next_volume = amt
		musicPlayer2.volume_db = get_decibels_for_music(expected_next_volume)
		#print("Next volume: ", amt, " (actual: ", musicPlayer2.volume_db, ")")

func set_cur_volume(amt):
	if expected_cur_volume != amt:
		expected_cur_volume = amt
		musicPlayer1.volume_db = get_decibels_for_music(expected_cur_volume)
		#print("Cur volume: ", amt, " (actual: ", musicPlayer1.volume_db, ")")

func swap_players():
	var tmp = musicPlayer1
	musicPlayer1 = musicPlayer2
	musicPlayer2 = tmp
	tmp = musicPlayer1_file
	musicPlayer1_file = musicPlayer2_file
	musicPlayer2_file = tmp
	tmp = expected_cur_volume
	expected_cur_volume = expected_next_volume
	expected_next_volume = tmp
	#print("Swapped music players - cur=", musicPlayer1_file, ", next=", musicPlayer2_file)

func _on_timer_timeout():
	check_background_music()
