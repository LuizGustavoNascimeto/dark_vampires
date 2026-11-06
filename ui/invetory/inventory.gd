extends Control

signal charms_changed

@export var items: Array[ItemData] = []

@onready var grid: GridContainer = %GridContainer
@onready var name_label: Label = %TitleLabel
@onready var description_label: Label = %Description
@onready var big_icon: TextureRect = %Icon
@onready var tabs: TabContainer = %Tabs
@onready var circle: Control = %Charms

signal charm_equipped(charm: ItemData)
var equipped_charm: ItemData = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # works while the game is paused
	visible = false
	tabs.focus_mode = Control.FOCUS_NONE
	tabs.get_tab_bar().focus_mode = Control.FOCUS_NONE
	charms_changed.connect(_on_charms_changed)
	_build_slots()
	_on_charms_changed()
	circle.charm_pressed.connect(toggle_charm)
	charm_equipped.connect(circle.set_equipped)
	_build_slots()
	_on_charms_changed()


# Called by collectible items. Returns true if the item fit.
func add_item(item: ItemData) -> bool:
	items.append(item)
	_build_slots()
	if item.type == ItemData.ITEM_TYPE.CHARM:
		charms_changed.emit()
	return true


func get_charms() -> Array[ItemData]:
	var result: Array[ItemData] = []
	result.assign(items.filter(func(i: ItemData): return i.type == ItemData.ITEM_TYPE.CHARM))
	return result


func _on_charms_changed() -> void:
	circle.build(get_charms())


func _build_slots() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	for item in items:
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(64, 64)
		slot.focus_mode = Control.FOCUS_ALL
		slot.expand_icon = true
		slot.icon = item.icon
		# Focus (arrows/d-pad) updates the details panel
		slot.focus_entered.connect(_show_item.bind(item))
		# Mouse hover also selects
		slot.mouse_entered.connect(slot.grab_focus)
		grid.add_child(slot)


func _show_item(item: ItemData) -> void:
	if item == null:
		name_label.text = ""
		description_label.text = ""
		big_icon.texture = null
		return
	name_label.text = item.name
	description_label.text = item.description
	big_icon.texture = item.icon


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_inventory"):
		_toggle()
		get_viewport().set_input_as_handled()
	elif not visible:
		return
	elif event.is_action_pressed("ui_cancel"):
		_toggle()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_next"):
		_change_tab(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_previous"):
		_change_tab(-1)
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	visible = not visible
	get_tree().paused = visible
	if visible:
		_focus_current_tab.call_deferred()


func _change_tab(direction: int) -> void:
	tabs.current_tab = wrapi(tabs.current_tab + direction, 0, tabs.get_tab_count())
	_focus_current_tab.call_deferred()


func _focus_current_tab() -> void:
	match tabs.current_tab:
		0:
			if grid.get_child_count() > 0:
				grid.get_child(0).grab_focus()
		1:
			circle.focus_slot()

func toggle_charm(charm: ItemData) -> void:
	equipped_charm = null if equipped_charm == charm else charm
	charm_equipped.emit(equipped_charm)
	
func remove_item(item: ItemData) -> void:
	var index := items.find(item)
	if index == -1:
		return
	items.remove_at(index)
	_build_slots()
	if item.type == ItemData.ITEM_TYPE.CHARM:
		if equipped_charm == item:
			equipped_charm = null
			charm_equipped.emit(null)   # Player undoes the effects
		charms_changed.emit()
