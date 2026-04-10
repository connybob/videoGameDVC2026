extends CharacterBody3D

const SPEED = 40.0
const TURN_SPEED = 2.0
const GRAVITY = -20.0

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	var input = Input.get_axis("forward", "reverse")
	velocity.x = transform.basis.z.x * input * SPEED
	velocity.z = transform.basis.z.z * input * SPEED
	
	if input != 0:
		var turn = Input.get_axis("right", "left")
		rotation.y += (turn * TURN_SPEED * delta)
	
	move_and_slide()
