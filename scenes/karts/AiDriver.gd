extends Node

@export var vehicle: Kart
@export var path: Path3D

var smoothed_turn := 0.0
var distance := 0.0


func _process(delta):

	if vehicle == null or path == null:
		return

	var curve = path.curve
	var curve_length = curve.get_baked_length()

	# -------------------------------------------------
	# 1. PROGRESS ALONG TRACK (stable advancement)
	# -------------------------------------------------
	distance += abs(vehicle.current_speed) * delta
	distance = fposmod(distance, curve_length)

	# -------------------------------------------------
	# 2. MULTI LOOKAHEAD (smarter steering target)
	# -------------------------------------------------
	var look1 = fposmod(distance + 4.0, curve_length)
	var look2 = fposmod(distance + 8.0, curve_length)
	var look3 = fposmod(distance + 14.0, curve_length)

	var p1 = path.to_global(curve.sample_baked(look1))
	var p2 = path.to_global(curve.sample_baked(look2))
	var p3 = path.to_global(curve.sample_baked(look3))

	# weighted target (near matters more than far)
	var target_pos = (p1 * 0.5 + p2 * 0.3 + p3 * 0.2)

	# direction toward combined target
	var to_target = target_pos - vehicle.global_position
	to_target.y = 0
	to_target = to_target.normalized()

	# -------------------------------------------------
	# 3. VEHICLE FORWARD DIRECTION
	# -------------------------------------------------
	var forward = -vehicle.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	# -------------------------------------------------
	# 4. STEERING ANGLE (COMPARE DIRECTIONS)
	# -------------------------------------------------
	var angle = forward.signed_angle_to(to_target, Vector3.UP)

	# -------------------------------------------------
	# 5. STEERING SMOOTHING (REMOVE JITTER)
	# -------------------------------------------------
	var raw_turn = clamp(angle * 1.2, -1.0, 1.0)

	# deadzone kills micro-correction swirl
	if abs(angle) < 0.04:
		raw_turn = 0.0

	smoothed_turn = lerp(smoothed_turn, raw_turn, 5.0 * delta)

	vehicle.turn = smoothed_turn

	# -------------------------------------------------
	# 6. SPEED CONTROL
	# -------------------------------------------------
	var speed_factor = 1.0 - clamp(abs(angle) * 1.3, 0.0, 1.0)
	vehicle.throttle = lerp(0.35, 1.0, speed_factor)

	# -------------------------------------------------
	# 7. DEBUG
	# -------------------------------------------------
	if Engine.get_physics_frames() % 10 == 0:
		print("POS:", vehicle.global_position)
		print("DIR:", to_target)