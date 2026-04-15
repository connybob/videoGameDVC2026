extends CharacterBody3D

# movement speed
const MAX_FORWARD_SPEED = 55.0
const MAX_REVERSE_SPEED = 20.0

# acceleration / deceleration
const ACCEL = 12.0
const DECEL = 8.0

# turning speed (left and right)
const TURN_SPEED = 2.0

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

func _physics_process(delta):

	# gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# input (-1 reverse, 1 forward)
	var input = Input.get_axis("reverse", "forward")

	# TARGET SPEED based on input
	var target_speed = 0.0
	if input > 0:
		target_speed = MAX_FORWARD_SPEED
	elif input < 0:
		target_speed = -MAX_REVERSE_SPEED

	# ACCELERATION / DECELERATION toward target speed
	if current_speed < target_speed:
		current_speed += ACCEL * delta
	elif current_speed > target_speed:
		current_speed -= DECEL * delta

	# stop tiny drifting
	if abs(input) < 0.1:
		current_speed = move_toward(current_speed, 0, DECEL * delta)

	# clamp speeds
	current_speed = clamp(current_speed, -MAX_REVERSE_SPEED, MAX_FORWARD_SPEED)

	# MOVE in facing direction
	velocity = -transform.basis.z * current_speed

	# turning
	var turn = Input.get_axis("right", "left")
	rotation.y += turn * TURN_SPEED * delta

	# wheel spinning (based on movement)
	wheel_fl.rotation.x += current_speed * WHEEL_SPIN_SPEED * delta * 0.05
	wheel_fr.rotation.x += current_speed * WHEEL_SPIN_SPEED * delta * 0.05
	wheel_bl.rotation.x += current_speed * WHEEL_SPIN_SPEED * delta * 0.05
	wheel_br.rotation.x += current_speed * WHEEL_SPIN_SPEED * delta * 0.05

	# steering wheel visual
	steering_wheel.rotation.z = -turn * deg_to_rad(STEERING_AMOUNT)

	# apply movement
	move_and_slide()