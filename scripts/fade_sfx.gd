class_name FadeSFXPlayer extends AudioStreamPlayer

@export var fade_dur: float = 1.0

func _fade_vol(start: float, end: float, dur: float) -> void:
	var diff := absf(end - start)
	fade_tween.tween_method(set_volume_linear, start, end, dur * diff)

var fade_tween: Tween
func fade_start(dur := -1.0) -> void:
	if dur <= 0.0: dur = fade_dur
	if playing: return
	if fade_tween:
		fade_tween.kill()
	volume_linear = 0.0
	playing = true
	fade_tween = create_tween()
	_fade_vol(0.0, 1.0, dur)
	await fade_tween.finished

func fade_end(dur := -1.0) -> void:
	if dur <= 0.0: dur = fade_dur
	if not playing: return
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	_fade_vol(volume_linear, 0.0, dur)
	fade_tween.tween_callback(set_playing.bind(false))
	await fade_tween.finished
