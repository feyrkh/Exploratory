extends Control

func _ready():
	find_child("OverallVolume").value_changed.connect(_on_overall_volume_value_changed)
	find_child("SfxVolume").value_changed.connect(_on_sfx_volume_value_changed)
	find_child("MusicVolume").value_changed.connect(_on_music_volume_value_changed)
	find_child("RelaxTutorial").toggled.connect(func(val): Global.has_completed_relax_tutorial = !val)
	find_child("StruggleTutorial").toggled.connect(func(val): Global.has_completed_struggle_tutorial = !val)
	find_child("GalleryTutorial").toggled.connect(func(val):  Global.has_completed_gallery_tutorial = !val)
	find_child("SlowInitialZoom").toggled.connect(func(val):  Global.slow_initial_zoom = val)
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
	find_child("RelaxTutorial").button_pressed = !Global.has_completed_relax_tutorial
	find_child("StruggleTutorial").button_pressed = !Global.has_completed_struggle_tutorial
	find_child("GalleryTutorial").button_pressed = !Global.has_completed_gallery_tutorial
	find_child("SlowInitialZoom").button_pressed = Global.slow_initial_zoom
