extends CanvasLayer

var panel: Panel
var suggestion: Panel
var jack: TextureRect
var background: TextureRect
var buttonsPanel: Panel

func DoTween():
	while true:
		var t = create_tween()
		t.set_ease(Tween.EASE_IN_OUT)
		t.set_trans(Tween.TRANS_CUBIC)
		t.tween_property(jack, "scale", Vector2(1.05, 1.05), 2.0)
		t.parallel().tween_property(jack, "rotation_degrees", -3.0, 2.0)
		t.parallel().tween_property(background, "scale", Vector2(1.05, 1.05), 2.0)
		
		await t.finished
		
		t.kill()
		
		t = create_tween()
		t.set_ease(Tween.EASE_IN_OUT)
		t.set_trans(Tween.TRANS_CUBIC)
		t.tween_property(jack, "scale", Vector2(1.0, 1.0), 2.0)
		t.parallel().tween_property(jack, "rotation_degrees", 2.0, 2.0)
		t.parallel().tween_property(background, "scale", Vector2(1.0, 1.0), 2.0)
		
		await t.finished
		
		t.kill()

func _ready() -> void:
	panel = get_node("Panel")
	suggestion = panel.get_node("Suggestion")
	jack = get_node("Jack")
	background = get_node("Background")
	buttonsPanel = get_node("ButtonsPanel")
	
	var highscores = get_node("Highscores")
	
	highscores.get_node("Waves/Amount").text = str(Globals.globalVars.get("HighWaves"))
	highscores.get_node("Defeated/Amount").text = str(Globals.globalVars.get("HighEnemies"))
	highscores.get_node("Obtained/Amount").text = str(Globals.globalVars.get("HighCards"))
	
	AudioPlayer.play("Sounds/Wind.mp3", self, true)
	
	await get_tree().create_timer(1.0).timeout
	
	suggestion.visible = true
	
	var suggestTween = create_tween()
	suggestTween.tween_property(suggestion, "modulate", Color(1,1,1,1), 1.0)
	suggestTween.parallel().tween_property(suggestion, "scale", Vector2(1.2, 1.2), 10.0)
	
	await get_tree().create_timer(5.0).timeout
	
	suggestTween = create_tween()
	suggestTween.tween_property(suggestion, "modulate", Color(1,1,1,0), 1.0)
	
	await suggestTween.finished
	
	suggestion.visible = false
	
	await get_tree().create_timer(1.0).timeout
	
	AudioPlayer.play("Music/Still Shade.mp3", self, true)
	
	DoTween()
	
	var t = create_tween()
	t.tween_property(panel, "modulate", Color(0,0,0,0), 1.0)
	t.parallel().tween_property(get_node("Sounds_Wind_mp3"), "volume_db", -10.0, 1.0)
	
	await t.finished
	
	get_node("Sounds_Wind_mp3").stop()
	
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(get_node("Title"), "position", Vector2(509.0, 77.0), 1.0)
	
	await t.finished
	
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(jack, "position", Vector2(72.0, 27.0), 1.0)
	
	await t.finished
	await get_tree().create_timer(1.0).timeout
	
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(buttonsPanel, "position", Vector2(700.0, 480.0), 0.4)
