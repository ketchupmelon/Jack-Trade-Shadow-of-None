extends Button

func _pressed() -> void:
	AudioPlayer.play("Sounds/UISelect.wav", self)
	
	var parent = get_parent()
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(parent, "position", Vector2(700.0, 696.0), 0.4)
	await t.finished
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(parent.get_parent().get_node("Highscores"), "position", Vector2(700.0, 480.0), 0.4)
