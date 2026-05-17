extends Node

@export var vehicle: Kart
@export var path: Path3D

var smoothed_turn := 0.0
var distance := 0.0

# =================================================
# STATE
# =================================================
var last_position := Vector3.ZERO
var stuck_timer := 0.0

var reversing := false
var reverse_remaining := 0.0


# =================================================
# RAYCAST
# =================================================
func cast_ray(space_state, origin: Vector3, dir: Vector3, length := 2.5):
	var query = PhysicsRayQueryParameters3D.create(
		origin,
		origin + dir * length
	)
	query.exclude = [vehicle]
	return space_state.intersect_ray(query)


# =================================================
# TURN SHARPNESS (CURVE ANALYSIS)
# =================================================
func get_turn_sharpness(curve, d, path):
	var a = path.to_global(curve.sample_baked(d))
	var b = path.to_global(curve.sample_baked(d + 6.0))
	var c = path.to_global(curve.sample_baked(d + 12.0))

	var ab = (b - a)
	var bc = (c - b)

	ab.y = 0
	bc.y = 0

	if ab.length() < 0.001 or bc.length() < 0.001:
		return 0.0

	return abs(rad_to_deg(
		ab.normalized().signed_angle_to(bc.normalized(), Vector3.UP)
	))


# =================================================
# CLAMP TARGET TO PATH (IMPORTANT STABILITY FIX)
# =================================================
func clamp_to_path(target: Vector3, path_point: Vector3, max_offset: float):
	var offset = target - path_point
	var d = offset.length()

	if d > max_offset:
		offset = offset.normalized() * max_offset

	return path_point + offset


func _process(delta):

	if vehicle == null or path == null:
		return

	var curve = path.curve
	var curve_length = curve.get_baked_length()

	# =================================================
	# TRACK PROGRESS
	# =================================================
	distance += abs(vehicle.current_speed) * delta
	distance = fposmod(distance, curve_length)

	# =================================================
	# STUCK DETECTION
	# =================================================
	var speed = vehicle.velocity.length()
	var movement = vehicle.global_position.distance_to(last_position)
	last_position = vehicle.global_position

	if not reversing:
		if speed < 1.0 and movement < 0.05:
			stuck_timer += delta
		else:
			stuck_timer = 0.0

		if stuck_timer > 1.0:
			reversing = true
			reverse_remaining = 1.2
			stuck_timer = 0.0
			smoothed_turn = 0.0

	# =================================================
	# LOOKAHEAD (CONTROLLED + BOUNDED)
	# =================================================
	speed = vehicle.velocity.length()

	var look_near = clamp(speed * 0.25, 4.0, 8.0)
	var look_far  = look_near * 1.8

	var d_near = fposmod(distance + look_near, curve_length)
	var d_far  = fposmod(distance + look_far, curve_length)

	var p_near = path.to_global(curve.sample_baked(d_near))
	var p_far  = path.to_global(curve.sample_baked(d_far))

	# main path anchor
	var base_target = p_near.lerp(p_far, 0.25)

	# clamp so it NEVER drifts too far off track
	var target_pos = clamp_to_path(base_target, p_near, 2.5)

	# =================================================
	# PATH DIRECTION
	# =================================================
	var tangent_dir = (p_far - p_near)
	tangent_dir.y = 0
	tangent_dir = tangent_dir.normalized() if tangent_dir.length() > 0.001 else Vector3.FORWARD

	var to_target = target_pos - vehicle.global_position
	to_target.y = 0

	var dist = to_target.length()
	to_target = to_target.normalized() if dist > 0.001 else tangent_dir

	var correction_strength = clamp(dist / 10.0, 0.0, 1.0)
	correction_strength *= correction_strength

	var final_dir = (
		tangent_dir * (1.0 - correction_strength) +
		to_target * correction_strength
	).normalized()

	# =================================================
	# VEHICLE FORWARD
	# =================================================
	var forward = -vehicle.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized() if forward.length() > 0.001 else Vector3.FORWARD

	# =================================================
	# WALL DETECTION (SAFE + SHORT RANGE)
	# =================================================
	var space_state = vehicle.get_world_3d().direct_space_state
	var origin = vehicle.global_position + Vector3.UP * 0.2

	var right = forward.cross(Vector3.UP).normalized()

	var rays = [
		forward,
		(forward + right * 0.5).normalized(),
		(forward - right * 0.5).normalized()
	]

	var avoid = Vector3.ZERO

	for r in rays:
		var hit = cast_ray(space_state, origin, r)
		if hit:
			avoid += -r

	if avoid != Vector3.ZERO:
		final_dir = (final_dir * 0.35 + avoid.normalized() * 0.65).normalized()

	# =================================================
	# SHARP TURN DETECTION
	# =================================================
	var turn_angle = get_turn_sharpness(curve, distance, path)
	var is_sharp = turn_angle > 35.0

	# =================================================
	# NORMAL MODE
	# =================================================
	if not reversing:

		var angle = forward.signed_angle_to(final_dir, Vector3.UP)

		if is_sharp:
			angle *= 1.6

		var target_turn = clamp(angle * 1.4, -1.0, 1.0)

		if abs(angle) < 0.03:
			target_turn = 0.0

		smoothed_turn = lerp(smoothed_turn, target_turn, 5.0 * delta)
		vehicle.turn = smoothed_turn

		var turn_factor = clamp(abs(angle) / 1.2, 0.0, 1.0)
		vehicle.throttle = lerp(1.0, 0.35, turn_factor)

	# =================================================
	# REVERSE MODE (FULL OVERRIDE — NO PATH LEAK)
	# =================================================
	else:

		vehicle.throttle = -1.0

		# PURE ESCAPE VECTOR (no path influence allowed)
		var escape = avoid if avoid != Vector3.ZERO else -forward
		escape = escape.normalized()

		var escape_angle = forward.signed_angle_to(escape, Vector3.UP)

		vehicle.turn = clamp(escape_angle * 3.0, -1.0, 1.0)

		reverse_remaining -= movement

		if reverse_remaining <= 0.0 or movement > 0.15:
			reversing = false
			stuck_timer = 0.0
			smoothed_turn = 0.0
