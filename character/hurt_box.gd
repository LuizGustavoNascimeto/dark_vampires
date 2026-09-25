# Script na Area2D filha
extends Area2D

func _ready():
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D):
	if area.is_in_group("enemy"):
		var enemy = area.get_parent()
		if enemy.has_method("get_damage_amount"):
			get_parent().reduce_health(enemy.get_damage_amount())
		
