extends ProgressBar

const DAMAGE_REDUCE_RATE = 400

@onready var timer = $Timer
@onready var damage_bar = $Damagebar

var stamina:float = 0 : set = _set_stamina
var is_stamina_reducing = false

func init_stamina(_stamina):
	self.max_value = _stamina
	damage_bar.max_value = _stamina

	self.stamina = _stamina
	self.value = _stamina
	damage_bar.value = _stamina

func _physics_process(delta: float) -> void:
	if is_stamina_reducing:
		reduce_damage_stamina(delta)

func _set_stamina(new_stamina):
	var prev_stamina = stamina
	stamina = min(max_value, new_stamina)
	self.value = stamina
	if stamina < prev_stamina:
		timer.start()
	else:
		damage_bar.value += stamina - prev_stamina

func reduce_damage_stamina(delta: float) -> void:
	var tmp = maxf(damage_bar.value - DAMAGE_REDUCE_RATE * delta, stamina)
	damage_bar.value = tmp
	if damage_bar.value <= stamina:
		is_stamina_reducing = false

func _on_timer_timeout() -> void:
	is_stamina_reducing =  true
