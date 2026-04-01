extends CharacterBody2D
class_name Player

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const BOSS_EVERY = 5 #waves
const COMBO_DROP = 2000 #milliseconds

#FOR ANIMATIONS
var states = { #must match name of corresponding animation, higher takes priority
	"Shield Blitz" = false,
	Burst = false,
	ProjFire = false,
	Bash = false,
	SnatchLoop = false,
	Snatch = false,
	BasicAtk2 = false,
	BasicAtk1 = false,
	Dash = false,
	Fall = false,
	Jump = false,
	Run = false,
	Idle = true
}
var animData = {
	Dash = {
		once = true,
		playAfter = "none"
	},
	Jump = {
		once = true,
		playAfter = "Fall"
	},
	BasicAtk1 = {
		once = true,
		playAfter = "none"
	},
	BasicAtk2 = {
		once = true,
		playAfter = "none"
	},
	Snatch = {
		once = true,
		playAfter = "SnatchLoop"
	},
	Bash = {
		once = true,
		playAfter = "none"
	},
	ProjFire = {
		once = true,
		playAfter = "none"
	},
	Burst = {
		once = true,
		playAfter = "none"
	},
	"Shield Blitz" = {
		once = true,
		playAfter = "none"
	}
}
var playHistory = {}

#FOR ATTACKS
var currAttack: Attack
var attackState: int = 1
var canQueue: bool = true
var queued: bool = false
var lastAttack: int
var lastHit: int

#FOR PHYSCIS
@export var vels: Array
var currForce: Force

#FOR CARDS
var CARD_COLORS
var cards = [
	#red
	[],
	
	#green
	[],
	
	#blue
	[]
]
var maxCards: int
var lastWings: int

#FOR HEALTH
var maxHealth: float = 100.0
@export var health: float = maxHealth
var lastHealth: float = health
var shakingBar: bool

#tracking
@export var lookDirection: int = 1
@export var attacking: bool = false
var pointInd: int = 1
var snatchTarget: Enemy
var danger: float = 0.0
var dangerGoal: float = 500.0
var dangerRate: float = 0.0
var trapTween: Tween
var waveTrans: bool
var combo: int
var comboDrain: float
var airTime: float
var canDash: bool = true
var enemiesDefeated: int
var cardsObtained: int

#objects
@export var camera: Camera2D
var canvas: CanvasLayer
var healthBar: ProgressBar
var dangerBar: ProgressBar
var comboBar: ProgressBar
var comboLabel: Label
var animPlayer: AnimationPlayer
var sprite: AnimatedSprite2D
var maps: Node2D

#signals
signal SnatchEnd(status: String, body: Node2D)
signal BringTowards(body: Enemy)
signal GiveWild(n: String)
signal GrantRefill
signal IncreaseMax
signal RewardChosen
signal UpdateCombo

func SetState(state: String, to: bool, resetHistory: bool = false):
	if resetHistory:
		playHistory.erase(state)
	states.set(state, to)
	
func CanAct() -> bool:
	return not waveTrans and not attacking and danger >= 0.0
	
func OnBringTowards(body: Enemy):
	var t = create_tween()
	t.tween_property(self, "global_position", body.global_position + Vector2(50.0 * body.lookDirection, 0.0), 0.15)
	await t.finished
	velocity.y = 0.0
	
func OnGiveWild(n: String):
	var c = canvas.get_node("CardSelect/Wild")
	
	Globals.globalVars.set("WildName", n)
	
	c.get_node("Image").texture = load("res://Assets/UI/Cards/Details/" + n + ".png")
	c.get_node("Label").text = n
	c.visible = true
	
	match n:
		"x2 Uses":
			for coloredCards in cards:
				for card in coloredCards:
					card.uses *= 2
					card.maxUses *= 2
			
			UpdateCards()

func OnMaxIncrease():
	maxCards += 1
	
func OnRefill():
	for i in range(0,3):
		
		while cards[i].size() < maxCards:
			cards[i].append(Card.DrawRandCardFromColorInd(i))
			
	UpdateCards()
	
func StartQueue() -> bool:
	if canQueue and not queued:
		queued = true
		
		var start = Time.get_ticks_msec()
		
		while get_tree() and Time.get_ticks_msec() - start <= 300 and not CanAct():
			await get_tree().process_frame
			
		queued = false
			
		return Time.get_ticks_msec() - start <= 300
	else:
		return false
	
func PerformAttack(atkName: String):
	if not CanAct() and not await StartQueue():
		return
	#if not CanAct():
		#if canQueue and not queued:
			#queued = true
			#
			#while not CanAct():
				#await get_tree().process_frame
				#
			#queued = false
		#else:
			#return
	
	attacking = true
	lastAttack = Time.get_ticks_msec()
	
	var attack = Attack.new(self)
	
	match atkName:
		"M1":
			attack.damage = 5
			attack.animName = "BasicAtk" + str(attackState)
			attack.knockback = Force.new(Vector2(305.0, 50.0 if is_on_floor() else 120.0), 500.0, 500.0, true, true, -1, -1)
			attack.duration = 0.4
			attack.hitboxSize = Vector2(25.0, 10.0)
			attack.hitboxOffset = Vector2.ZERO
			attack.startVel = Force.new(Vector2(350.0, 100.0 if not is_on_floor() else 0.0), 700.0, 400.0, true, not is_on_floor(), lookDirection, -1)
			attack.hitVFX = "Spark"
			attack.startVFX = ["Spray", Vector2(10.0, 0.0), lookDirection]
			
			attackState += 1
			
			if attackState > 2:
				attackState = 1
		"Bash":
			attack.damage = 10
			attack.animName = "Bash"
			attack.knockback = Force.new(Vector2(400.0, 200.0), 500.0, 500.0, true, true, -1, -1)
			attack.duration = 0.4
			attack.hitboxSize = Vector2(25.0, 10.0)
			attack.hitboxOffset = Vector2.ZERO
			attack.startVel = Force.new(Vector2(350.0,0.0), 700.0, 400.0, true, not is_on_floor(), lookDirection, -1)
			attack.hitVFX = "Spark"
			attack.startVFX = ["Spray", Vector2(10.0, 0.0), lookDirection]
			attack.colorInd = 0
		"Burst":
			attack.damage = 20
			attack.animName = "Burst"
			attack.knockback = Force.new(Vector2(500.0, 400.0), 700.0, 700.0, true, true, -1, -1)
			attack.duration = 0.4
			attack.hitboxSize = Vector2(75.0, 75.0)
			attack.hitboxOffset = Vector2(-attack.hitboxSize.x / 2.0, 0.0)
			attack.startVel = Force.new(Vector2(0.0,50.0), 0.0, 150.0, true, true, lookDirection, -1)
			attack.hitVFX = "Spark"
			attack.startVFX = ["Splash", Vector2(0.0, 0.0), lookDirection]
			attack.colorInd = 2
			
			VFXHandler.ShowVFX("Boom", position, get_parent(), 1)
		"Shield Blitz":
			attack.damage = 10
			attack.animName = "Shield Blitz"
			attack.knockback = Force.new(Vector2(400.0, 200.0), 500.0, 500.0, true, true, -1, -1)
			attack.duration = 0.3
			attack.hitboxSize = Vector2(25.0, 10.0)
			attack.hitboxOffset = Vector2.ZERO
			attack.startVel = Force.new(Vector2(500.0,0.0), 700.0, 400.0, true, true, lookDirection, -1)
			attack.hitVFX = "Splash"
			attack.startVFX = ["Spray", Vector2(10.0, 0.0), lookDirection]
			attack.colorInd = 2
			
	attack.Start()
	vels.append(attack.startVel)
	animPlayer.stop()
	SetState(attack.animName, true, true)
	
	currAttack = attack
	
	await get_tree().create_timer(currAttack.duration).timeout
	
	if currAttack:
		currAttack.Delete()
	
	attacking = false
	
