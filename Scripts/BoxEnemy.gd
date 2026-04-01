extends Enemy

@export var attackEvery: float = 0.5 #seconds
var elapsed: float = 0.0
var currAttack: Attack

func PendSpikes():
	await get_tree().create_timer(0.5).timeout
	
	if isWeak:
		return
	
	Projectile.SpawnProj("BoxSpikes", self, Vector2(50.0, 50.0), get_parent(), 2)

func StartAttack():
	attacking = true
	sprite.play("prepare")
	VFXHandler.ShowVFX("Glare", Vector2.ZERO, self, lookDirection)
	
	await get_tree().create_timer(1.0).timeout
	
	if isWeak:
		return
		
	match outlineColor:
		1:
			currAttack = Attack.new(self)
			
			currAttack.damage = 5
			currAttack.knockback = Force.new(Vector2(400.0, 200.0), 500.0, 500.0, true, true, -1, -1)
			currAttack.duration = 0.4
			currAttack.hitboxSize = Vector2(20.0,20.0)
			currAttack.hitboxOffset = Vector2.ZERO
			currAttack.startVel = Force.new(Vector2(350.0,0.0), 700.0, 400.0, true, not is_on_floor(), lookDirection, -1)
			currAttack.hitVFX = "Spark"
			#currAttack.startVFX = ["Spray", Vector2(10.0, 0.0), lookDirection]
			currAttack.colorInd = 0
			
			vels.append(currAttack.startVel)
			currAttack.Start()
		2:
			for i in range(0,3):
				Projectile.SpawnProj("Box", self, Vector2.ZERO, get_parent(), 2, -50.0 + (50.0*i))
		3:
			PendSpikes()
	
	sprite.play("attack")
	
	await get_tree().create_timer(0.6).timeout
	attacking = false

func _physics_process(delta: float) -> void:
	if target.health <= 0:
		return
		
	if not noAttack:
		if not isWeak and not attacking:
			elapsed += delta
			
			if elapsed >= attackEvery:
				elapsed = 0.0
				StartAttack()
		
		if currAttack:
			currAttack.Update(true)
	
	super(delta)
	ChaseTarget(delta)
