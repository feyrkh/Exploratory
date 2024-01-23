extends Control

func _ready():
	find_child("OverallVolume").value_changed.connect(_on_overall_volume_value_changed)
	find_child("SfxVolume").value_changed.connect(_on_sfx_volume_value_changed)
	find_child("MusicVolume").value_changed.connect(_on_music_volume_value_changed)
	refresh()

func _on_sfx_volume_value_changed(value):
	Global.setting_changed.emit(AudioPlayerPool.SFX_VOLUME_PCT, AudioPlayerPool.audio_config.get_config(AudioPlayerPool.SFX_VOLUME_PCT), value)

func _on_music_volume_value_changed(value):
	Global.setting_changed.emit(AudioPlayerPool.MUSIC_VOLUME_PCT, AudioPlayerPool.audio_config.get_config(AudioPlayerPool.MUSIC_VOLUME_PCT), value)

func _on_overall_volume_value_changed(value):
	Global.setting_changed.emit(AudioPlayerPool.OVERALL_VOLUME_PCT, AudioPlayerPool.audio_config.get_config(AudioPlayerPool.OVERALL_VOLUME_PCT), value)

func refresh():
	find_child("SfxVolume").value = AudioPlayerPool.audio_config.get_config(AudioPlayerPool.SFX_VOLUME_PCT)
	find_child("MusicVolume").value = AudioPlayerPool.audio_config.get_config(AudioPlayerPool.MUSIC_VOLUME_PCT)
	find_child("OverallVolume").value = AudioPlayerPool.audio_config.get_config(AudioPlayerPool.OVERALL_VOLUME_PCT)