func StartSnatch():
	if not CanAct() and not await StartQueue():
		return
	
	attacking = true
	SetState("Snatch", true, true)
	
	currForce = Force.new(Vector2(50.0, 0.0), 0.0, 0.0, true, true, 1 * lookDirection, 1)
	
	vels.append(currForce)
	
	AudioPlayer.play("Sounds/SnatchStart.wav", self)
	
	await get_tree().create_timer(0.2).timeout
	
	VFXHandler.ShowVFX("ShadowHand", global_position + Vector2(12.0 * lookDirection, 0.0), get_parent(), lookDirection)

func Slowmo(dur: float):
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_ignore_time_scale(true)
	t.tween_property(Engine, "time_scale", 0.2, 0.3)
	await t.finished
	await get_tree().create_timer(dur, true, false, true).timeout
	var t2 = create_tween()
	t2.set_ease(Tween.EASE_IN)
	t2.set_trans(Tween.TRANS_CUBIC)
	t2.set_ignore_time_scale(true)
	t2.tween_property(Engine, "time_scale", 1.0, 0.3)
	
func ShakeCam(dur: float):
	var start: int = Time.get_ticks_msec()
	
	while Time.get_ticks_msec() - start <= (dur * 1000):
		camera.offset = Vector2(randf_range(-3.0,3.0), randf_range(-3.0,3.0))
		await get_tree().process_frame
	
func PendVanish(card):
	await get_tree().create_timer(1.0, true, false, true).timeout
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "position", card.position - Vector2(12.0 * card.get_meta("d"), 0.0), 0.2)
	tween.parallel().tween_property(card, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.2)
	
	await tween.finished
	
	card.queue_free()

func OnSnatchEnd(status: String, body: Node2D = null):
	var waveCleared: bool
	
	match status:
		#"Fail":
			#print("failed")
		"Success":
			var colorInd = -1
			var rewarded = [0, 0, 0]
			
			enemiesDefeated += 1
			
			AudioPlayer.play("Sounds/SnatchSuccess.wav", self)
			TakeDamage(-5.0)
			
			for amount in body.rewards:
				colorInd += 1
				
				#giving the cards
				for i in range(0,amount):
					if cards[colorInd].size() < maxCards:
						cards[colorInd].append(Card.DrawRandCardFromColorInd(colorInd))
						rewarded[colorInd] += 1
						cardsObtained += 1
					else:
						#print(str(colorInd) + " is full")
						break
			
			UpdateCards()
			
			#TakeDamage(-15.0)
			
			Globals.globalVars.set("Defeated", Globals.globalVars.get("Defeated") + 1)
			canvas.get_node("WaveStuff/Wave/Progress").text = "(" + str(Globals.globalVars.get("Defeated")) + "/" + str(Globals.globalVars.get("WaveGoal")) + ")"
			
			waveCleared = Globals.globalVars.get("Defeated") == Globals.globalVars.get("WaveGoal")
			
			body.defeated = true
			dangerRate -= body.dangerLevel
			snatchTarget = body
			
			VFXHandler.ShowVFX("Boom", body.position, body.get_parent(), 1, 1.0 / 0.1)
			ShakeCam(0.2)
			var t = create_tween().bind_node(body)
			t.tween_property(body, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.1)
			t.parallel().tween_property(body, "scale", Vector2(2.0, 2.0), 0.1)
			
			var zoomTween = create_tween()
			zoomTween.set_ignore_time_scale(true)
			zoomTween.set_ease(Tween.EASE_OUT)
			zoomTween.set_trans(Tween.TRANS_CUBIC)
			zoomTween.tween_property(camera, "zoom", Vector2(5.0, 5.0), 0.2)
			
			Engine.time_scale = 0.1
			
			colorInd = 0
			
			var start = Time.get_ticks_msec()
			var offCount: int = 0
		
			for amount in rewarded:
				colorInd += 1
				
				if amount == 0:
					continue
				
				#showing the granted cards
				var gain = get_node("CardGain").duplicate()
				gain.visible = true
				gain.name = "Gain" + str(colorInd)
				gain.texture = canvas.get_node("CardSelect/" + str(colorInd)).texture
				gain.get_node("Label").text = "+" + str(amount)
				gain.position = Vector2(0.0, -15.0 * offCount)
				gain.set_meta("d", lookDirection)
				add_child(gain)
				
				var tween = create_tween()
				tween.set_ignore_time_scale(true)
				tween.set_trans(Tween.TRANS_CUBIC)
				tween.set_ease(Tween.EASE_OUT)
				tween.tween_property(gain, "position", gain.position + Vector2(25.0 * lookDirection, 0.0), 0.3)
				
				await get_tree().create_timer(0.1, true, false, true).timeout
				
				PendVanish(gain)
				
				offCount += 1
				
			while Time.get_ticks_msec() - start <= 300:
				await get_tree().process_frame
			
			var zoomTween2 = create_tween()
			zoomTween2.set_ease(Tween.EASE_OUT)
			zoomTween2.set_trans(Tween.TRANS_CUBIC)
			zoomTween2.set_ignore_time_scale(true)
			zoomTween2.tween_property(camera, "zoom", Vector2(3.0, 3.0), 0.2)
			
			Engine.time_scale = 1.0
			
			VFXHandler.ShowVFX("Particles", body.position, body.get_parent(), 1)
			
			vels.append(Force.new(Vector2(300.0, 100.0), 500.0, 500.0, false, false, -lookDirection, -1))
			
			if waveCleared:
				Slowmo(0.5)
			
			await t.finished
			
			snatchTarget = null
			
			body.queue_free()
	
	SetState("Snatch", false)
	SetState("SnatchLoop", false)
	attacking = false
	
	vels.remove_at(vels.find(currForce))
	
	if waveCleared:
		await get_tree().create_timer(1.0).timeout
		NextWave()

