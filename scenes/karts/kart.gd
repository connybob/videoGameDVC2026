extends CharacterBody3D

@export var is_ai := false
@export var ai_target: Node3D

# -------------------------
# SPEED
# -------------------------
const MAX_FORWARD_SPEED := 55.0
const MAX_REVERSE_SPEED := 20.0
const ACCEL := 18.0
const TURN_SPEED := 2.5
const GRAVITY := -20.0

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
	# INPUT (PLAYER OR AI)
	# =========================================================
	var throttle := 0.0
	var turn := 0.0

	if is_ai and ai_target:
		# -------------------------
		# AI STEERING (STABLE)
		# -------------------------
		var forward = -transform.basis.z
		forward.y = 0
		forward = forward.normalized()

		var to_target = ai_target.global_position - global_position
		to_target.y = 0
		to_target = to_target.normalized()

		var angle = forward.signed_angle_to(to_target, Vector3.UP)

		turn = clamp(angle * 2.5, -1.0, 1.0)

		# smooth AI acceleration (prevents rocket start)
		throttle = 0.7
	else:
		throttle = Input.get_axis("reverse", "forward")
		turn = Input.get_axis("right", "left")


	# =========================================================
	# GRAVITY
	# =========================================================
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0


	# =========================================================
	# SPEED (CLEAN ACCELERATION MODEL)
	# =========================================================
	var target_speed := 0.0

	if throttle >= 0.0:
		target_speed = throttle * MAX_FORWARD_SPEED
	else:
		target_speed = throttle * MAX_REVERSE_SPEED

	current_speed = move_toward(current_speed, target_speed, ACCEL * delta)


	# =========================================================
	# TURNING (SCALES WITH SPEED)
	# =========================================================
	var speed_ratio = abs(current_speed) / MAX_FORWARD_SPEED

	var horizontal_speed = Vector3(velocity.x, 0, velocity.z).length()
	var moving = horizontal_speed > 0.5

	if moving:
		var steer_strength = TURN_SPEED * lerp(0.6, 1.4, speed_ratio)
		rotation.y += turn * steer_strength * delta


	# =========================================================
	# MOVEMENT
	# =========================================================
	var forward_dir = -transform.basis.z
	var right_dir = transform.basis.x

	var forward_vel = forward_dir * current_speed

	# small arcade drift (intentional, but controlled)
	var side_vel = right_dir * (turn * speed_ratio * current_speed * 0.2)

	var target_velocity = forward_vel + side_vel

	# smooth movement response
	var response = lerp(12.0, 6.0, speed_ratio) * delta

	velocity.x = move_toward(velocity.x, target_velocity.x, response)
	velocity.z = move_toward(velocity.z, target_velocity.z, response)


	# =========================================================
	# WHEELS
	# =========================================================
	var spin = current_speed * WHEEL_SPIN_SPEED * delta

	wheel_fl.rotation.x += spin
	wheel_fr.rotation.x += spin
	wheel_bl.rotation.x += spin
	wheel_br.rotation.x += spin

	steering_wheel.rotation.z = -turn * deg_to_rad(STEERING_AMOUNT)


	move_and_slide()
