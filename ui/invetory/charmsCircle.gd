extends Control

@export var slot_size := Vector2(64, 64)
@export var base_radius := 140.0
@export var slot_gap := 12.0

@onready var charm_name: Label = %CharmName

@onready var ring: Control = %Ring
@onready var center_icon: TextureRect = %CenterIcon

var charms: Array[ItemData] = []
var equipped: ItemData = null
var slots: Array[Button] = []

signal charm_pressed(charm: ItemData)


func build(new_charms: Array[ItemData]) -> void:
	for child in ring.get_children():
		ring.remove_child(child)
		child.queue_free()
	slots.clear()
	_show_charm(null)
	charms = new_charms

	var count := charms.size()
	if count == 0:
		_refresh_equipped()
		return

	var radius := _get_radius(count)
	for i in count:
		var slot := Button.new()
		slot.custom_minimum_size = slot_size
		slot.size = slot_size
		slot.expand_icon = true
		slot.icon = charms[i].icon
		slot.focus_mode = Control.FOCUS_ALL
		slot.pressed.connect(charm_pressed.emit.bind(charms[i]))
		slot.focus_entered.connect(_show_charm.bind(charms[i]))
		ring.add_child(slot)
		slots.append(slot)

		var angle := -PI / 2.0 + i * TAU / count
		slot.position = Vector2.from_angle(angle) * radius - slot_size / 2.0

	_link_neighbors()
	_refresh_equipped()

func _link_neighbors() -> void:
	var count := slots.size()
	for i in count:
		var previous := slots[(i - 1 + count) % count]
		var next := slots[(i + 1) % count]
		var slot := slots[i]
		slot.focus_neighbor_left = previous.get_path()
		slot.focus_neighbor_top = previous.get_path()
		slot.focus_neighbor_right = next.get_path()
		slot.focus_neighbor_bottom = next.get_path()

func _get_radius(count: int) -> float:
	if count < 2:
		return base_radius
	# Adjacent centers must be at least one slot diagonal + gap apart,
	# otherwise square slots can overlap at 45 degrees
	var min_distance := slot_size.length() + slot_gap
	var min_radius := min_distance / (2.0 * sin(PI / count))
	return maxf(base_radius, min_radius)

# Called by Inventory when the equipped charm changes (null = nothing equipped)
func set_equipped(charm: ItemData) -> void:
	equipped = charm
	_refresh_equipped()


func _refresh_equipped() -> void:
	center_icon.texture = equipped.icon if equipped else null
	for i in slots.size():
		var is_equipped := charms[i] == equipped
		slots[i].modulate = Color(1.0, 0.9, 0.4) if is_equipped else Color.WHITE

# Focuses the equipped charm, or the first one if none is equipped
func focus_slot() -> void:
	if slots.is_empty():
		return
	slots[maxi(charms.find(equipped), 0)].grab_focus()
	
func _show_charm(charm: ItemData) -> void:
	charm_name.text = charm.name if charm else ""
