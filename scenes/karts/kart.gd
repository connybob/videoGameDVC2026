extends CharacterBody3D

# movement speed
const SPEED = 40.0

# turning speed (left and right)
const TURN_SPEED = 2.0

# pulls car down (when there are obstacles)
const GRAVITY = -20.0

const WHEEL_SPIN_SPEED = 5.0
const STEERING_AMOUNT = 20.0

# reference all wheel nodes
@onready var wheel_fl = $BlueberrySodaKart/Wheel_FL
@onready var wheel_fr = $BlueberrySodaKart/Wheel_FR
@onready var wheel_bl = $BlueberrySodaKart/Wheel_BL
@onready var wheel_br = $BlueberrySodaKart/Wheel_BR
@onready var steering_wheel = $BlueberrySodaKart/SteeringWheel1

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

	# spin all wheels when moving
	wheel_fl.rotation.x += input * WHEEL_SPIN_SPEED * delta
	wheel_fr.rotation.x += input * WHEEL_SPIN_SPEED * delta
	wheel_bl.rotation.x += input * WHEEL_SPIN_SPEED * delta
	wheel_br.rotation.x += input * WHEEL_SPIN_SPEED * delta

	# rotate steering wheel when turning
	steering_wheel.rotation.z = -turn * deg_to_rad(STEERING_AMOUNT)
	
	#apply the movement
	move_and_slide()
