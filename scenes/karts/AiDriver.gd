extends Node

@export var vehicle: Kart
@export var path: Path3D

var smoothed_turn := 0.0
var distance := 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)

func _process(delta):

	if vehicle == null or path == null:
		return

	# move forward along path based on speed
	distance += abs(vehicle.current_speed) * delta

	# get point ahead on track
	var target_pos = path.curve.sample_baked(distance + 8.0)

	# steering
	var forward = -vehicle.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	var to_target = target_pos - vehicle.global_position
	to_target.y = 0
	to_target = to_target.normalized()

	var angle = forward.signed_angle_to(to_target, Vector3.UP)

	var raw_turn = clamp(angle * 2.0, -1.0, 1.0)
	smoothed_turn = lerp(smoothed_turn, raw_turn, 6.0 * delta)

	vehicle.turn = smoothed_turn

	# speed control
	var speed_factor = 1.0 - clamp(abs(angle) * 1.5, 0.0, 1.0)
	vehicle.throttle = lerp(0.3, 1.0, speed_factor)
