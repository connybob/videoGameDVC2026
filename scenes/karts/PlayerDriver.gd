extends Node

@export var vehicle: Kart

func _process(delta):

	if vehicle == null:
		return

	vehicle.throttle = Input.get_axis("reverse", "forward")
	vehicle.turn = Input.get_axis("right", "left")