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
	# 2. GET ROAD DIRECTION (TANGENT, NOT POINT CHASING)
	# -------------------------------------------------
	var p1 = curve.sample_baked(distance)
	var p2 = curve.sample_baked(distance + 5.0)

	var p1_world = path.to_global(p1)
	var p2_world = path.to_global(p2)

	var path_dir = (p2_world - p1_world).normalized()

	# -------------------------------------------------
	# 3. VEHICLE FORWARD DIRECTION
	# -------------------------------------------------
	var forward = -vehicle.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	# -------------------------------------------------
	# 4. STEERING ANGLE (COMPARE DIRECTIONS)
	# -------------------------------------------------
	var angle = forward.signed_angle_to(path_dir, Vector3.UP)

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
		print("DIR:", path_dir)