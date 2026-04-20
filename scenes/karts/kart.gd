extends CharacterBody3D

@export var is_ai := false
@export var ai_target: Node3D

# -------------------------
# SPEED
# -------------------------
const MAX_FORWARD_SPEED = 55.0
const MAX_REVERSE_SPEED = 20.0

const ACCEL = 12.0
const DECEL = 8.0

const TURN_SPEED = 0.5
const GRAVITY = -20.0

const WHEEL_SPIN_SPEED = 5.0
const STEERING_AMOUNT = 20.0

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
var current_speed = 0.0

func _physics_process(delta):

	# -------------------------
	# INPUT
	# -------------------------
	var throttle = 0.0
	var turn = 0.0

	if is_ai:
		# =========================
		# AI STEERING (FIXED)
		# =========================
		if ai_target:
			var to_target = (ai_target.global_position - global_position).normalized()
			var forward = -transform.basis.z

			# steering direction (-1 left, +1 right)
			turn = forward.cross(to_target).y

		throttle = 1.0
	else:
		throttle = Input.get_axis("reverse", "forward")
		turn = Input.get_axis("right", "left")

	# -------------------------
	# GRAVITY
	# -------------------------
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

	# -------------------------
	# SPEED
	# -------------------------
	var target_speed = throttle * MAX_FORWARD_SPEED
	current_speed = lerp(current_speed, target_speed, 4.0 * delta)

	# -------------------------
	# TURNING
	# -------------------------
	var speed_ratio = abs(current_speed) / MAX_FORWARD_SPEED
	rotation.y += turn * TURN_SPEED * (0.5 + speed_ratio) * delta

	# -------------------------
	# DRIFT PHYSICS
	# -------------------------
	var forward = -transform.basis.z * current_speed
	var right = transform.basis.x

	var drift_strength = turn * speed_ratio * abs(current_speed) * 0.35
	var sideways = right * drift_strength

	var target_velocity = forward + sideways

	var retention = clamp(1.0 - (2.2 * delta), 0.88, 1.0)

	velocity.x = velocity.x * retention + target_velocity.x * (1.0 - retention)
	velocity.z = velocity.z * retention + target_velocity.z * (1.0 - retention)

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