func PendDelete(toDelete, after: float):
	await get_tree().create_timer(after).timeout
	toDelete.queue_free()
	
func UpdatePointer(amount: int):
	var oldCard = canvas.get_node("CardSelect/" + str(pointInd))
	var oldPanel = oldCard.get_node("Panel")
	
	oldCard.modulate = Color(0.5, 0.5, 0.5)
	oldPanel.visible = false
	#oldCard.scale = Vector2(1.0, 1.0)
	#oldPanel.scale -= Vector2(0.1, 0.1)
	
	AudioPlayer.play("Sounds/Switch.wav", self)
	
	pointInd += amount
	
	if pointInd == 4:
		pointInd = 1
	elif pointInd == 0:
		pointInd = 3
		
	UpdateCards()
	
	var newCard = canvas.get_node("CardSelect/" + str(pointInd))
	var newPanel = newCard.get_node("Panel")
	var newColor = CARD_COLORS[pointInd - 1]
	
	#newCard.scale = Vector2(1.2, 1.2)
	#newPanel.scale += Vector2(0.1, 0.1)
	#canvas.get_node("CardSelect/Pointer").position = newCard.position + Vector2(58.0, 0.0)
	newCard.modulate = Color(1.0, 1.0, 1.0)
	canvas.get_node("CardSelect/Pointer").position = newCard.position - (newCard.size/4)
	newPanel.visible = true
	
	healthBar.modulate = newColor
	comboLabel.modulate = Color(newColor.r, newColor.g, newColor.b, comboLabel.modulate.a)
	VFXHandler.ShowVFX("Boom", Vector2.ZERO, self, 1, 1.0, newColor)

func UpdateCards():
	#setting all the cards visible to false
	for i in range(1,4):
		var panel = canvas.get_node("CardSelect/" + str(i) + "/Panel")
		
		for j in range(0,5):
			var cardTexture = panel.get_node("Card" + str(j))
			cardTexture.visible = false
	
	#showing the cards in the cards list
	for i in range(1,4):
		var panel = canvas.get_node("CardSelect/" + str(i) + "/Panel")
		var cardAmount = cards[i - 1].size()
		var excess = panel.get_node("Excess")
		var extraAmount = cardAmount - 5
		
		
		for j in range(0,clamp(cardAmount, 0, 5)):
			var cardTexture = panel.get_node("Card" + str(j))
			var curr = cards[i - 1][j]
			cardTexture.visible = true
			cardTexture.get_node("Label").text = curr.cardName
			cardTexture.get_node("Image").texture = load("res://Assets/UI/Cards/Details/" + curr.cardName + ".png")
			cardTexture.self_modulate = CARD_COLORS[i - 1]
		
		if extraAmount > 0:
			excess.text = "+" + str(extraAmount)
			excess.visible = true
		else:
			excess.visible = false
	
	if cards[pointInd - 1].size() > 0:
		var zero = canvas.get_node("CardSelect/" + str(pointInd) + "/Panel/Card0")
		var bar = zero.get_node("ProgressBar")
		var currCard = cards[pointInd - 1][0]
		var remaining = currCard.maxUses - currCard.uses
		var usesLabel = zero.get_node("Uses")
		
		bar.max_value = currCard.maxUses
		bar.value = remaining
		
		#usesLabel.text = "Uses:\n(" + str(currCard.maxUses - remaining) + "/" + str(currCard.maxUses) + ")"
		usesLabel.text = str(currCard.uses)
		usesLabel.modulate = Color(1,1,0) if Globals.globalVars.get("WildName") == "x2 Uses" else Color(1,1,1)

func CardEffect(mode: int):
	var panel = canvas.get_node("CardSelect/" + str(pointInd) + "/Panel")
	var clone = panel.get_node("Card0").duplicate()
	var t = create_tween()
	
	clone.z_index -= 1
	clone.name = "CardC"
	clone.get_node("Uses").visible = false
	clone.get_node("ProgressBar").visible = false
		
	panel.add_child(clone)
	
	if mode == 0:
		t.tween_property(clone, "modulate", Color(clone.modulate.r, clone.modulate.g, clone.modulate.b, 0.0), 0.3)
		t.parallel().tween_property(clone, "position", clone.position + Vector2(0.0, -100.0), 0.3)
	else:
		t.tween_property(clone, "modulate", Color(clone.modulate.r, clone.modulate.g, clone.modulate.b, 0.0), 0.3)
		t.parallel().tween_property(clone, "scale", Vector2(2.0, 2.0), 0.3)
		
	PendDelete(clone, 0.3)

func UseCard():
	if not CanAct() and not await StartQueue():
		return
	
	if cards[pointInd - 1].size() > 0:
		var card = cards[pointInd - 1][0]
		
		if card:
			#SetState(card.cardName, true, true)
			match card.cardName:
				"Bash":
					PerformAttack("Bash")
				"Spear":
					SetState("BasicAtk1", true, true)
					Projectile.SpawnProj("Spear", self, Vector2(100.0, 0.0), get_parent(), 0)
					vels.append(Force.new(Vector2(100.0, 0.0), 400.0, 400.0, true, true, lookDirection, -1))
					VFXHandler.ShowVFX("Spray", Vector2(10.0 * lookDirection, 0.0), self, lookDirection)
				"Bullet":
					AudioPlayer.play("Sounds/Shoot.wav", self)
					SetState("ProjFire", true, true)
					Projectile.SpawnProj("Bullet", self, Vector2(10.0, 0.0), get_parent(), 1)
					vels.append(Force.new(Vector2(100.0, 80.0 if not is_on_floor() else 0.0), 400.0, 400.0, true, true, -lookDirection, -1))
					VFXHandler.ShowVFX("Spray", Vector2(10.0 * lookDirection, 0.0), self, lookDirection)
				"Boomerang":
					SetState("BasicAtk1", true, true)
					Projectile.SpawnProj("Boomerang", self, Vector2(10.0, 0.0), get_parent(), 1)
					vels.append(Force.new(Vector2(100.0, 80.0 if not is_on_floor() else 0.0), 400.0, 400.0, true, true, -lookDirection, -1))
					VFXHandler.ShowVFX("Spray", Vector2(10.0 * lookDirection, 0.0), self, lookDirection)
				"Burst":
					PerformAttack("Burst")
				"Shield Blitz":
					PerformAttack("Shield Blitz")
					
			card.uses -= 1
			
			#CardEffect(1)

			if card.uses == 0:
				CardEffect(0)
				cards[pointInd - 1].remove_at(0)
			
			UpdateCards()
		
