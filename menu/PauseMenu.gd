extends Control
class_name PauseMenu

const quotes = [
	"“My heart is full of gold veins, instead of cracks.”\n– Leah Rider",
	"“Kintsugi symbolizes how we must incorporate our wounds into who we are,
	rather than try to merely repair and forget them.”\n– David Wong",
	"“Why be broken when you can be gold?”\n- Sarah Rees Brennan",
	"“The scars are the design. Your attention is drawn to the cracks and how they are mended. That is what you’re supposed to see. The beauty is in the brokenness.”\n- Justin Whitmel Earley",
	"“To become beautiful it had to break.”\n— Aura Trevortini",
	"“Your cracks can become the most beautiful part of you.”\n— Candice Kumai",
	"“Your wounds and healing are a part of your history; a part of who you are.”\n— Bryant McGill",
	"“All beautiful things carry distinctions of imperfection.”\n— Bryant McGill",
	"“Nothing lasts forever, nothing is complete, nothing is perfect.”\n– Shawzi Tsukanoto",
	"“If you’re broken, hold until each piece of you heals one again.\nLife is but a Kintsukuroi.”\n— Samara Rhea Samuel",
	"“For my poor love I cannot find repair without a balm more powerful than these.”\n— Roy Ernest Ballard",
	"“The secret to becoming unbreakable is realizing that you are already broken. We all are.”\n— Brant Menswar",
	"“I love the idea that an accident can be an occasion to make something more delightful, not less so.”\n— Ingrid Fetell Lee",
	"“Every beautiful thing is damaged. You are that beauty; we all are.”\n— Bryant McGill",
	"“I sit and pick up those pieces with their renewed essence and identities, with their flawed edges and imperfections, and join them together like Kintsugi, displaying the damages with pride.”\n— Rubina Ruhee",
	"“In repairing the object you really ended up loving it more, because you now knew its eagerness to be reassembled, and in running a fingertip over its surface you alone could feel its many cracks – a bond stronger than mere possession.”\n— Nicholson Baker",
	"“It doesn’t hide the cracks, but embraces it, seeing it as integral to the object’s history, and rebuilds something new.”\n— Sidhanta Patnaik",
	"“World is imperfect. Life is imperfect. You are imperfect. I’m imperfect. All are Kintsugi.”",
	"“I am looking forward to getting shattered only to add further elegance to myself.”\n– Aura Trevortini",
	"“There is no such thing as perfect. There is only broken, and then there is healed.”\n– Brené Brown",
	"“Your scars are not your shame, they are your strength.”",
	"“Scars are not wounds. They are proof that you have healed.”",
	"“Embrace your scars. They are part of your story.”",
	"“Scars are beautiful. They show that you’ve been through something and you’ve come out the other side.”",
]

signal close
signal save_game
signal exit_game

func _ready():
	if Global.game_mode != "relax":
		find_child("QuitAndSaveButton").visible = false
		find_child("QuitAndDiscardButton").text = "Quit"
	find_child("SfxVolume").value = AudioPlayerPool.audio_config.get_config(AudioPlayerPool.SFX_VOLUME_PCT)
	find_child("MusicVolume").value = AudioPlayerPool.audio_config.get_config(AudioPlayerPool.MUSIC_VOLUME_PCT)
	find_child("OverallVolume").value = AudioPlayerPool.audio_config.get_config(AudioPlayerPool.OVERALL_VOLUME_PCT)
	find_child("QuoteLabel").text = quotes.pick_random()
	get_tree().paused = true

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_return_button_pressed()
		get_viewport().set_input_as_handled()

func _on_return_button_pressed():
	get_tree().paused = false
	close.emit()
	queue_free()
	Global.play_button_click_sound("menu_back")

func _on_quit_and_discard_button_pressed():
	get_tree().paused = false
	close.emit()
	exit_game.emit()

func _on_quit_and_save_button_pressed():
	get_tree().paused = false
	close.emit()
	save_game.emit()
	exit_game.emit()

func _on_sfx_volume_value_changed(value):
	Global.setting_changed.emit(AudioPlayerPool.SFX_VOLUME_PCT, AudioPlayerPool.audio_config.get_config(AudioPlayerPool.SFX_VOLUME_PCT), value)

func _on_music_volume_value_changed(value):
	Global.setting_changed.emit(AudioPlayerPool.MUSIC_VOLUME_PCT, AudioPlayerPool.audio_config.get_config(AudioPlayerPool.MUSIC_VOLUME_PCT), value)

func _on_overall_volume_value_changed(value):
	Global.setting_changed.emit(AudioPlayerPool.OVERALL_VOLUME_PCT, AudioPlayerPool.audio_config.get_config(AudioPlayerPool.OVERALL_VOLUME_PCT), value)
