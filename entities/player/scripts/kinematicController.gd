extends KinematicBody

onready var head: Spatial = $Head
onready var cam: Camera = $Head/Camera

export(float, 0.0, 1.0, 0.05) var airControl = 0.3
export(float) var mouseSens = 12.0
export(float) var FOV = 80.0
export(float) var gravity = 30.0
export(int) var walkSpeed = 10
export(int) var sprintSpeed = 16
export(int) var acceleration = 8
export(int) var deacceleration = 10
export(int) var flySpeed = 10
export(int) var flyAcc = 4
export(int) var jumpHeight = 10
export(int) var staminaDeplete = 2
export(int) var staminaFill = 1

var mouseAxis := Vector2()
var velocity := Vector3()
var direction := Vector3()
var moveAxis := Vector2()
var sprint_enabled := true
var flying := false
const FLOOR_MAX_ANGLE: float = deg2rad(46.0)

func _ready() -> void:

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam.fov = FOV

func _process(_delta: float) -> void:

	moveAxis.x = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	moveAxis.y = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

func _physics_process(delta: float) -> void:

	if flying: fly(delta)
	else: walk(delta)

func _input(event: InputEvent) -> void:

	if event is InputEventMouseMotion:
		mouseAxis = event.relative
		camera_rotation()

func walk(delta: float) -> void:

	direction = Vector3()
	var aim: Basis = get_global_transform().basis
	if moveAxis.x >= 0.5: direction -= aim.z
	if moveAxis.x <= -0.5: direction += aim.z
	if moveAxis.y <= -0.5: direction -= aim.x
	if moveAxis.y >= 0.5: direction += aim.x
	direction.y = 0
	direction = direction.normalized()

	var tempSnap: Vector3
	if is_on_floor():
		tempSnap = Vector3.DOWN
		if Input.is_action_just_pressed("move_jump"):
			tempSnap = Vector3.ZERO
			velocity.y = jumpHeight

	velocity.y -= gravity * delta

	var tempSpeed: int
	if (Input.is_action_pressed("move_sprint") and can_sprint() and moveAxis != Vector2(0, 0)):
		tempSpeed = sprintSpeed
		cam.set_fov(lerp(cam.fov, FOV * 1.05, delta * 8))
		PlayerGlobal.stamina -= staminaDeplete
	else:
		tempSpeed = walkSpeed
		cam.set_fov(lerp(cam.fov, FOV, delta * 8))
		PlayerGlobal.stamina += staminaFill*int(PlayerGlobal.stamina > 0)
	if PlayerGlobal.stamina == 0 and Input.is_action_just_released("move_sprint"): PlayerGlobal.stamina = staminaFill
	PlayerGlobal.stamina = int(clamp(PlayerGlobal.stamina, 0, 100))

	var tempVel: Vector3 = velocity
	tempVel.y = 0
	var tempTarget: Vector3 = direction * tempSpeed
	var tempAcc: float
	if direction.dot(tempVel) > 0: tempAcc = acceleration
	else: tempAcc = deacceleration
	if not is_on_floor(): tempAcc *= airControl

	tempVel = tempVel.linear_interpolate(tempTarget, tempAcc * delta)
	velocity.x = tempVel.x
	velocity.z = tempVel.z

	if direction.dot(velocity) == 0:
		var velClamp := 0.25
		if abs(velocity.x) < velClamp: velocity.x = 0
		if abs(velocity.z) < velClamp: velocity.z = 0

	var moving = move_and_slide_with_snap(velocity, tempSnap, Vector3.UP, true, 4, FLOOR_MAX_ANGLE)
	if is_on_wall(): velocity = moving
	else: velocity.y = moving.y

func fly(delta: float) -> void:

	direction = Vector3()
	var aim = head.get_global_transform().basis
	if moveAxis.x >= 0.5: direction -= aim.z
	if moveAxis.x <= -0.5: direction += aim.z
	if moveAxis.y <= -0.5: direction -= aim.x
	if moveAxis.y >= 0.5: direction += aim.x
	direction = direction.normalized()

	var target: Vector3 = direction * flySpeed
	velocity = velocity.linear_interpolate(target, flyAcc * delta)

	velocity = move_and_slide(velocity)

func camera_rotation() -> void:

	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED: return
	if mouseAxis.length() > 0:
		var horizontal: float = -mouseAxis.x * (mouseSens / 100)
		var vertical: float = -mouseAxis.y * (mouseSens / 100)

		mouseAxis = Vector2()

		rotate_y(deg2rad(horizontal))
		head.rotate_x(deg2rad(vertical))

		var temp_rot: Vector3 = head.rotation_degrees
		temp_rot.x = clamp(temp_rot.x, -90, 90)
		head.rotation_degrees = temp_rot

func can_sprint() -> bool: return (sprint_enabled and PlayerGlobal.stamina > 0 and is_on_floor())