func PromptRewards():
	var rewards = canvas.get_node("BossRewards")
	var label = rewards.get_node("Label")
	
	get_node("Celebrate").play()
	
	rewards.visible = true
	
	var showTween = create_tween()
	showTween.tween_property(rewards, "self_modulate", Color(1,1,1,1), 0.5)
	
	await showTween.finished
	
	label.visible = true
	
	var labelTween = create_tween()
	labelTween.set_ease(Tween.EASE_OUT)
	labelTween.set_trans(Tween.TRANS_CUBIC)
	labelTween.tween_property(label, "position", Vector2(329.0, 20.0), 0.3)
	labelTween.parallel().tween_property(label, "modulate", Color(1,1,1,1), 0.3)
	
	await labelTween.finished
	
	for child in rewards.get_children():
		if child.name != "Label":
			child.visible = true
			child.modulate = Color(1,1,1,1)
			child.scale = Vector2(8.0, 8.0)
			child.selected = false
			child.ignore = false
			child.disabled = false
			
			if child.name == "Wild":
				child.emit_signal("SetRandom")
			
			var tween = create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(child, "position", Vector2(child.position.x, 267.0), 0.3)
			
			await get_tree().create_timer(0.2).timeout
			
	await RewardChosen
	
	await get_tree().create_timer(0.5).timeout
	
	var selectedCard
	
	for child in rewards.get_children():
		if child.name != "Label":
			if not child.selected:
				var tween = create_tween()
				tween.set_ease(Tween.EASE_OUT)
				tween.set_trans(Tween.TRANS_CUBIC)
				tween.tween_property(child, "position", Vector2(child.position.x, 768.0), 0.3)
				
				await get_tree().create_timer(0.2).timeout
			else:
				selectedCard = child
			
	var selectTween = create_tween()
	selectTween.set_ease(Tween.EASE_IN)
	selectTween.set_trans(Tween.TRANS_BACK)
	selectTween.tween_property(selectedCard, "position", Vector2(selectedCard.position.x, -220.0), 0.3)
	
	await selectTween.finished
	
	await get_tree().create_timer(0.5).timeout
	
	for child in rewards.get_children():
		if child.name != "Label":
			child.visible = false
			
	selectedCard.position.y = 768.0
	
	var labelExit = create_tween()
	labelExit.set_ease(Tween.EASE_OUT)
	labelExit.set_trans(Tween.TRANS_CUBIC)
	labelExit.tween_property(label, "position", Vector2(329.0, -112.0), 0.3)
	labelExit.parallel().tween_property(label, "modulate", Color(1,1,1,1), 0.3)
	
	await labelExit.finished
	
	label.visible = false
	
	var fadeTween = create_tween()
	fadeTween.tween_property(rewards, "self_modulate", Color(1,1,1,0), 0.5)
	
	await fadeTween.finished
	
func NextWave():
	waveTrans = true
	
	var node = canvas.get_node("WaveStuff")
	var wave = node.get_node("Wave")
	var large = node.get_node("WaveLarge")
	var bar = wave.get_node("ProgressBar")
	var largeWave
	
	var hideWave = create_tween()
	hideWave.tween_property(wave, "position", Vector2(484.0, -145.0), 0.2)
	
	await hideWave.finished
	
	if Globals.globalVars.get("Wave") == 2 and not Globals.globalVars.get("DidDashTutor"):
		var l = canvas.get_node("Tutorial")
		var dash = canvas.get_node("Dash")
		
		waveTrans = false
		dash.visible = true
		
		ShowTutorial(l, "You can DASH to avoid enemy attacks. Try it!")
		
		while not states.get("Dash"):
			await BlinkControl(dash)
		
		await get_tree().create_timer(1.0).timeout
		
		var t = create_tween()
		t.set_ease(Tween.EASE_IN)
		t.set_trans(Tween.TRANS_BACK)
		t.tween_property(l, "position", Vector2(200.0, -125.0), 0.4)
		
		await t.finished
		
		l.visible = false
		
		Globals.globalVars.set("DidDashTutor", true)
		waveTrans = true
	
	if Globals.globalVars.get("Wave") != 0 and Globals.globalVars.get("Wave")%BOSS_EVERY == 0:
		get_node("Music_Paragon of no Paradigm_mp3").stream_paused = true
		AudioPlayer.play("Music/Boss Wave Cleared.mp3", self, true, -6.0)
		
		large.text = "BOSS CLEAR"
		large.position = Vector2(-711.0, 247.0)
		large.visible = true
	
		largeWave = create_tween()
		largeWave.tween_property(large, "position", Vector2(202.0, 247.0), 0.3)
		largeWave.tween_property(large, "position", Vector2(312.0, 247.0), 1.5)
		largeWave.tween_property(large, "position", Vector2(1161.0, 247.0), 0.3)
		
		await get_tree().create_timer(2.5).timeout
		
		await PromptRewards()
		
		get_node("Celebrate").stop()
		get_node("Music_Paragon of no Paradigm_mp3").stream_paused = false
		
		TakeDamage(-maxHealth)
	else:
		TakeDamage(-20.0)
		
	Globals.globalVars.set("Wave", Globals.globalVars.get("Wave") + 1)
	
	AudioPlayer.play("Sounds/Notify.wav", self)
	
	large.text = "Wave " + str(Globals.globalVars.get("Wave"))
	large.position = Vector2(-711.0, 247.0)
	large.visible = true
	
	largeWave = create_tween()
	largeWave.tween_property(large, "position", Vector2(202.0, 247.0), 0.3)
	largeWave.tween_property(large, "position", Vector2(312.0, 247.0), 1.5)
	largeWave.tween_property(large, "position", Vector2(1161.0, 247.0), 0.3)
	
	await get_tree().create_timer(2.5).timeout
	
	var spawnCount = 2 + Globals.globalVars.get("Wave")
	
	if Globals.globalVars.get("Wave")%BOSS_EVERY == 0:
		large.text = "BOSS WAVE"
		large.position = Vector2(-711.0, 247.0)
	
		largeWave = create_tween()
		largeWave.tween_property(large, "position", Vector2(202.0, 247.0), 0.3)
		largeWave.tween_property(large, "position", Vector2(312.0, 247.0), 1.5)
		largeWave.tween_property(large, "position", Vector2(1161.0, 247.0), 0.3)
		
		spawnCount *= 2
		
		await get_tree().create_timer(2.5).timeout
	
	#spawning the enemies
	var enemies = ["big_box", "box_enemy", "flying_enemy"]
	var parentTo = get_parent().get_node("Enemies")
	var healthSum: int = 0
	
	dangerRate = 0.0
	waveTrans = false
	
	for i in spawnCount:
		var enemyName = enemies[randi_range(0,enemies.size()-1)]
		var enemy = load("res://Scenes/Enemies/Basic/" + enemyName + ".tscn").instantiate()
		
		enemy.global_position = camera.global_position + Vector2(50.0 * i, 0.0)
		
		if enemy.outlineColor == 2:
			enemy.global_position -= Vector2(0.0, 50.0)
		
		enemy.global_position.x = clamp(enemy.global_position.x, -450.0, 2200.0)
		enemy.global_position.y = clamp(enemy.global_position.y, -400.0, 700.0)
		
		enemy.health += (5 * (Globals.globalVars.get("Wave") - 1))
		enemy.attackEvery = randf_range(1.0, 2.0)
		enemy.target = self
		
		healthSum += enemy.health
		dangerRate += enemy.dangerLevel
		
		parentTo.add_child(enemy)
	
	Globals.globalVars.set("Defeated", 0)
	Globals.globalVars.set("WaveGoal", spawnCount)
	
	wave.text = "Wave " + str(Globals.globalVars.get("Wave"))
	wave.get_node("Progress").text = "(0/" + str(spawnCount) + ")"
	
	bar.max_value = healthSum
	bar.value = healthSum
	
	large.visible = false
	
	var showWave = create_tween()
	showWave.set_trans(Tween.TRANS_CUBIC)
	showWave.set_ease(Tween.EASE_OUT)
	showWave.tween_property(wave, "position", Vector2(484.0, 0.0), 0.3)
	
