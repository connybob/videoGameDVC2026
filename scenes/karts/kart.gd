class_name Kart
extends CharacterBody3D

@export var is_ai := false

# ───────── SPEED ─────────
const MAX_FORWARD_SPEED := 50.0
const MAX_REVERSE_SPEED := 14.0
const ACCEL := 20.0
const DRAG := 12.0
const TURN_SPEED := 0.95
const GRAVITY := -20.0

# ───────── DRIFT ─────────
const DRIFT_TURN_MULTIPLIER := 1.3
const DRIFT_SLIP := 0.25
const DRIFT_MIN_SPEED := 15.0
const DRIFT_HOP_HEIGHT := 2.5

# ───────── WALL BEHAVIOR ─────────
const BOUNCE_FACTOR := 0.4
const STUN_TIME := 0.2

# ───────── BOOST ─────────
const BOOST_MINI := [0.8, 50.0, 0.9]
const BOOST_SUPER := [1.8, 60.0, 1.4]

# ───────── NODES ─────────
@onready var wheel_fl = $BlueberrySodaKart/Wheel_FL
@onready var wheel_fr = $BlueberrySodaKart/Wheel_FR
@onready var wheel_bl = $BlueberrySodaKart/Wheel_BL
@onready var wheel_br = $BlueberrySodaKart/Wheel_BR
@onready var kart_model := get_node_or_null("BlueberrySodaKart")

# ───────── STATE ─────────
var current_speed := 0.0
var throttle := 0.0
var turn := 0.0

var is_drifting := false
var drift_dir := 0
var drift_charge := 0.0

var boost_timer := 0.0
var boost_speed := 0.0

var stun_timer := 0.0


# ─────────────────────────────────────────────
# MAIN PHYSICS LOOP
# ─────────────────────────────────────────────
func _physics_process(delta):

	# =========================
	# INPUT (AI OR PLAYER)
	# =========================
	if not is_ai:
		throttle = Input.get_axis("reverse", "forward")
		turn = Input.get_axis("right", "left")

	# =========================
	# STUN (wall hit penalty)
	# =========================
	if stun_timer > 0:
		stun_timer -= delta
		throttle = 0.0
		turn *= 0.3

	# =========================
	# GRAVITY
	# =========================
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

	# =========================
	# BOOST / SPEED CONTROL
	# =========================
	if boost_timer > 0:
		boost_timer -= delta
		current_speed = lerp(current_speed, boost_speed, 10.0 * delta)
	else:
		var target_speed = throttle * MAX_FORWARD_SPEED
		var accel = ACCEL if abs(throttle) > 0.01 else DRAG
		current_speed = move_toward(current_speed, target_speed, accel * delta)

	var speed_ratio = abs(current_speed) / MAX_FORWARD_SPEED

	# =========================
	# DRIFT (simplified but stable)
	# =========================
	var drift_pressed := Input.is_action_pressed("drift")
	var drift_just_pressed := Input.is_action_just_pressed("drift")

	if drift_just_pressed and is_on_floor() and abs(current_speed) > DRIFT_MIN_SPEED:
		velocity.y = DRIFT_HOP_HEIGHT

	if abs(turn) > 0.1:
		drift_dir = 1 if turn > 0 else -1
		is_drifting = true
		drift_charge = 0.0

	if drift_pressed and abs(current_speed) > DRIFT_MIN_SPEED:
		if is_drifting:
			drift_charge += delta

			var drift_turn = (drift_dir * TURN_SPEED * DRIFT_TURN_MULTIPLIER) * speed_ratio
			rotation.y += drift_turn * delta

			kart_model.rotation.z = lerp(kart_model.rotation.z, -drift_dir * 0.15, 10 * delta)
	else:
		if is_drifting:
			_apply_boost()

		is_drifting = false
		drift_dir = 0
		kart_model.rotation.z = lerp(kart_model.rotation.z, 0.0, 10 * delta)

		rotation.y += turn * TURN_SPEED * (0.5 + speed_ratio) * delta

	# =========================
	# MOVEMENT
	# =========================
	var forward = -transform.basis.z * current_speed
	var right = transform.basis.x

	var slip = DRIFT_SLIP if is_drifting else 0.18
	var side = right * turn * speed_ratio * abs(current_speed) * slip

	velocity.x = lerp(velocity.x, forward.x + side.x, 0.9)
	velocity.z = lerp(velocity.z, forward.z + side.z, 0.9)

	# =========================
	# PHYSICS STEP
	# =========================
	move_and_slide()

	_handle_wall_collision()

	# =========================
	# WHEELS
	# =========================
	var spin = current_speed * 0.02
	wheel_fl.rotation.x += spin
	wheel_fr.rotation.x += spin
	wheel_bl.rotation.x += spin
	wheel_br.rotation.x += spin

func _handle_wall_collision():

	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var normal = col.get_normal()

		if normal.y > 0.5:
			continue

		velocity = velocity.bounce(normal) * BOUNCE_FACTOR
		current_speed *= BOUNCE_FACTOR
		stun_timer = STUN_TIME
		break


func _apply_boost():
	if drift_charge >= BOOST_SUPER[0]:
		boost_speed = BOOST_SUPER[1]
		boost_timer = BOOST_SUPER[2]
	elif drift_charge >= BOOST_MINI[0]:
		boost_speed = BOOST_MINI[1]
		boost_timer = BOOST_MINI[2]
