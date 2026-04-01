extends TextureRect

var bar: ProgressBar

signal Cooldown(dur: float)

func OnCooldown(dur: float):
	bar.visible = true
	bar.value = 0.0
	
	var t = create_tween()
	t.tween_property(bar, "value", 100.0, dur)
	
	await t.finished
	
	bar.visible = false
	
	var clone = duplicate()
	clone.name = "WildC"
	clone.z_index -= 1
	
	get_parent().add_child(clone)
	
	t = create_tween()
	t.tween_property(clone, "scale", Vector2(5.0, 5.0), 0.2)
	t.parallel().tween_property(clone, "modulate", Color(1,1,1,0), 0.2)
	
	await t.finished
	
	clone.queue_free()

func _ready() -> void:
	bar = $ProgressBar
	Cooldown.connect(OnCooldown)
