extends Node2D
class_name Force

@export var vel: Vector2
@export var xDamp: float
@export var yDamp: float
@export var xOverride: bool
@export var yOverride: bool
@export var xDirect: int
@export var yDirect: int

#VEL MUST NEVER HAVE NEGATIVE COMPONENTS

func _init(velp = Vector2.ZERO, xDampp = 0.0, yDampp = 0.0, xOverridep = false, yOverridep = false, xDirectp = 1, yDirectp = 1) -> void:
	vel = velp
	xDamp = xDampp
	yDamp = yDampp
	xOverride = xOverridep
	yOverride = yOverridep
	xDirect = xDirectp
	yDirect = yDirectp
