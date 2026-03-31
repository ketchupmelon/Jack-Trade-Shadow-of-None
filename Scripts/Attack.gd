extends Node2D
class_name Attack

#reference
@export var summoner: Node2D

#behavior
@export var damage: int
@export var animName: String
@export var knockback: Force
@export var duration: float

#settings
@export var hitboxSize: Vector2
@export var hitboxOffset: Vector2
@export var hitboxParent: Node2D
@export var startVel: Force
@export var hitVFX: String
@export var startVFX: Array #[name, offset, direction]
@export var hitVFXParent: Node2D
@export var colorInd: int = -1

#tracking
var startTime: int
var hitbox: Area2D
var ignoreList = {}
var enabled: bool = true

func _init(atkSummoner, 
atkDamage = 0, 
atkAnimName = "none", 
atkKnockback = Force.new(), 
atkDuration = -1.0, 
atkHitboxSize = Vector2(5.0, 5.0), 
atkHitboxOffset = Vector2.ZERO,
atkStartVel = Force.new(),
hitVFXp = "",
startVFXp = [],
hitboxParentp = null,
hitVFXParentp = null) -> void:
	summoner = atkSummoner
	damage = atkDamage
	animName = atkAnimName
	knockback = atkKnockback
	duration = atkDuration
	hitboxSize = atkHitboxSize
	hitboxOffset = atkHitboxOffset
	hitboxParent = hitboxParentp if hitboxParentp else summoner
	startVel = atkStartVel
	hitVFX = hitVFXp
	hitVFXParent = hitVFXParentp
	startVFX = startVFXp
	ignoreList.set(summoner, true)
	
func Start():
	hitbox = Area2D.new()
	var box = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	hitbox.position = ((hitboxSize/2) + hitboxOffset)
	hitbox.position.y -= hitboxSize.y / 2
	hitbox.position.x *= summoner.lookDirection
	hitbox.set_collision_layer_value(1, true)
	hitbox.set_collision_mask_value(1, true)
	hitbox.set_collision_mask_value(2, true)
	hitbox.set_collision_mask_value(3, true)
	shape.size = hitboxSize
	box.shape = shape
	
	hitbox.add_child(box)
	hitboxParent.add_child(hitbox)
	
	startTime = Time.get_ticks_msec()
	
	if startVFX.size() > 0:
		startVFX[1].x *= startVFX[2]
		VFXHandler.ShowVFX(startVFX[0], startVFX[1], summoner, startVFX[2])
	
	#if not summoner.is_in_group("Player") and not summoner.is_in_group("Snatcher"):
		#summoner.get_node("AnimatedSprite2D").play(animName)
		#var animPlayer = summoner.get_node("AnimationPlayer") if summoner is Player else summoner.get_node("AnimatedSprite2D")
		#animPlayer.play(animName)
	
func GetStatus() -> int:
	if not enabled:
		return 2
	elif duration != -1.0 and Time.get_ticks_msec() - startTime >= (duration * 1000):
		return 1 #hitbox expired
	else:
		return 0
		
func Delete():
	hitbox.queue_free()
	queue_free()
	
func Update(autoDelete: bool = false):
	var status = GetStatus()
	
	if status:
		match status:
			1:
				if autoDelete:
					Delete()
		return
		
	for body in hitbox.get_overlapping_bodies():
		if not ignoreList.get(body):
			ignoreList.set(body, true)
			
			var targetIsPlr = body.is_in_group("Player")
			var targetIsEnemy = body.is_in_group("Enemies")
			
			if (targetIsEnemy and summoner.is_in_group("Player")) or (targetIsPlr and summoner.is_in_group("Enemies")):
				var endAfter: bool 
				var isSnatcher: bool
				
				if summoner.is_in_group("Player") and body.is_in_group("Enemies"):
					isSnatcher = hitboxParent.is_in_group("Snatcher")
					
					if isSnatcher:
						if body.defeated:
							continue
						if enabled:
							enabled = false
							hitboxParent.lookDirection *= -1
						
						if not body.isWeak:
							#if not Input.is_action_pressed("BringToward"):
							body.emit_signal("BringTowards")
							#else:
								#summoner.emit_signal("BringTowards", body)
						else:
							hitboxParent.landed = true
							endAfter = true
							summoner.emit_signal("SnatchEnd", "Success", body)
							
						
					#knockback.vel.x += ((50.0 * knockback.xDirect) * count)
				knockback.xDirect = summoner.lookDirection
				if body.TakeDamage(damage, knockback.duplicate(), isSnatcher, colorInd):
					VFXHandler.ShowVFX(hitVFX, body.global_position if hitVFXParent else Vector2.ZERO, hitVFXParent if hitVFXParent else body, 1)
				AudioPlayer.play("Sounds/Hit.wav", summoner)
				if endAfter:
					return
			
