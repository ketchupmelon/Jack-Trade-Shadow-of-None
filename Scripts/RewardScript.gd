extends TextureButton

var wildNames = ["Snatch Extend", "x2 Uses", "Air Jump"]

@export var ignore: bool
@export var selected: bool
var wName: String
var plr: Player
var lastInd: int = -1

signal SetRandom

func OnClick():
	selected = true
	disabled = true
	
	AudioPlayer.play("Sounds/UISelect.wav", self)
	
	match name:
		"Wild":
			plr.emit_signal("GiveWild", wName)
		"Refill":
			plr.emit_signal("GrantRefill")
		"MoreMax":
			plr.emit_signal("IncreaseMax")
	
	for button in get_parent().get_children():
		if button.name != "Label":
			button.ignore = true
			button.disabled = true
			
			if button.name != name:
				button.TScale(Vector2(7.0, 7.0), true)
			else:
				TScale(Vector2(10.0, 10.0))
				
	var clone = duplicate()
	clone.name = "Effect"
	get_parent().add_child(clone)
	
	var t = create_tween()
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(clone, "scale", Vector2(12.0, 12.0), 0.3)
	t.parallel().tween_property(clone, "modulate", Color(1,1,1,0), 0.3)
	
	await t.finished
	
	clone.queue_free()
	
	plr.emit_signal("RewardChosen")

func TScale(s: Vector2, gray: bool = false):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", s, 0.3)
	
	if gray:
		tween.parallel().tween_property(self, "modulate", Color.from_rgba8(128, 128, 128, 255), 0.3)

func OnEnter():
	if not ignore:
		TScale(Vector2(9.0, 9.0))

func OnExit():
	if not ignore:
		TScale(Vector2(8.0, 8.0))

func RandomizeCard():
	var ind = randi_range(0,wildNames.size()-1)
		
	if ind == lastInd:
		ind -= 1
		
		if ind < 0:
			ind = wildNames.size()-1
	
	wName = wildNames[ind]
	lastInd = ind
	
	get_node("CardName").text = wName
	get_node("Image").texture = load("res://Assets/UI/Cards/Details/" + wName + ".png")

func _ready():
	plr = get_parent().get_parent().get_parent().get_parent().get_node("Player")
	
	pressed.connect(OnClick)
	mouse_entered.connect(OnEnter)
	mouse_exited.connect(OnExit)
	
	if name == "Wild":
		SetRandom.connect(RandomizeCard)
