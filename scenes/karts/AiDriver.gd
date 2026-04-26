extends Node

@export var vehicle: Kart
@export var target: Node3D

var smoothed_turn := 0.0

func _init():
	print("AI SCRIPT LOADED")

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	print("AI DRIVER READY")

func _process(delta):
	print("vehicle class:", vehicle.get_class())
	print("AI running")
	print("AI throttle:", vehicle.throttle, " turn:", vehicle.turn)
	print("-------------------")

	if vehicle == null or target == null:
		return

	var forward = -vehicle.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	var to_target = target.global_position - vehicle.global_position
	to_target.y = 0

	var distance = to_target.length()
	var dir_to_target = to_target.normalized()

	var lookahead = clamp(distance * 0.25, 6.0, 25.0)

	var steering_point = target.global_position + dir_to_target * lookahead
	var desired_dir = (steering_point - vehicle.global_position)
	desired_dir.y = 0
	desired_dir = desired_dir.normalized()

	var angle = forward.signed_angle_to(desired_dir, Vector3.UP)

	var raw_turn = clamp(angle * 1.8, -1.0, 1.0)

	smoothed_turn = lerp(smoothed_turn, raw_turn, 6.0 * delta)

	# throttle ONLY ONCE (fixes conflict)
	var turn_amount = abs(angle)

	if turn_amount > 0.7:
		vehicle.throttle = 0.25
	elif turn_amount > 0.4:
		vehicle.throttle = 0.55
	else:
		vehicle.throttle = 0.85

	vehicle.turn = smoothed_turn
