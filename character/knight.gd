extends CharacterBody2D

const SPEED := 300.0
const DASH_POWER := 3.5
const DASH_ROTATION_SPEED := 30.0
const DASH_COST := 45
const STAMINA_RECOVER_RATE := 60.0 #/s

@onready var body_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $HurtBox
@onready var health_bar = $CanvasLayer/Healthbar
@onready var stamina_bar = $CanvasLayer/Staminabar


@onready var dash_timer: Timer = $Timers/DashTimer
@onready var dash_cooldown_timer: Timer = $Timers/DashCooldownTimer
@onready var stamina_cooldown_timer: Timer = $Timers/StmCooldownTimer
@onready var invencible_timer: Timer = $Timers/InvencibleTimer


enum States_enum { JUMP, WALK, RUN, IDLE, HURT, DASH}
var state: States_enum = States_enum.IDLE

var max_health: int = 300
var health: int

var max_stamina: float = 200.0
var stamina: float
var is_recovering_stamina := false


var dash_direction := Vector2.ZERO
var last_move_direction := Vector2.RIGHT
var animate_dash := 0

var is_invencible := false

func _ready() -> void:
	health = max_health
	health_bar.init_health(health)
	stamina = max_stamina
	stamina_bar.init_stamina(stamina)

	dash_timer.timeout.connect(finish_dash)
	stamina_cooldown_timer.timeout.connect(start_stamina_recovery)
	invencible_timer.timeout.connect(finish_invencibility)

func _physics_process(delta: float) -> void:
	var input_direction := get_input_direction()

	if can_start_dash():
		start_dash(input_direction)

	if state == States_enum.DASH:
		apply_dash(delta)
	else:
		apply_movement(input_direction)

	if is_recovering_stamina:
		recover_stamina(delta)

	self.move_and_slide()


func get_input_direction() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")


func can_start_dash() -> bool:
	return Input.is_action_just_pressed("dash") and dash_cooldown_timer.is_stopped()


func start_dash(input_direction: Vector2) -> void:
	if stamina <= 0:
		print("ficou sem folego kkkkkkk")
		return
	var is_moving := not input_direction.is_zero_approx()

	if is_moving:
		last_move_direction = input_direction.normalized()
		dash_direction = last_move_direction
		animate_dash = 1
	else:
		dash_direction = -last_move_direction
		animate_dash = 2
	reduce_stamina(DASH_COST)
	state = States_enum.DASH
	dash_timer.start()
	dash_cooldown_timer.start()


func apply_movement(input_direction: Vector2) -> void:
	if input_direction.is_zero_approx():
		self.velocity = Vector2.ZERO
		return

	last_move_direction = input_direction.normalized()
	self.velocity = last_move_direction * SPEED


func apply_dash(delta: float) -> void:

	self.velocity = dash_direction * SPEED * DASH_POWER

	self.set_collision_mask_value(4, false)
	update_hurtbox_collision()

	if animate_dash == 1:
		body_sprite.rotate(DASH_ROTATION_SPEED * delta)
	if animate_dash == 2:
		body_sprite.scale = Vector2(1.25, 0.75)


func finish_dash() -> void:
	state = States_enum.IDLE
	self.set_collision_mask_value(4, true)
	animate_dash = 0
	update_hurtbox_collision()

	body_sprite.rotation = 0.0
	body_sprite.scale = Vector2(1, 1)

func start_invencibility() -> void:
	is_invencible = true
	invencible_timer.start()
	update_hurtbox_collision()

func finish_invencibility() -> void:
	is_invencible = false
	update_hurtbox_collision()

func update_hurtbox_collision() -> void:
	var should_be_off := is_invencible or state == States_enum.DASH
	hurtbox.set_collision_mask_value(2, not should_be_off)

func reduce_health(dmg: int) -> void:
	start_invencibility()
	health -= dmg
	if health < 0:
		health = 0
		die()
	health_bar.health = health

func reduce_stamina(stm: int) -> void:
	is_recovering_stamina = false
	stamina -= stm
	if stamina < 0:
		stamina = 0
	stamina_bar.stamina = stamina
	stamina_cooldown_timer.start()

func start_stamina_recovery() -> void:
	is_recovering_stamina = true

func recover_stamina(delta: float) -> void:
	stamina = minf(stamina + STAMINA_RECOVER_RATE * delta, max_stamina)
	stamina_bar.stamina = stamina
	if stamina >= max_stamina:
		is_recovering_stamina = false

func die() -> void:
	print("na teoria vc morreu, mas toma mais 100 de vida ai seu canalha")
	health += 100
