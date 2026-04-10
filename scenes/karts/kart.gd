extends CharacterBody3D

# movement speed
const SPEED = 40.0

# turning speed (left and right)
const TURN_SPEED = 2.0

# pulls car down (when there are obstacles)
const GRAVITY = -20.0

func _physics_process(delta):
	# pull kart down when not on floor
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# forward/reverse (WASD or arrow)
	var input = Input.get_axis("forward", "reverse")
	
	# moves the kart in the direction it's facing
	velocity.x = transform.basis.z.x * input * SPEED
	velocity.z = transform.basis.z.z * input * SPEED
	
	# left/right input movement
	var turn = Input.get_axis("right", "left")
	rotation.y += (turn * TURN_SPEED * delta)
	
	#apply the movement
	move_and_slide()
