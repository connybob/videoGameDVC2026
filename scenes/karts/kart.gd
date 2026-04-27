class_name Kart
extends CharacterBody3D

@export var is_ai := false

# ───────── SPEED ─────────
const MAX_FORWARD_SPEED := 50.0
const MAX_REVERSE_SPEED := 14.0
const ACCEL := 20.0
const BRAKE := 30.0
const DRAG := 12.0
const TURN_SPEED := 0.65
const GRAVITY := -20.0

# ───────── DRIFT ─────────
const DRIFT_TURN_MULTIPLIER := 1.3
const DRIFT_SLIP := 0.25
const DRIFT_MIN_SPEED := 10.0

# ───────── BOOST ─────────
const BOOST_MINI := [0.8, 50.0, 0.9]
const BOOST_SUPER := [1.8, 60.0, 1.4]

# ───────── NODES ─────────
@onready var wheel_fl = $BlueberrySodaKart/Wheel_FL
@onready var wheel_fr = $BlueberrySodaKart/Wheel_FR
@onready var wheel_bl = $BlueberrySodaKart/Wheel_BL
@onready var wheel_br = $BlueberrySodaKart/Wheel_BR
@onready var steering_wheel = $BlueberrySodaKart/SteeringWheel1
@onready var kart_model = $BlueberrySodaKart

# ───────── STATE ─────────
var current_speed := 0.0
var throttle := 0.0
var turn := 0.0

var is_drifting := false
var drift_dir := 0
var drift_charge := 0.0

var boost_timer := 0.0
var boost_speed := 0.0


func _physics_process(delta):

	# ── INPUT (PLAYER ONLY) ──
	#if not is_ai:
	#	throttle = Input.get_axis("reverse", "forward")
	#	turn = Input.get_axis("right", "left")

	# ── GRAVITY ──
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

	# ── BOOST ──
	if boost_timer > 0:
		boost_timer -= delta
		current_speed = lerp(current_speed, boost_speed, 10.0 * delta)
	else:
		var target_speed = throttle * MAX_FORWARD_SPEED
		var accel = ACCEL if abs(throttle) > 0.01 else DRAG
		current_speed = move_toward(current_speed, target_speed, accel * delta)

	var speed_ratio = abs(current_speed) / MAX_FORWARD_SPEED

	# ── DRIFT INPUT ──
	var drift_pressed := Input.is_action_pressed("drift")
	var can_drift: bool = drift_pressed and is_on_floor() and abs(current_speed) > DRIFT_MIN_SPEED

	if can_drift:
		if not is_drifting:
			drift_dir = 1 if turn >= 0 else -1
			is_drifting = true
			drift_charge = 0.0

		drift_charge += delta

		var drift_turn = drift_dir * TURN_SPEED * DRIFT_TURN_MULTIPLIER * speed_ratio
		rotation.y += drift_turn * delta

		kart_model.rotation.z = lerp(kart_model.rotation.z, -drift_dir * 0.1, 10 * delta)

	else:
		if is_drifting:
			_apply_boost()

		is_drifting = false
		kart_model.rotation.z = lerp(kart_model.rotation.z, 0.0, 10 * delta)

		rotation.y += turn * TURN_SPEED * (0.5 + speed_ratio) * delta

	# ── MOVEMENT ──
	var forward = -transform.basis.z * current_speed
	var right = transform.basis.x

	var slip = DRIFT_SLIP if is_drifting else 0.18
	var side = right * turn * speed_ratio * abs(current_speed) * slip

	var target_vel = forward + side
	var smooth = 0.9

	velocity.x = lerp(velocity.x, target_vel.x, smooth)
	velocity.z = lerp(velocity.z, target_vel.z, smooth)

	# ── WHEELS ──
	var spin = current_speed * 0.02
	wheel_fl.rotation.x += spin
	wheel_fr.rotation.x += spin
	wheel_bl.rotation.x += spin
	wheel_br.rotation.x += spin

	move_and_slide()
<<<<<<< HEAD
=======


func _apply_boost():
	if drift_charge >= BOOST_SUPER[0]:
		boost_speed = BOOST_SUPER[1]
		boost_timer = BOOST_SUPER[2]
	elif drift_charge >= BOOST_MINI[0]:
		boost_speed = BOOST_MINI[1]
		boost_timer = BOOST_MINI[2]
>>>>>>> c929abfada6cc00a3fa420d7c84928822c92ebac