func OnUpdateCombo(displayOnly: bool = false):
	if not displayOnly:
		if combo == 0:
			var t = create_tween()
			var goal = comboLabel.modulate
			
			goal.a = 1.0
			comboBar.max_value = 100.0
			
			t.set_trans(Tween.TRANS_CUBIC)
			t.set_ease(Tween.EASE_OUT)
			t.tween_property(comboLabel, "modulate", goal, 0.3)
			t.parallel().tween_property(comboLabel, "position", Vector2(706.0, 329.0), 0.3)
			
		lastHit = Time.get_ticks_msec()
		comboDrain = 0.0
		combo += 1
	else:
		var t = create_tween()
		var goal = comboLabel.modulate
		
		goal.a = 0.0
		
		t.set_trans(Tween.TRANS_CUBIC)
		t.set_ease(Tween.EASE_OUT)
		t.tween_property(comboLabel, "modulate", goal, 0.3)
		t.parallel().tween_property(comboLabel, "position", Vector2(750.0, 329.0), 0.3)
		
	comboLabel.text = str(snapped(airTime, 0.01)) + "s"
	
	if comboBar.value >= comboBar.max_value:
		comboBar.max_value += 50.0
		
		var clone = comboLabel.duplicate()
		var mod = clone.modulate
		var t = create_tween().bind_node(clone)
		
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_CUBIC)
		
		clone.name = "ComboC"
		clone.get_node("Bar").queue_free()
		mod.a = 0.0
		
		canvas.add_child(clone)
		
		t.tween_property(clone, "modulate", mod, 0.3)
		t.parallel().tween_property(clone, "scale", Vector2(2.0, 2.0), 0.3)
		
		PendDelete(clone, 0.3)

func ShakeHealthBar():
	shakingBar = true
	
	var start = Time.get_ticks_msec()
	var pos = healthBar.position
	
	while Time.get_ticks_msec() - start <= 300:
		healthBar.position = Vector2(randf_range(0.0, 14.0), randf_range(600.0, 630.0))
		await get_tree().process_frame
	
	healthBar.position = pos
	shakingBar = false

func UpdateHealthBar():
	healthBar.value = health
	
	if lastHealth > health and not shakingBar:
		ShakeHealthBar()
	
	lastHealth = health
	
func TakeDamage(amount: float, knockback: Force = null, _isSnatcher: bool = false, _c: int = -1, override: bool = false) -> bool:
	if not states.get("Dash"):
		health = clamp(health - amount, 1 if not override else 0, maxHealth)
		
		if knockback:
			vels.append(knockback)
		
		UpdateHealthBar()
		
		return true
	else:
		return false
	
func Dash():
	if not canDash or (not CanAct() and not await StartQueue()):
		return
	
	canDash = false
	
	SetState("Dash", true, true)
	
	VFXHandler.ShowVFX("Splash", position, get_parent(), lookDirection, 1.0)
	vels.append(Force.new(Vector2(900.0, 0.0), 2500.0, 2500.0, true, true, lookDirection, 1))
	
	await get_tree().create_timer(0.4).timeout
	
	SetState("Dash", false)
	
	await get_tree().create_timer(0.2).timeout
	
	canDash = true

func ChangeControlsDisplay():
	Globals.globalVars.set("MouseControls", not Globals.globalVars.get("MouseControls"))
	
	var attack = canvas.get_node("Attack")
	var snatch = canvas.get_node("Snatch")
	var switch = canvas.get_node("CardSelect/Switch")
	var notice = canvas.get_node("Notice")
	var path = "res://Assets/UI/Controls/"
	
	if Globals.globalVars.get("MouseControls"):
		notice.text = "Press TAB for keyboard controls"
		attack.texture = load(path + "Left Click.png")
		snatch.texture = load(path + "Middle Click.png")
		switch.texture = load(path + "Scroll.png")
		
		for i in range(1,4):
			canvas.get_node("CardSelect/" + str(i) + "/Panel/Use").texture = load(path + "Right Click.png")
	else:
		notice.text = "Press TAB for mouse controls"
		attack.texture = load(path + "J.png")
		snatch.texture = load(path + "O.png")
		switch.texture = load(path + "K.png")
		
		for i in range(1,4):
			canvas.get_node("CardSelect/" + str(i) + "/Panel/Use").texture = load(path + "I.png")

func _input(event: InputEvent) -> void:
	if event.is_pressed():
		if event.is_action("M1"):
			PerformAttack("M1")
		elif event.is_action("M2"):
			StartSnatch()
		elif event.is_action("Dash"):
			Dash()
		elif event.is_action("PointerDown"):
			UpdatePointer(1)
		elif event.is_action("PointerUp"):
			UpdatePointer(-1)
		elif event.is_action("UseCard"):
			UseCard()
		elif event.is_action("BoxEscape"):
			AttemptEscape()
		elif event.is_action("ToggleControls"):
			ChangeControlsDisplay()

