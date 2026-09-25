extends ProgressBar

const DAMAGE_REDUCE_RATE = 50

@onready var timer = $Timer
@onready var damage_bar = $DamageBar

var health: int = 0 : set = _set_health
var is_health_reducing = false

func _physics_process(delta: float) -> void:
	if is_health_reducing:
		reduce_damage_health(delta)

func _set_health(new_health):
	var prev_health = health
	health = min(max_value, new_health)
	self.value = health

	if health < prev_health:
		timer.start()
	else:
		damage_bar.value = health


func init_health(_health):
	self.max_value = _health
	damage_bar.max_value = _health

	self.health = _health
	self.value = _health
	damage_bar.value = _health

func reduce_damage_health(delta: float) -> void:
	var tmp = maxf(damage_bar.value - DAMAGE_REDUCE_RATE * delta, health)
	damage_bar.value = tmp
	if damage_bar.value <= health:
		is_health_reducing = false

func _on_timer_timeout() -> void:
	is_health_reducing = true
