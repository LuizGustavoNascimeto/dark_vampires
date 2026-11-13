extends Control

signal charm_pressed(charm: ItemData)

const CHARM_SLOT_SCENE = preload("res://ui/invetory/charm-slot.tscn")

@export var slot_size := Vector2(64, 64)
@export var base_radius := 140.0
@export var slot_gap := 12.0
@export var focus_scale := 1.2
@export var animation_time := 0.2

@onready var ring: Control = %Ring
@onready var center_icon: TextureRect = %CenterIcon
@onready var charm_name: Label = %CharmName

var slots: Array[Button] = []
var charms: Array[ItemData] = []
var equipped: ItemData = null

var _ring_angle := 0.0
var _ring_tween: Tween


func build(new_charms: Array[ItemData]) -> void:
	var focused_charm := _get_focused_charm()   # must come before slots.clear()

	for child in ring.get_children():
		ring.remove_child(child)
		child.queue_free()
	slots.clear()
	charms = new_charms
	_show_charm(null)

	var count := charms.size()
	if count == 0:
		_refresh_equipped()
		return

	var radius := _get_radius(count)
	for i in count:
		var slot: Button = CHARM_SLOT_SCENE.instantiate()
		slot.custom_minimum_size = slot_size
		slot.size = slot_size
		slot.pivot_offset = slot_size / 2.0   # scale/rotate around the center
		slot.icon = charms[i].icon
		slot.pressed.connect(charm_pressed.emit.bind(charms[i]))
		slot.focus_entered.connect(_on_slot_focused.bind(i))
		slot.focus_exited.connect(_animate_slot_scale.bind(slot, 1.0))
		slot.mouse_entered.connect(slot.grab_focus)   # mouse hover selects
		ring.add_child(slot)
		slots.append(slot)

		var angle := -PI / 2.0 + i * TAU / count
		slot.position = Vector2.from_angle(angle) * radius - slot_size / 2.0

	_link_neighbors()
	_set_ring_angle(_ring_angle)   # keeps icons upright after a rebuild
	_refresh_equipped()

	if focused_charm and is_visible_in_tree():
		focus_charm.call_deferred(focused_charm)


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


# Called by Inventory when the equipped charm changes (null = nothing equipped)
func set_equipped(charm: ItemData) -> void:
	equipped = charm
	_refresh_equipped()
	_show_charm(_get_focused_charm())   # updates the "(equipado)" tag


func _refresh_equipped() -> void:
	center_icon.texture = equipped.icon if equipped else null
	for i in slots.size():
		var is_equipped := charms[i] == equipped
		slots[i].set_pressed_no_signal(is_equipped)


# Focuses the equipped charm, or the first one if none is equipped
func focus_slot() -> void:
	if slots.is_empty():
		return
	slots[maxi(charms.find(equipped), 0)].grab_focus()


func focus_charm(charm: ItemData) -> void:
	var index := charms.find(charm)
	if index == -1:
		focus_slot()
	else:
		slots[index].grab_focus()


func _get_focused_charm() -> ItemData:
	var index := slots.find(get_viewport().gui_get_focus_owner())
	return charms[index] if index != -1 else null


# ───────────── Polish ─────────────
func _on_slot_focused(index: int) -> void:
	_show_charm(charms[index])
	_animate_slot_scale(slots[index], focus_scale)
	_rotate_ring_to(-index * TAU / slots.size())


func _show_charm(charm: ItemData) -> void:
	if charm == null:
		charm_name.text = ""
		return
	charm_name.text = charm.name + (" (equipped)" if charm == equipped else "")


func _animate_slot_scale(slot: Button, target: float) -> void:
	if not is_instance_valid(slot) or not slot.is_inside_tree():
		return
	var tween := slot.create_tween()
	tween.tween_property(slot, "scale", Vector2.ONE * target, animation_time * 0.5)


func _rotate_ring_to(target: float) -> void:
	if _ring_tween:
		_ring_tween.kill()
	# angle_difference takes the shortest way around the circle
	var end := _ring_angle + angle_difference(_ring_angle, target)
	_ring_tween = create_tween()
	_ring_tween.tween_method(_set_ring_angle, _ring_angle, end, animation_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# Rotates the ring and counter-rotates every slot so the icons stay upright
func _set_ring_angle(angle: float) -> void:
	_ring_angle = angle
	ring.rotation = angle
	for slot in slots:
		slot.rotation = -angle


func _get_radius(count: int) -> float:
	if count < 2:
		return base_radius
	var min_distance := slot_size.length() + slot_gap
	var min_radius := min_distance / (2.0 * sin(PI / count))
	return maxf(base_radius, min_radius)
