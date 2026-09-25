extends Node2D


const ROTATION_SPEED = 5

@export var damage: int = 40


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate(ROTATION_SPEED * delta)
	
func get_damage_amount() -> int:
	return damage
