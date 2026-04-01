extends CanvasLayer

var panel: Panel
var flash: Panel
var label: Label
var image: TextureRect
var moveTween: Tween
var cutscenePath: String

func SetFade(num: float):
	var t = create_tween()
	t.tween_property(panel, "modulate", Color(0,0,0,num), 1.0)
	await t.finished

func DoFlash():
	flash.modulate = Color(1,1,1,1)
	
	var t = create_tween()
	t.tween_property(flash, "modulate", Color(1,1,1,0), 1.0)
	await t.finished

func MoveImage(t: String, up: bool):
	if moveTween:
		moveTween.kill()
	
	image.texture = load(cutscenePath + t)
	image.position = Vector2.ZERO
	
	moveTween = create_tween()
	moveTween.tween_property(image, "position", Vector2(0,-90 if not up else 90), 8.0)

func _ready() -> void:
	cutscenePath = "res://Assets/UI/Cutscene/"
	
	flash = get_node("Flash")
	panel = get_node("Panel")
	label = get_node("Label")
	image = get_node("Image")
	
	await get_tree().create_timer(1.0).timeout
	
	AudioPlayer.play("Music/The Inceptive.mp3", self, true)
	
	label.text = "As legend has it, the universe has been held together by the balance of 3 types of cards."
	MoveImage("Colors.png", true)
	await SetFade(0)
	
	var cards = get_node("Cards")
	
	for c in cards.get_children():
		var t = create_tween()
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_CUBIC)
		t.tween_property(c, "position", Vector2(c.position.x, 195.0), 0.4)
		
		await get_tree().create_timer(0.2).timeout
	
	await get_tree().create_timer(5.0).timeout
	
	await SetFade(1)
	
	cards.visible = false
	
	label.text = "With these cards scattered across the universe, a force of corruption sought to seize the power of these cards."
	MoveImage("Evil King.png", true)
	await SetFade(0)
	await get_tree().create_timer(6.0).timeout
	
	await SetFade(1)
	
	label.text = "Stolen from their place, the cards were stored away into boxes and hidden in a secret chamber."
	MoveImage("Boxes.png", true)
	await SetFade(0)
	
	var stored = image.get_node("Stored")
	
	stored.visible = true
	
	for t in stored.get_children():
		create_tween().tween_property(t, "modulate", Color(1,1,1,1), 0.4)
		await get_tree().create_timer(0.2).timeout
	
	await get_tree().create_timer(5.0).timeout
	
	await SetFade(1)
	
	stored.visible = false
	
	label.text = "But one of these boxes was not so indifferent. It had casted a shadow with ambition."
	MoveImage("Box Close Up.png", false)
	await SetFade(0)
	await get_tree().create_timer(6.0).timeout
	
	await SetFade(1)
	
	var tween = create_tween()
	tween.tween_property(get_node("Music_The Inceptive_mp3"), "volume_db", -10.0, 1.0)
	AudioPlayer.play("Sounds/SnatchStart.wav", self)
	await DoFlash()
	get_node("Music_The Inceptive_mp3").stop()
	await get_tree().create_timer(1.0).timeout
	
	AudioPlayer.play("Music/Just Getting Started.mp3", self)
	
	label.text = "The shadow was able to break outside of the box, defecting from its fixed shape."
	MoveImage("Break Free.png", true)
	await SetFade(0)
	await get_tree().create_timer(6.0).timeout
	
	await SetFade(1)
	
	label.text = "The shadow was liberated from its limits and strived to pursue its ideals. It sought fight against such evil under a new identity..."
	MoveImage("Jack Approach.png", true)
	await SetFade(0)
	await get_tree().create_timer(7.0).timeout
	
	image.texture = load(cutscenePath + "Jack Approach With Pumpkin.png")
	label.text = "Jack Trade, the jack-of-all-trades, shadow of none."
	AudioPlayer.play("Sounds/Shine.wav", self)
	await DoFlash()
	await get_tree().create_timer(5.0).timeout
	
	await SetFade(1)
	tween = create_tween()
	tween.tween_property(get_node("Music_Just Getting Started_mp3"), "volume_db", -15.0, 1.0)
	await tween.finished
	
	get_tree().change_scene_to_file("res://Scenes/Places/Battle.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action("Skip"):
		get_tree().change_scene_to_file("res://Scenes/Places/Battle.tscn")
