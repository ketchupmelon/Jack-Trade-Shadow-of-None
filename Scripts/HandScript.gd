extends Node2D

@export var summoner: Player

var parent: Node2D
var sprite: Sprite2D
var attack: Attack
@export var lookDirection: int
@export var landed: bool

var max_dist: int
var speed: int

var startPos: Vector2
var initDirect: int

func PendDelete(toDelete: Node2D, after: float):
	await get_tree().create_timer(after).timeout
	toDelete.queue_free()

func _ready() -> void:
	add_to_group("Snatcher")
	
	if Globals.globalVars.get("WildName") == "Snatch Extend":
		speed = 800
		max_dist = 200
	else:
		speed = 700
		max_dist = 100
	
	sprite = $Sprite2D
	attack = Attack.new(summoner, 0, "none", Force.new(), -1.0, Vector2(20.0, 20.0), Vector2.ZERO, null, "Splash", ["Spray", Vector2(25.0, 0.0), summoner.lookDirection], self, get_parent())
	lookDirection = summoner.lookDirection
	initDirect = lookDirection
	startPos = global_position
	parent = get_parent().get_node("LayerVFX")
	
	attack.Start()

func _process(delta: float) -> void:
	var effectiveSpeed = speed * delta
	var dist: float = abs(startPos - global_position).x
	
	if visible:
		var layer = Sprite2D.new()
		layer.global_position = global_position
		layer.z_index = 0
		layer.modulate = Color(0,0,0,0.3)
		layer.flip_h = sprite.flip_h
		layer.texture = sprite.texture
		parent.add_child(layer)
		
		create_tween().tween_property(layer, "modulate", Color(0,0,0,0), 0.3)
		PendDelete(layer, 0.3)
		
		global_position += Vector2(effectiveSpeed * lookDirection, 0.0)
		
		attack.Update()
	
	if dist >= max_dist and lookDirection == initDirect:
		lookDirection *= -1
	elif lookDirection != initDirect and dist <= effectiveSpeed * 2:
		if visible:
			visible = false
			
			if not landed:
				summoner.emit_signal("SnatchEnd", "Fail")
		else:
			for vfx in parent.get_children():
				return
				
			queue_free()