func SetMap(n: String, trans: bool = false):
	var toSet = maps.get_node(n).duplicate()
	var parent = get_parent()
	var currMap = parent.get_node_or_null("CurrMap")
	var fadePanel = canvas.get_node("FadePanel")
	
	if trans:
		var t = create_tween()
		
		fadePanel.modulate = Color(1,1,1,0)
		
		t.tween_property(fadePanel, "modulate", Color(1,1,1,1), 1.0)
		await t.finished
	
	if currMap:
		currMap.queue_free()
	
	toSet.name = "CurrMap"
	toSet.get_node("Ground").enabled = true
	
	parent.add_child.call_deferred(toSet)
	
	if trans:
		var t = create_tween()
		t.tween_property(fadePanel, "modulate", Color(1,1,1,0), 1.0)
		await t.finished
		fadePanel.modulate = Color(0,0,0,0)

func ShowTutorial(l: Label, t: String):
	l.position = Vector2(200.0, -125.0)
	l.text = t
	l.visible = true
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(l, "position", Vector2(200.0, 14.0), 0.4)
	
func BlinkControl(c: TextureRect):
	var l = c.get_node("Label")
	
	l.self_modulate = Color(1,1,0)
	
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(l, "scale", Vector2(1.2, 1.2), 0.2)
	
	await t.finished
	
	l.self_modulate = Color(1,1,1)
	
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(l, "scale", Vector2(1.0, 1.0), 0.2)
	
	await t.finished
	
func StartTutorial():
	var panel = canvas.get_node("FadePanel")
	var attack = canvas.get_node("Attack")
	var snatch = canvas.get_node("Snatch")
	var switch = canvas.get_node("CardSelect/Switch")
	var notice = canvas.get_node("Notice")
	var l = canvas.get_node("Tutorial")
	var useLabels = {}
	
	attack.visible = false
	snatch.visible = false
	switch.visible = false
	notice.visible = true
	
	for i in range(1,4):
		var u = canvas.get_node("CardSelect/" + str(i) + "/Panel/Use")
		u.visible = false
		useLabels[i] = u
	
	canvas.get_node("WaveStuff").visible = false
	panel.modulate = Color(0,0,0,1)
	
	SetMap("Cardboard")
	
	await get_tree().create_timer(1.0).timeout
	
	AudioPlayer.play("Music/Preparation.mp3", self, true, -6.0)
	
	var t = create_tween()
	t.tween_property(panel, "modulate", Color(0,0,0,0), 2.0)
	
	await t.finished
	
	var tutorEnemy = load("res://Scenes/Enemies/Basic/box_enemy.tscn").instantiate()
	
	tutorEnemy.noAttack = true
	tutorEnemy.firstTutor = true
	tutorEnemy.target = self
	tutorEnemy.global_position = global_position + Vector2(50.0, 0.0) #enemy could spawn out of bounds on the right
	tutorEnemy.global_position.x = clamp(tutorEnemy.global_position.x, -450.0, 2200.0)
	tutorEnemy.global_position.y = clamp(tutorEnemy.global_position.y, -400.0, 700.0)
	
	get_parent().get_node("Enemies").add_child(tutorEnemy)
	
	ShowTutorial(l, "Weaken the enemy by using ATTACKs.")
	attack.visible = true
	while tutorEnemy.health > 0:
		await BlinkControl(attack)
		
	ShowTutorial(l, "Now, perform a SNATCH to get cards from the enemy.")
	snatch.visible = true
	while tutorEnemy:
		await BlinkControl(snatch)
	
	await get_tree().create_timer(1.0).timeout
		
	ShowTutorial(l, "You may have noticed your attacks were \"WEAK...\" Let's fix that!")
	
	await get_tree().create_timer(3.0).timeout
	
	ShowTutorial(l, "Switch to the color BLUE.")
	switch.visible = true
	while pointInd != 3:
		await BlinkControl(switch)
		
	var tutorEnemy2 = load("res://Scenes/Enemies/Basic/big_box.tscn").instantiate()
	
	tutorEnemy2.noAttack = true
	tutorEnemy2.target = self
	tutorEnemy2.health = 20
	tutorEnemy2.global_position = global_position + Vector2(50.0, -50.0)
	tutorEnemy2.global_position.x = clamp(tutorEnemy2.global_position.x, -450.0, 2200.0)
	tutorEnemy2.global_position.y = clamp(tutorEnemy2.global_position.y, -400.0, 700.0)
	
	get_parent().get_node("Enemies").add_child(tutorEnemy2)
	
	ShowTutorial(l, "Use CARDS of the same color as the enemy to deal \"CRITICAL!!\" damage.")
	
	for i in useLabels:
		useLabels[i].visible = true
	
	while tutorEnemy2.health > 0:
		BlinkControl(useLabels.get(1))
		BlinkControl(useLabels.get(2))
		await BlinkControl(useLabels.get(3))
		
	ShowTutorial(l, "Now, finish the enemy with a SNATCH for more card(s)!")
	while tutorEnemy2:
		await BlinkControl(snatch)
	
	await get_tree().create_timer(1.0).timeout
	
	ShowTutorial(l, "Yay! Now you know how to fight enemies!")
	
	await get_tree().create_timer(3.0).timeout
	
	ShowTutorial(l, "Good luck out there!")
	
	await get_tree().create_timer(2.0).timeout
	
	t = create_tween()
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_BACK)
	t.tween_property(l, "position", Vector2(200.0, -125.0), 0.4)
	
	await t.finished
	
	l.visible = false
	notice.visible = false
	
	t = create_tween()
	t.tween_property(get_node("Music_Preparation_mp3"), "volume_db", -20.0, 1.0)
	
	await SetMap("City", true)
	
	get_node("Music_Preparation_mp3").stop()
	
	await get_tree().create_timer(1.0).timeout
	
	Globals.globalVars.set("DidTutor", true)
	canvas.get_node("WaveStuff").visible = true
	AudioPlayer.play("Music/Paragon of no Paradigm.mp3", self, true, -6.0)
	
	NextWave()

