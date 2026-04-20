extends Node

@export var vehicle: CharacterBody3D
@export var target: Node3D

# tuning
const MAX_LOOKAHEAD := 25.0
const MIN_LOOKAHEAD := 6.0
const TURN_STRENGTH := 1.8
const SMOOTHING := 6.0

var smoothed_turn := 0.0


func _process(delta):

	# =========================================================
	# VALIDATION
	# =========================================================
	if not vehicle or not target:
		return


	# =========================================================
	# DIRECTION SETUP
	# =========================================================
	var forward = -vehicle.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	var to_target = target.global_position - vehicle.global_position
	to_target.y = 0

	var distance = to_target.length()
	var dir_to_target = to_target.normalized()


	# =========================================================
	# LOOKAHEAD (CRITICAL FIX)
	# =========================================================
	var lookahead = clamp(distance * 0.25, MIN_LOOKAHEAD, MAX_LOOKAHEAD)

	var steering_point = target.global_position + dir_to_target * lookahead
	var desired_dir = (steering_point - vehicle.global_position)
	desired_dir.y = 0
	desired_dir = desired_dir.normalized()


	# =========================================================
	# TURNING (SMOOTH + STABLE)
	# =========================================================
	var angle = forward.signed_angle_to(desired_dir, Vector3.UP)

	var raw_turn = clamp(angle * TURN_STRENGTH, -1.0, 1.0)

	# smooth steering (prevents twitching)
	smoothed_turn = lerp(smoothed_turn, raw_turn, SMOOTHING * delta)

	vehicle.turn = smoothed_turn


	# =========================================================
	# THROTTLE (SMART SPEED CONTROL)
	# =========================================================
	var turn_amount = abs(angle)

	if turn_amount > 0.7:
		vehicle.throttle = 0.25   # sharp turn → slow
	elif turn_amount > 0.4:
		vehicle.throttle = 0.55
	else:
		vehicle.throttle = 0.85  # straight → full speed
