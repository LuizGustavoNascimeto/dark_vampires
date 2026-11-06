extends CharacterBody2D

# ───────────── "Constantes" ─────────────
const SPEED := 125.0
const DASH_POWER := 2.5
const DASH_ROTATION_SPEED := 30.0
const DASH_COST := 45
var STAMINA_RECOVER_RATE := 90.0 # por segundo

# ───────────── Nodes ─────────────
@onready var body_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $HurtBox
@onready var health_bar = $CanvasLayer/Healthbar
@onready var stamina_bar = $CanvasLayer/Staminabar
@onready var inventory: Control = %Inventory  
@onready var interaction_label: MarginContainer = $CanvasLayer/InteractionLabel


@onready var dust_particles: GPUParticles2D = $Particles/DustParticles
@onready var blood_particles_2d: GPUParticles2D = $Particles/BloodParticles2D

@onready var dash_timer: Timer = $Timers/DashTimer
@onready var dash_cooldown_timer: Timer = $Timers/DashCooldownTimer
@onready var stamina_cooldown_timer: Timer = $Timers/StmCooldownTimer
@onready var invencible_timer: Timer = $Timers/InvencibleTimer
@onready var damage_style := stamina_bar.damage_bar.get_theme_stylebox("fill") as StyleBoxFlat

# ───────────── Estado ─────────────
enum States_enum { IDLE, WALK, DASH }
var state: States_enum = States_enum.IDLE

# Vida
var max_health: int = 300
var health: int

# Stamina
var max_stamina: float = 200.0
var stamina: float
var is_recovering_stamina := false

# Direção / dash
var last_move_direction := Vector2.RIGHT # também usada como "para onde está olhando"
var dash_direction := Vector2.ZERO
var animate_dash := 0 # 0 = nenhum, 1 = rolando, 2 = recuo

var is_invencible := false

#INVETORY
var equipped_charm: ItemData = null

# ───────────── Ciclo de vida ─────────────
func _ready() -> void:
	health = max_health
	health_bar.init_health(health)
	stamina = max_stamina
	stamina_bar.init_stamina(stamina)

	dash_timer.timeout.connect(finish_dash)
	stamina_cooldown_timer.timeout.connect(start_stamina_recovery)
	invencible_timer.timeout.connect(finish_invencibility)
	inventory.charm_equipped.connect(_on_charm_equipped)


func _physics_process(delta: float) -> void:
	var input_direction := get_input_direction()

	if can_start_dash():
		start_dash(input_direction)

	if state == States_enum.DASH:
		apply_dash(delta)
	else:
		apply_movement(input_direction)
	
	update_animation()

	if is_recovering_stamina:
		recover_stamina(delta)

	move_and_slide()


# ───────────── Input ─────────────
func get_input_direction() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")


func can_start_dash() -> bool:
	return Input.is_action_just_pressed("dash") \
		and dash_cooldown_timer.is_stopped() \
		and state != States_enum.DASH


# ───────────── Movimento ─────────────
func apply_movement(input_direction: Vector2) -> void:
	if input_direction.is_zero_approx():
		state = States_enum.IDLE
		velocity = Vector2.ZERO
		dust_particles.emitting = false
		return

	state = States_enum.WALK
	last_move_direction = input_direction.normalized()
	velocity = last_move_direction * SPEED
	dust_particles.emitting = true


# ───────────── Dash ─────────────
func start_dash(input_direction: Vector2) -> void:
	if stamina <= 0:
		print("ficou sem folego kkkkkkk")
		return

	if input_direction.is_zero_approx():
		# Parado: recua para trás
		dash_direction = -last_move_direction
		animate_dash = 2
	else:
		last_move_direction = input_direction.normalized()
		dash_direction = last_move_direction
		animate_dash = 1

	reduce_stamina(DASH_COST)
	state = States_enum.DASH
	dust_particles.emitting = false
	set_collision_mask_value(4, false)
	update_hurtbox_collision()
	dash_timer.start()
	dash_cooldown_timer.start()


func apply_dash(delta: float) -> void:
	velocity = dash_direction * SPEED * DASH_POWER

	if animate_dash == 1:
		body_sprite.rotate(DASH_ROTATION_SPEED * delta)
	elif animate_dash == 2:
		body_sprite.scale = Vector2(1.25, 0.75)


func finish_dash() -> void:
	state = States_enum.IDLE
	animate_dash = 0
	set_collision_mask_value(4, true)
	update_hurtbox_collision()

	body_sprite.rotation = 0.0
	body_sprite.scale = Vector2.ONE


# ───────────── Animação ─────────────
func update_animation() -> void:
	var prefix := "run" if state == States_enum.WALK else "idle"
	play_animation(prefix, last_move_direction)


func play_animation(prefix: String, facing: Vector2) -> void:
	# Horizontal tem prioridade (igual ao original); senão cima/baixo
	if not is_zero_approx(facing.x):
		body_sprite.flip_h = facing.x < 0
		body_sprite.play(prefix + "_right")
	elif facing.y < 0:
		body_sprite.play(prefix + "_up")
	else:
		body_sprite.play(prefix + "_down")


# ───────────── Invencibilidade / Hurtbox ─────────────
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


# ───────────── Vida ─────────────
func reduce_health(dmg: int) -> void:
	start_invencibility()
	health -= dmg
	blood_particles_2d.emitting = true
	if health <= 0:
		die()
	health_bar.health = health


func die() -> void:
	print("na teoria vc morreu, mas toma mais 100 de vida ai seu canalha")
	health = 100


# ───────────── Stamina ─────────────
func reduce_stamina(stm: int) -> void:
	is_recovering_stamina = false
	stamina = maxf(stamina - stm, 0.0)
	stamina_bar.stamina = stamina
	stamina_cooldown_timer.start()


func start_stamina_recovery() -> void:
	is_recovering_stamina = true


func recover_stamina(delta: float) -> void:
	stamina = minf(stamina + STAMINA_RECOVER_RATE * delta, max_stamina)
	stamina_bar.stamina = stamina
	if stamina >= max_stamina:
		is_recovering_stamina = false
		
func show_interaction(text: String) -> void:
	var label: Label = interaction_label.get_child(0)
	label.text = text
	interaction_label.visible = true

func hide_interaction() -> void:
	interaction_label.visible = false

func _on_charm_equipped(charm: ItemData) -> void:
	_remove_charm_effects(equipped_charm)
	equipped_charm = charm
	_apply_charm_effects(charm)


func _apply_charm_effects(charm: ItemData) -> void:
	print("deu BO AQUI")
	if charm == null:
		return
	if charm.name_code == "cloranth-shield":
		STAMINA_RECOVER_RATE *= (1 + charm.numeric_buff)
		stamina_cooldown_timer.wait_time /= (1.0 + charm.numeric_buff)
		damage_style.bg_color = Color.YELLOW
		return
	# example: speed += charm.speed_bonus


func _remove_charm_effects(charm: ItemData) -> void:
	if charm == null:
		return
	if charm.name_code == "cloranth-shield":
		STAMINA_RECOVER_RATE /= (1 + charm.numeric_buff)
		stamina_cooldown_timer.wait_time *= (1.0 + charm.numeric_buff)
		damage_style.bg_color = Color.WHITE
		return
