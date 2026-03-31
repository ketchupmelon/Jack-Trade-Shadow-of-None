extends Node
class_name Card

@export var cardName: String
@export var uses: int
@export var maxUses: int

static var cards = [
	#red
	[Card.new("Bash", 3), Card.new("Spear", 2)],
	
	#green
	[Card.new("Bullet", 3), Card.new("Boomerang", 3)],
	
	#blue
	[Card.new("Burst", 2), Card.new("Shield Blitz", 3)]
]

func _init(n: String, u: int):
	cardName = n
	uses = u
	maxUses = u
	
static func DrawRandCardFromColorInd(colorInd: int):
	var card = cards[colorInd][randi_range(0,cards[colorInd].size()-1)]
	return Card.new(card.cardName, card.uses if Globals.globalVars.get("WildName") != "x2 Uses" else card.uses * 2)
