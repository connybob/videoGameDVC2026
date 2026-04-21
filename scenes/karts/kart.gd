extends CharacterBody3D

# --- SPEED (Mario Kart-style feel) ---
const MAX_FORWARD_SPEED = 40.0
const MAX_REVERSE_SPEED = 14.0
const TURN_SPEED        = 0.58
const GRAVITY           = -20.0
const WHEEL_SPIN_SPEED  = 5.0
const STEERING_AMOUNT   = 20.0

# --- DRIFT ---
const DRIFT_TURN_MULTIPLIER = 1.30   # tighter arc while drifting
const DRIFT_COUNTERSTEER    = 0.18   # how much you can fight the drift
const DRIFT_SLIP            = 0.22   # sideways grip loss (lower = less slippery)
const DRIFT_MIN_SPEED       = 10.0
const DRIFT_TILT_ANGLE      = 0.09
const DRIFT_TILT_SPEED      = 10.0

# boost tiers: [min_charge_secs, top_speed_during_boost, duration]
const BOOST_MINI  = [0.8,  50.0, 0.9]
const BOOST_SUPER = [1.8,  60.0, 1.4]

# --- NODE REFS ---
@onready var wheel_fl      = $BlueberrySodaKart/Wheel_FL
@onready var wheel_fr      = $BlueberrySodaKart/Wheel_FR
@onready var wheel_bl      = $BlueberrySodaKart/Wheel_BL
@onready var wheel_br      = $BlueberrySodaKart/Wheel_BR
@onready var steering_wheel = $BlueberrySodaKart/SteeringWheel1
@onready var kart_model    = $BlueberrySodaKart

# --- MOVEMENT STATE ---
var current_speed := 0.0

# --- DRIFT STATE ---
var is_drifting  := false
var drift_dir    := 0
var drift_charge := 0.0
var drift_tilt   := 0.0

# --- BOOST STATE ---
var boost_timer := 0.0
var boost_speed := 0.0


func _physics_process(delta: float) -> void:

	# ── GRAVITY ──────────────────────────────────────────
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

	# ── INPUT ─────────────────────────────────────────────
	var throttle      := Input.get_axis("reverse", "forward")
	var turn          := Input.get_axis("right", "left")
	var drift_pressed := Input.is_action_pressed("drift")

	# ── BOOST ─────────────────────────────────────────────
	if boost_timer > 0:
		boost_timer   -= delta
		current_speed  = lerp(current_speed, boost_speed, 10.0 * delta)
	else:
		var target_speed := throttle * MAX_FORWARD_SPEED
		current_speed = lerp(current_speed, target_speed, 3.0 * delta)

	var speed_ratio: float = absf(current_speed) / MAX_FORWARD_SPEED

	# ── DRIFT ─────────────────────────────────────────────
	var can_drift: bool = drift_pressed and is_on_floor() and absf(current_speed) > DRIFT_MIN_SPEED

	if can_drift:
		if not is_drifting:
			drift_dir    = 1 if turn >= 0.0 else -1
			is_drifting  = true
			drift_charge = 0.0

		drift_charge += delta

		var arc_turn := drift_dir * TURN_SPEED * DRIFT_TURN_MULTIPLIER * speed_ratio
		var steer    := turn * TURN_SPEED * DRIFT_COUNTERSTEER * speed_ratio
		rotation.y  += (arc_turn + steer) * delta

		drift_tilt = lerp(drift_tilt, -drift_dir * DRIFT_TILT_ANGLE, DRIFT_TILT_SPEED * delta)
	else:
		if is_drifting:
			_apply_boost()

		is_drifting  = false
		drift_charge = 0.0
		drift_tilt   = lerp(drift_tilt, 0.0, DRIFT_TILT_SPEED * delta)

		rotation.y += turn * TURN_SPEED * (0.5 + speed_ratio) * delta

	kart_model.rotation.z = drift_tilt

	# ── VELOCITY ──────────────────────────────────────────
	var forward    := -transform.basis.z * current_speed
	var right      := transform.basis.x
	var slip_input: float = float(drift_dir) if is_drifting else turn
	var slip_amt: float   = DRIFT_SLIP if is_drifting else 0.18
	var sideways: Vector3 = right * slip_input * speed_ratio * absf(current_speed) * slip_amt

	var target_vel: Vector3 = forward + sideways
	var retention: float    = clampf(1.0 - (2.2 * delta), 0.88, 1.0)
	if is_drifting:
		retention = clamp(1.0 - (1.2 * delta), 0.85, 1.0)

	velocity.x = velocity.x * retention + target_vel.x * (1.0 - retention)
	velocity.z = velocity.z * retention + target_vel.z * (1.0 - retention)

	# ── WHEELS ────────────────────────────────────────────
	var spin := current_speed * WHEEL_SPIN_SPEED * delta * 0.05
	wheel_fl.rotation.x += spin
	wheel_fr.rotation.x += spin
	wheel_bl.rotation.x += spin
	wheel_br.rotation.x += spin

	steering_wheel.rotation.z = -turn * deg_to_rad(STEERING_AMOUNT)

	move_and_slide()
