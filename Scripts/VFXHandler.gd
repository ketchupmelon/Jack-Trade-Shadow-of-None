class_name VFXHandler

static var folder = "res://Scenes/VFX/"

static func ShowVFX(sceneName: String, position: Vector2, parent: Node2D, direction: int = 1, tScale: float = 1.0, mod: Color = Color(1.0, 1.0, 1.0)):
	var vfx = load(folder + sceneName + ".tscn").instantiate()
	vfx.modulate = mod
	vfx.position = position
	
	var sprite = vfx.get_node_or_null("AnimatedSprite2D")
	
	if sprite:
		sprite.flip_h = direction == -1
	else:
		vfx.get_node("Sprite2D").flip_h = direction == -1
		
		if vfx.name == "ShadowHand":
			vfx.summoner = parent.get_node("Player")
	
	parent.add_child(vfx)
	
	var p = vfx.get_node_or_null("AnimationPlayer")
	
	if p:
		p.speed_scale = tScale
		p.play("default")
		await p.animation_finished
		vfx.queue_free()
		
static func ShowDmgStatus(canvas: CanvasLayer, name: String, body: Enemy):
	var pos = body.get_global_transform_with_canvas().get_origin()
	var vfx = canvas.get_node(name).duplicate()
	
	vfx.position = pos
	
	canvas.add_child(vfx)
	
	var tween = vfx.create_tween()
	var mod = vfx.modulate
	tween.tween_property(vfx, "position", vfx.position + Vector2(-vfx.size.x/2.0, 20.0), 0.4)
	tween.parallel().tween_property(vfx, "modulate", Color(mod.r, mod.g, mod.b, 0.0), 0.5)
	tween.parallel().tween_property(vfx, "scale", Vector2(2.0, 2.0), 0.4)
	
	await vfx.get_tree().create_timer(0.5).timeout
	
	vfx.queue_free()
