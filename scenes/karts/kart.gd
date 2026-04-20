extends CharacterBody3D

@export var is_ai := false
@export var ai_target: Node3D

# -------------------------
# SPEED
# -------------------------
const MAX_FORWARD_SPEED := 55.0
const MAX_REVERSE_SPEED := 20.0
const ACCEL := 25.0
const BRAKE := 35.0
const DRAG := 20.0

const TURN_SPEED := 2.2
const GRAVITY := -20.0

const GRIP := 18.0   # sideways grip

const WHEEL_SPIN_SPEED := 5.0
const STEERING_AMOUNT := 20.0

# -------------------------
# NODES
# -------------------------
@onready var wheel_fl = $BlueberrySodaKart/Wheel_FL
@onready var wheel_fr = $BlueberrySodaKart/Wheel_FR
@onready var wheel_bl = $BlueberrySodaKart/Wheel_BL
@onready var wheel_br = $BlueberrySodaKart/Wheel_BR
@onready var steering_wheel = $BlueberrySodaKart/SteeringWheel1

# -------------------------
# STATE
# -------------------------
var current_speed := 0.0


func _physics_process(delta):

	# =========================================================
	# INPUT
	# =========================================================
	var throttle := Input.get_axis("reverse", "forward")
	var turn := Input.get_axis("right", "left")


	# =========================================================
	# GRAVITY
	# =========================================================
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0


	# =========================================================
	# SPEED CONTROL (REAL ACCELERATION)
	# =========================================================
	var max_speed = MAX_FORWARD_SPEED if throttle >= 0 else MAX_REVERSE_SPEED
	var target_speed = throttle * max_speed

	# accelerate / brake
	if abs(throttle) > 0.01:
		var accel_rate = ACCEL if sign(throttle) == sign(current_speed) else BRAKE
		current_speed = move_toward(current_speed, target_speed, accel_rate * delta)
	else:
		# natural drag when no input
		current_speed = move_toward(current_speed, 0.0, DRAG * delta)


	# =========================================================
	# TURNING (stable, no speed injection)
	# =========================================================
	var speed_ratio = clamp(abs(current_speed) / MAX_FORWARD_SPEED, 0, 1)

	if abs(current_speed) > 0.5:
		var steer_strength = TURN_SPEED * (1.0 - 0.75 * speed_ratio)
		rotation.y += turn * steer_strength * delta


	# =========================================================
	# MOVEMENT (NO MORE SPEED EXPLOSION)
	# =========================================================
	var forward_dir = -transform.basis.z
	var right_dir = transform.basis.x

	# current velocity components
	var forward_vel = velocity.dot(forward_dir)
	var side_vel = velocity.dot(right_dir)

	# smoothly match forward velocity to desired speed
	forward_vel = move_toward(forward_vel, current_speed, ACCEL * delta)

	# kill sideways sliding
	side_vel = move_toward(side_vel, 0.0, GRIP * delta)

	# rebuild velocity
	velocity = forward_dir * forward_vel + right_dir * side_vel

	# HARD SPEED CAP (final safety)
	var max_cap = MAX_FORWARD_SPEED if current_speed >= 0 else MAX_REVERSE_SPEED
	velocity = velocity.limit_length(max_cap)


	# =========================================================
	# WHEELS
	# =========================================================
	var spin = forward_vel * WHEEL_SPIN_SPEED * delta

	wheel_fl.rotation.x += spin
	wheel_fr.rotation.x += spin
	wheel_bl.rotation.x += spin
	wheel_br.rotation.x += spin

	steering_wheel.rotation.z = -turn * deg_to_rad(STEERING_AMOUNT)


	move_and_slide()
