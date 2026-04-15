extends CharacterBody3D

# movement speed
const MAX_FORWARD_SPEED = 55.0
const MAX_REVERSE_SPEED = 20.0

# acceleration / deceleration
const ACCEL = 12.0
const DECEL = 8.0

# turning speed (left and right)
const TURN_SPEED = 0.5

# pulls car down (when in air)
const GRAVITY = -20.0

const WHEEL_SPIN_SPEED = 5.0
const STEERING_AMOUNT = 20.0

# reference all wheel nodes
@onready var wheel_fl = $BlueberrySodaKart/Wheel_FL
@onready var wheel_fr = $BlueberrySodaKart/Wheel_FR
@onready var wheel_bl = $BlueberrySodaKart/Wheel_BL
@onready var wheel_br = $BlueberrySodaKart/Wheel_BR
@onready var steering_wheel = $BlueberrySodaKart/SteeringWheel1

# current movement state
var current_speed = 0.0
var horizontal_velocity = Vector3.ZERO

func _physics_process(delta):

	# -------------------------
	# GRAVITY
	# -------------------------
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

	# -------------------------
	# INPUT
	# -------------------------
	var throttle = Input.get_axis("reverse", "forward")
	var turn = Input.get_axis("right", "left")

	# -------------------------
	# SPEED (SMOOTH ENGINE)
	# -------------------------
	var target_speed = throttle * MAX_FORWARD_SPEED
	current_speed = lerp(current_speed, target_speed, 4.0 * delta)

	# -------------------------
	# TURNING (speed affects control)
	# -------------------------
	var speed_ratio = abs(current_speed) / MAX_FORWARD_SPEED
	rotation.y += turn * TURN_SPEED * (0.5 + speed_ratio) * delta

	# -------------------------
	# BASE FORWARD MOTION
	# -------------------------
	var forward = -transform.basis.z * current_speed

	# -------------------------
	# DRIFT (THIS IS THE KEY FIX)
	# -------------------------
	var right = transform.basis.x

	# sideways slip increases with speed + turning
	var drift = turn * speed_ratio * abs(current_speed) * 0.35

	var sideways = right * drift

	# -------------------------
	# FINAL VELOCITY
	# -------------------------
	var target_velocity = forward + sideways

	# smooth movement (prevents snapping)
	velocity.x = lerp(velocity.x, target_velocity.x, 8.0 * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, 8.0 * delta)

	# -------------------------
	# WHEELS
	# -------------------------
	var spin = current_speed * WHEEL_SPIN_SPEED * delta * 0.05

	wheel_fl.rotation.x += spin
	wheel_fr.rotation.x += spin
	wheel_bl.rotation.x += spin
	wheel_br.rotation.x += spin

	steering_wheel.rotation.z = -turn * deg_to_rad(STEERING_AMOUNT)

	move_and_slide()