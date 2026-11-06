extends Area2D

@export var item: ItemData

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player_near := false


func _ready() -> void:
	body_entered.connect(_ao_entrar_corpo)
	body_exited.connect(_ao_sair_corpo)


func _ao_entrar_corpo(corpo: Node2D) -> void:
	if corpo.is_in_group("player"):
		player_near = true
		corpo.show_interaction("Take")
		


func _ao_sair_corpo(corpo: Node2D) -> void:
	if corpo.is_in_group("player"):
		player_near = false
		corpo.hide_interaction()

func _unhandled_input(event: InputEvent) -> void:

	if player_near and event.is_action_pressed("interact"):
		_coletar()
		self.get_viewport().set_input_as_handled()


func _coletar() -> void:
	var inventario = get_tree().get_first_node_in_group("inventory")
	if inventario and inventario.add_item(item):
		queue_free() # só some do mundo se coube no inventário
