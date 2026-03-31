extends Node2D
class_name Projectile

@export var summoner: Node2D
@export var colorInd: int = -1
@export var speed: float
@export var ySpeed: float
@export var knockback: Force
@export var direction: int
@export var hitVFX: String
@export var damage: int
@export var lifeTime: float
@export var upDamp: float
@export var ignoreFadeHit: bool
@export var keepOnHit: bool
@export var isBoomerang: bool

var hitbox: Area2D
var elapsed: float
var deleting: bool
var targetsHit = {}
var otherWay: bool

static func SpawnProj(projName: String, s: Node2D, offset: Vector2 = Vector2.ZERO, p: Node2D = null, cInd: int = -1, ys: float = 0.0):
	var proj = load("res://Scenes/Projectiles/" + projName + ".tscn").instantiate()
	var parent = p if p else s.get_parent()
	var sprite = proj.get_node("AnimatedSprite2D")
	
	offset.x *= s.lookDirection
	
	proj.summoner = s
	proj.global_position = s.global_position + offset
	proj.direction = s.lookDirection
	sprite.flip_h = proj.direction == -1
	proj.colorInd = cInd
	proj.ySpeed = ys
	
	parent.add_child(proj)
	
	sprite.play("default")

func OnBodyEnter(body):
	if (deleting and ignoreFadeHit) or (not summoner or not body):
		return
	
	if body != summoner and ((body.is_in_group("Player") and summoner.is_in_group("Enemies")) or (body.is_in_group("Enemies")) and summoner.is_in_group("Player")):
		if not targetsHit.get(body):
			knockback.xDirect = -body.lookDirection
			
			if body.TakeDamage(damage, knockback, false, colorInd):
				targetsHit.set(body, true)
				AudioPlayer.play("Sounds/Hit.wav", body)
				VFXHandler.ShowVFX(hitVFX, body.global_position, get_parent(), direction)
			
				if not keepOnHit:
					queue_free()

func _ready() -> void:
	self.remove_child(knockback)
	$Area2D.body_entered.connect(OnBodyEnter)
	
func _physics_process(delta: float) -> void:
	elapsed += delta
	
	if isBoomerang:
		if speed <= 0 and not otherWay:
			otherWay = true
			targetsHit.clear()
		
		speed -= (400.0 * delta)
	
	if not deleting and elapsed >= lifeTime:
		deleting = true
		
		var t = create_tween()
		t.tween_property(self, "modulate", Color(1,1,1,0),0.5)
		await t.finished
		queue_free()
	
	if upDamp == 0.0:
		position.x += (speed * direction) * delta
		position.y += (ySpeed * direction) * delta
	else:
		if speed > 0.0:
			position.y -= (speed * delta)
			speed -= (upDamp * delta)
