extends Button

func _pressed() -> void:
	disabled = true
	
	AudioPlayer.play("Sounds/UISelect.wav", self)
	
	var parent = get_parent()
	
	if name != "Play":
		var t = create_tween()
		
		t.tween_property(parent.get_node("FadePanel"), "modulate", Color(0,0,0,1), 1.0)
		
		await t.finished
	
	var d: String
	
	match name:
		"Restart":
			parent.get_node("MainMenu").disabled = true
			d = "res://Scenes/Places/Battle.tscn"
		"MainMenu":
			parent.get_node("Restart").disabled = true
			d = "res://Scenes/Places/MainMenu.tscn"
		"Play":
			var p = parent.get_parent()
			var background = p.get_node("Background")
			var jack = p.get_node("Jack")
			var tween = create_tween()
			
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.set_ease(Tween.EASE_OUT)
			
			background.modulate *= 10
			
			tween.tween_property(background, "modulate", Color.from_rgba8(255,130,0,255), 0.4)
			tween.parallel().tween_property(p.get_node("Title"), "position", Vector2(509.0, -406.0), 0.4)
			tween.parallel().tween_property(p.get_node("ButtonsPanel"), "position", Vector2(700.0, 660.0), 0.4)
			
			await tween.finished
			
			tween = create_tween()
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(jack, "position", Vector2(305.0, 27.0), 1.0)
			tween.parallel().tween_property(background, "modulate", Color(10,10,10,10), 5.0)
			
			await get_tree().create_timer(1.0).timeout
			
			jack.get_node("Glare/AnimationPlayer").play("default", -1, 0.8)
			AudioPlayer.play("Sounds/Shine.wav", self)
			
			await get_tree().create_timer(1.0).timeout
			
			tween = create_tween()
			tween.tween_property(p.get_node("Panel"), "modulate", Color(0,0,0,1), 1.0)
			tween.parallel().tween_property(p.get_node("Music_Still Shade_mp3"), "volume_db", -10.0, 1.0)
			
			await tween.finished
			
			d = "res://Scenes/Places/Intro.tscn"
		
	get_tree().change_scene_to_file(d)
