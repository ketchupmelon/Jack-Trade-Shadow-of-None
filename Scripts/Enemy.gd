extends CharacterBody2D
class_name Enemy

@export var health: int
@export var speed: int
@export var dangerLevel: float
@export var outlineColor: int
@export var noAttack: bool
@export var firstTutor: bool

@export var lookDirection: int
@export var isWeak: bool
@export var attacking: bool
@export var defeated: bool
@export var target: Player

@export var vels: Array

@export var rewards: Array[int] = [0,0,0]

var sprite: AnimatedSprite2D
var outline: Sprite2D
var pauseGravity: bool
var bar: ProgressBar
var canvas: CanvasLayer

signal BringTowards

func _ready() -> void:
	add_to_group("Enemies")
	
	canvas = get_parent().get_parent().get_node("Camera2D/CanvasLayer")
	sprite = $AnimatedSprite2D
	outline = Sprite2D.new()
	outline.z_index = z_index - 1
	outline.scale = Vector2(1.2, 1.2)
	var color = Color(10,10,10,10)
	color.v = 50.0
	outline.modulate = color
	
	var m = ShaderMaterial.new()
	m.shader = load("res://Resources/" + str(outlineColor) + ".gdshader")
	outline.material = m
	
	add_child(outline)
	bar = get_parent().get_parent().get_node("Camera2D/CanvasLayer/WaveStuff/Wave/ProgressBar")
	
	sprite.play("run")
	
	BringTowards.connect(OnBringTowards)
	
	if not firstTutor:
		#randomly assigning the amount of cards for each color
		for colorInd in range(0,3):
			rewards[randi_range(0,2)] += 1
	else:
		rewards = [1,1,1]
	
func _physics_process(_delta: float) -> void:
	outline.flip_h = sprite.flip_h
	outline.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		
func OnBringTowards():
	pauseGravity = true
	var t = create_tween()
	t.tween_property(self, "global_position", target.global_position + Vector2(50.0 * target.lookDirection, 0.0), 0.15)
	await t.finished
	pauseGravity = false
	
func OnDeath():
	VFXHandler.ShowVFX("Spark", global_position, get_parent())
	queue_free()
	
func Weakend():
	isWeak = true
	sprite.play("open")

func TakeDamage(damage: int, knockback: Force, isSnatcher: bool = false, cInd: int = -1) -> bool:
	#target.emit_signal("UpdateCombo")
	
	if isWeak and isSnatcher:
		return true
		
	if cInd == (outlineColor - 1):
		damage *= 2
		AudioPlayer.play("Sounds/Critical.wav", self)
		VFXHandler.ShowVFX("Boom", global_position, get_parent(), 1, 1.0, Globals.globalVars.get("COLORS")[outlineColor-1])
		VFXHandler.ShowDmgStatus(canvas, "Critical", self)
	else:
		@warning_ignore("integer_division")
		damage = damage/2
		VFXHandler.ShowDmgStatus(canvas, "Weak", self)
		
	var old = health
	
	health = clamp(health - damage, 0, health)
	
	if health > 0:
		modulate = Color(10,1,1,1)
		create_tween().tween_property(self, "modulate", Color(1,1,1,1), 0.3)
	else:
		Weakend()
		
	bar.value -= (old - health)
	
	vels.append(knockback)
	
	return true

func ChaseTarget(delta: float):
	if outlineColor != 2:
		if not is_on_floor():
			if not pauseGravity:
				if not isWeak:
					velocity.y += (get_gravity().y * delta)
				else:
					velocity.y = 20.0
			else:
				velocity.y = 0.0
	else:
		if isWeak or target.position.y - position.y > 50.0:
			velocity.y = 50.0
		else:
			velocity.y = 0.0
				
	if not isWeak:
		if not attacking:
			sprite.play("run")
		
			var difference: float = position.x - target.position.x
			
			if difference > 0:
				lookDirection = -1
			else:
				lookDirection = 1
				
			sprite.flip_h = lookDirection == 1
			velocity.x = ((speed * lookDirection) * delta)
		else:
			velocity.x = 0.0
	else:
		modulate = Color(10,10,10,10)
		velocity.x = 0.0
	
	VelocityHandler.UpdateVel(self, delta)
	
	move_and_slide()
