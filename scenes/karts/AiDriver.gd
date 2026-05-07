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

	# =================================================
	# 1. TRACK PROGRESS
	# =================================================

	distance += abs(vehicle.current_speed) * delta
	distance = fposmod(distance, curve_length)

	# =================================================
	# 2. SPEED-BASED LOOKAHEAD
	# =================================================

	var speed = vehicle.velocity.length()

	var look_near = clamp(speed * 0.25, 5.0, 10.0)
	var look_mid  = clamp(speed * 0.50, 10.0, 20.0)
	var look_far  = clamp(speed * 0.90, 18.0, 35.0)

	var d1 = fposmod(distance + look_near, curve_length)
	var d2 = fposmod(distance + look_mid, curve_length)
	var d3 = fposmod(distance + look_far, curve_length)

	# =================================================
	# 3. SAMPLE SPLINE POINTS
	# =================================================

	var p1 = path.to_global(curve.sample_baked(d1))
	var p2 = path.to_global(curve.sample_baked(d2))
	var p3 = path.to_global(curve.sample_baked(d3))

	# =================================================
	# 4. FUTURE TARGET POSITION
	# =================================================

	var target_pos = (
		p1 * 0.5 +
		p2 * 0.3 +
		p3 * 0.2
	)
	
	# =================================================
	# 5. ROAD TANGENT
	# =================================================

	var tangent_dir = (p3 - p1)
	tangent_dir.y = 0

	if tangent_dir.length() > 0.001:
		tangent_dir = tangent_dir.normalized()
	else:
		tangent_dir = Vector3.FORWARD

	# =================================================
	# 6. POSITION CORRECTION
	# =================================================

	var to_target = target_pos - vehicle.global_position
	to_target.y = 0

	var dist = to_target.length()

	if dist > 0.001:
		to_target = to_target.normalized()
	else:
		to_target = tangent_dir

	# =================================================
	# 7. SOFT CORRECTION
	# =================================================

	# close to path = less correction
	var correction_strength = clamp(dist / 10.0, 0.0, 1.0)

	# smoother falloff
	correction_strength *= correction_strength

	# =================================================
	# 8. FINAL STEERING DIRECTION
	# =================================================

	var final_dir = (
		tangent_dir * (1.0 - correction_strength) +
		to_target * correction_strength
	).normalized()

	# =================================================
	# 9. VEHICLE FORWARD
	# =================================================

	var forward = -vehicle.global_transform.basis.z
	forward.y = 0

	if forward.length() > 0.001:
		forward = forward.normalized()
	else:
		forward = Vector3.FORWARD

	# =================================================
	# 10. STEERING ANGLE
	# =================================================

	var angle = forward.signed_angle_to(final_dir, Vector3.UP)

	# =================================================
	# 11. STEERING INPUT
	# =================================================

	var target_turn = clamp(angle * 1.5, -1.0, 1.0)

	# deadzone removes micro jitter
	if abs(angle) < 0.03:
		target_turn = 0.0

	# smoothing
	smoothed_turn = lerp(smoothed_turn, target_turn, 4.0 * delta)

	vehicle.turn = smoothed_turn

	# =================================================
	# 12. THROTTLE CONTROL
	# =================================================

	# slow down on sharp turns
	var turn_factor = clamp(abs(angle) / 1.2, 0.0, 1.0)

	vehicle.throttle = lerp(1.0, 0.35, turn_factor)

	# =================================================
	# 13. DEBUG
	# =================================================

	if Engine.get_physics_frames() % 20 == 0:
		print("--------------------------------")
		print("Speed:", speed)
		print("Distance:", distance)
		print("Angle:", angle)
		print("Turn:", vehicle.turn)
		print("Correction:", correction_strength)