func _ready() -> void:
	add_to_group("Player")
	
	CARD_COLORS = Globals.globalVars.get("COLORS")
	
	maxCards = 5
	
	Globals.globalVars.set("Wave", 0)
	
	animPlayer = $AnimationPlayer
	sprite = $AnimatedSprite2D
	canvas = camera.get_node("CanvasLayer")
	healthBar = canvas.get_node("Health")
	dangerBar = canvas.get_node("WaveStuff/Wave/DangerBar")
	comboLabel = canvas.get_node("Combo")
	comboBar = comboLabel.get_node("Bar")
	maps = get_parent().get_node("Maps")
	
	healthBar.max_value = maxHealth
	dangerBar.max_value = dangerGoal
	
	SnatchEnd.connect(OnSnatchEnd)
	BringTowards.connect(OnBringTowards)
	GiveWild.connect(OnGiveWild)
	GrantRefill.connect(OnRefill)
	IncreaseMax.connect(OnMaxIncrease)
	UpdateCombo.connect(OnUpdateCombo)
	
	#setup the card panels
	var panel = canvas.get_node("Panel")
	
	for i in range(1,4):
		var clone = panel.duplicate()
		var card = canvas.get_node("CardSelect/" + str(i))
		
		if i != 1:
			clone.visible = false
		#clone.position = Vector2(-101.0, 9.0)
		clone.self_modulate = CARD_COLORS[i - 1]
		card.add_child(clone)
		clone.global_position = Vector2(899.0, 455.0)
		
	for map in maps.get_children():
		var background = map.get_node("Background")
		var ground = map.get_node("Ground")
		
		background.set_meta("mod", background.modulate)
		ground.set_meta("mod", ground.modulate)
		
	#SetMap("City")
		
	UpdateCards()
	UpdatePointer(0)
	UpdateHealthBar()
	#OnUpdateCombo(true)
	
	if Globals.globalVars.get("DidTutor"):
		var p = canvas.get_node("FadePanel")
		
		p.modulate = Color(0,0,0,1)
		
		canvas.get_node("Dash").visible = Globals.globalVars.get("DidDashTutor")
		
		create_tween().tween_property(p, "modulate", Color(0,0,0,0), 1.0)
		
		AudioPlayer.play("Music/Paragon of no Paradigm.mp3", self, true, -6.0)
		
		SetMap("City")
		NextWave()
	else:
		StartTutorial()

func GameOver():
	var overTween = create_tween()
	var parent = get_parent()
	var scoring = canvas.get_node("Scoring")
	
	if trapTween:
		trapTween.kill()
	
	overTween.set_trans(Tween.TRANS_BACK)
	overTween.set_ease(Tween.EASE_OUT)
	overTween.tween_property(camera, "zoom", Vector2(5.0, 5.0), 1.0)
	overTween.parallel().tween_property(parent.get_node("CurrMap"), "modulate", Color(0.0, 0.0, 0.0), 1.0)
	
	canvas.get_node("Escape").visible = false
	canvas.get_node("Attack").visible = false
	canvas.get_node("Snatch").visible = false
	canvas.get_node("Dash").visible = false
	canvas.get_node("CardSelect").visible = false
	canvas.get_node("Health").visible = false
	
	create_tween().tween_property(parent.get_node("Enemies"), "modulate", Color(1,1,1,0), 1.0)
	
	await overTween.finished
	
	ShowTutorial(canvas.get_node("Tutorial"), "GAME OVER")
	
	var t = create_tween()
	t.tween_property(get_node("Music_Paragon of no Paradigm_mp3"), "volume_db", -20.0, 1.0)
	
	await t.finished
	
	get_node("Music_Paragon of no Paradigm_mp3").stop()
	
	var wave = Globals.globalVars.get("Wave")
	var highWave = Globals.globalVars.get("HighWaves")
	
	var highEnemies = Globals.globalVars.get("HighEnemies")
	
	var highObtained = Globals.globalVars.get("HighCards")
	
	scoring.get_node("Waves").text = str(wave)
	scoring.get_node("Waves2").text = str(highWave)
	
	if wave > highWave:
		scoring.get_node("Waves/High").visible = true
		Globals.globalVars.set("HighWaves", wave)
	
	scoring.get_node("Defeated").text = str(enemiesDefeated)
	scoring.get_node("Defeated2").text = str(highEnemies)
	
	if enemiesDefeated > highEnemies:
		scoring.get_node("Defeated/High").visible = true
		Globals.globalVars.set("HighEnemies", enemiesDefeated)
	
	scoring.get_node("Obtained").text = str(cardsObtained)
	scoring.get_node("Obtained2").text = str(highObtained)
	
	if cardsObtained > highObtained:
		scoring.get_node("Obtained/High").visible = true
		Globals.globalVars.set("HighCards", cardsObtained)
		
	scoring.visible = true
		
	var scoringEnter = create_tween()
	scoringEnter.set_trans(Tween.TRANS_CUBIC)
	scoringEnter.set_ease(Tween.EASE_OUT)
	scoringEnter.tween_property(scoring, "position", Vector2(460.0, 362.0), 0.4)
	
	await scoringEnter.finished
	
	await get_tree().create_timer(1.0).timeout
	
	var restart = canvas.get_node("Restart")
	var mainMenu = canvas.get_node("MainMenu")
	
	restart.visible = true
	mainMenu.visible = true
	
	var buttonEnter = create_tween()
	buttonEnter.set_trans(Tween.TRANS_CUBIC)
	buttonEnter.set_ease(Tween.EASE_OUT)
	buttonEnter.tween_property(restart, "position", Vector2(494.0, 499.0), 0.4)
	buttonEnter.parallel().tween_property(mainMenu, "position", Vector2(493.0, 551.0), 0.4)
	
	
func DangerSequence():
	danger = -1.0
	
	var parent = get_parent()
	
	var box = Sprite2D.new()
	box.texture = load("res://Assets/UI/box.png")
	box.name = "TrapBox"
	box.scale = Vector2(1.6, 1.6)
	box.z_index = z_index + 1
	box.position = position
	
	var effect = box.duplicate()
	effect.name = "TrapEffect"
	effect.z_index = z_index
	
	parent.add_child(box)
	parent.add_child(effect)
	
	var bTween = create_tween()
	bTween.set_trans(Tween.TRANS_CUBIC)
	bTween.set_ease(Tween.EASE_OUT)
	bTween.tween_property(effect, "scale", Vector2(2.5, 2.5), 0.3)
	bTween.parallel().tween_property(effect, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.3)
	
	PendDelete(effect, 0.3)
	
	trapTween = create_tween()
	#zoomTween.set_trans(Tween.TRANS_CUBIC)
	#zoomTween.set_ease(Tween.EASE_OUT)
	trapTween.tween_property(camera, "zoom", Vector2(5.0, 5.0), 10.0)
	trapTween.parallel().tween_property(parent.get_node("CurrMap"), "modulate", Color(0.0, 0.0, 0.0), 10.0)
	
	var minigame = canvas.get_node("Escape")
	var line = minigame.get_node("Line")
	var goal = minigame.get_node("Goal")
	var task = minigame.get_node("Task")
	var goalDirect: int = 1
	var lineDirect: int = 1
	var moveSpeed: float = 40.0
	var elapsed: float = 0.0
	
	canvas.get_node("WaveStuff").visible = false
	canvas.get_node("CardSelect").visible = false
	
	#minigame.global_position = get_global_transform_with_canvas().get_origin() + Vector2(-minigame.size.x / 2, 100.0)
	line.position.x = randf_range(3.0, minigame.size.x - 3.0)
	minigame.visible = true
	
	while health > 0 and danger < 0:
		var delta = get_process_delta_time()
		
		if line.position.x <= 0.0 or line.position.x + line.size.x >= minigame.size.x:
			lineDirect *= -1
		if goal.position.x <= 0.0 or goal.position.x + goal.size.x >= minigame.size.x:
			goalDirect *= -1
		
		line.position.x += (((moveSpeed*4) * lineDirect) * delta)
		goal.position.x += ((moveSpeed * goalDirect) * delta)
		
		elapsed += delta
		
		if elapsed >= 0.2:
			elapsed = 0.0
			task.visible = not task.visible
		
		TakeDamage(5.0 * delta, null, false, -1, true)
		
		await get_tree().process_frame
	
	if health <= 0:
		GameOver()
		
func AttemptEscape():
	if danger >= 0.0 or health <= 0:
		return
	
	var minigame = canvas.get_node("Escape")
	var line = minigame.get_node("Line")
	var goal = minigame.get_node("Goal")
	var dist = abs(line.position.x - (goal.position.x + (goal.size.x / 2)))
	var parent = get_parent()
	
	if dist <= goal.size.x:
		#var background = parent.get_node("CurrMap/Background")
		#var ground = parent.get_node("CurrMap/Ground")
		
		parent.get_node("TrapBox").queue_free()
		canvas.get_node("WaveStuff").visible = true
		canvas.get_node("CardSelect").visible = true
		minigame.visible = false
		danger = 0.0
		
		trapTween.kill()
		
		var resetTween = create_tween()
		resetTween.set_ease(Tween.EASE_OUT)
		resetTween.set_trans(Tween.TRANS_CUBIC)
		resetTween.tween_property(camera, "zoom", Vector2(3.0, 3.0), 0.3)
		resetTween.parallel().tween_property(parent.get_node("CurrMap"), "modulate", Color(1,1,1), 0.3)
		
		VFXHandler.ShowVFX("Boom", position, get_parent())
		ShakeCam(0.3)
		
		vels.append(Force.new(Vector2(0.0, 40.0), 400.0, 400.0, false, false, 1, -1))
	else:
		TakeDamage(5.0)
		
		var clone = minigame.get_node("Status").duplicate()
		clone.name = "StatusC"
		clone.visible = true
		minigame.add_child(clone)
		
		var missTween = create_tween()
		missTween.tween_property(clone, "modulate", Color(0.47, 0.47, 0.47, 0.0), 0.5)
		missTween.parallel().tween_property(clone, "position", clone.position + Vector2(0.0, 10.0), 0.5)
		
		PendDelete(clone, 0.5)
		
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		if danger >= 0.0:
			velocity += get_gravity() * delta
		#airTime += delta
		#OnUpdateCombo()
	else:
		SetState("Fall", false)
		#airTime = 0.0

	# Handle jump.
	if Input.is_action_just_pressed("Jump"):
		var canWingJump = Globals.globalVars.get("WildName") == "Air Jump" and Time.get_ticks_msec() - lastWings >= 1000
		var canJump: bool
		
		if is_on_floor():
			canJump = true
		elif canWingJump:
			canJump = true
			lastWings = Time.get_ticks_msec()
			
			SetState("Fall", false)
			
			VFXHandler.ShowVFX("Wings", Vector2.ZERO, self, lookDirection)
			VFXHandler.ShowVFX("Splash", position, get_parent(), lookDirection)
			
			canvas.get_node("CardSelect/Wild").emit_signal("Cooldown", 1.0)
			
			animPlayer.stop()
			
		if canJump:
			SetState("Jump", true, true)
			velocity.y = JUMP_VELOCITY

	#move direction handling
	var direction := Input.get_axis("Left", "Right")
	
	if direction:
		velocity.x = direction * SPEED
		
		if not attacking and lookDirection != direction:
			lookDirection = int(direction)
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
			
	#updating based on movement/state vars
	if not attacking:
		sprite.flip_h = lookDirection < 0
	
	SetState("Run", direction)
	
	var highest: String
	
	for state in states.keys():
		if states.get(state):
			var currData = animData.get(state)
			
			if not currData or (currData.get("once") and not playHistory.get(state)):
				animPlayer.play(state)
				playHistory.set(state, [true, Time.get_ticks_msec()])
			elif currData:
				var afterAnim = currData.get("playAfter")
					
				if afterAnim and (not animPlayer.current_animation or Time.get_ticks_msec() - playHistory.get(state)[1] >= (animPlayer.current_animation_length * 1000)):
					if afterAnim != "none":
						animPlayer.play(afterAnim)
						playHistory.set(afterAnim, [true, Time.get_ticks_msec()])
						
						SetState(afterAnim, true)
					
					SetState(state, false)
			
			highest = state
			
			break
			
	#velocity update from vels
	VelocityHandler.UpdateVel(self, delta)
	
	#draw layer effect
	var layer = Sprite2D.new()
	var color = Color(CARD_COLORS[pointInd - 1])
	
	color.r *= 10
	color.g *= 10
	color.b *= 10
	color.a = 0.5
	color.v = 50.0
	
	var m = ShaderMaterial.new()
	m.shader = load("res://Resources/" + str(pointInd) + ".gdshader")
	
	layer.global_position = global_position
	layer.z_index = 0
	layer.material = m
	layer.flip_h = sprite.flip_h
	layer.texture = sprite.sprite_frames.get_frame_texture(highest, sprite.frame)
	
	get_parent().add_child(layer)
	create_tween().tween_property(layer, "modulate", Color(0,0,0,0), 0.3)
	PendDelete(layer, 0.3)
	
	#handling camera
	var camTween = create_tween()
	camTween.set_trans(Tween.TRANS_CUBIC)
	camTween.set_ease(Tween.EASE_OUT)                   #+ (Vector2(20.0 * direction, 0.0))
	camTween.tween_property(camera, "position", position if not snatchTarget else (position + snatchTarget.position) / 2, 0.3)
	
	#handling attack
	if currAttack:
		currAttack.Update()
		
	#handling danger
	if danger >= 0.0:
		move_and_slide()
		
		if Globals.globalVars.get("DidTutor" ) and dangerRate > 0.0:
			danger += (dangerRate * delta)
			dangerBar.value = danger
			
			if danger >= dangerGoal:
				DangerSequence()
	
	if health == 1.0:
		healthBar.get_node("Warning").visible = Time.get_ticks_msec()%400 >= 200
	else:
		healthBar.get_node("Warning").visible = false
	#comboBar.value -= comboDrain
	#comboDrain += (0.2 * delta)
	
	#if combo > 0 and comboBar.value <= 0.0:
		#combo = 0
		#OnUpdateCombo(true)
