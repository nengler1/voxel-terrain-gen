extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.001

#fov variables
const BASE_FOV = 80
const FOV_CHANGE = 1.5
var velocity_clamped
var target_fov

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8

# Camera Variables
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var world = $"../World"

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _unhandled_input(event):
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			head.rotate_y(-event.relative.x * SENSITIVITY)
			camera.rotate_x(-event.relative.y * SENSITIVITY)
			camera.rotation.x = clamp(
				camera.rotation.x,
				deg_to_rad(-90),
				deg_to_rad(90)
			)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle Sprint and FOV
	velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	if Input.is_action_pressed("sprint") and velocity_clamped >= 0.6:
		speed = SPRINT_SPEED
		target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
		camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	else:
		speed = WALK_SPEED
		camera.fov = lerp(camera.fov, float(BASE_FOV), delta * 8.0)
	
	#print(velocity_clamped)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward")
	var direction = (head.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 10.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 10.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 4.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 4.0)

	move_and_slide()
	
	handle_block_interaction()

func handle_block_interaction():
	if Input.is_action_just_pressed("click"):
		raycast_block(true)
	elif Input.is_action_just_pressed("delete_block"):
		raycast_block(false)

func raycast_block(remove_block: bool):
	var ray_length = 10
	var from = camera.global_transform.origin
	var to = from + -camera.global_transform.basis.z * ray_length
	var space = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	var result = space.intersect_ray(ray_query)

	if result and result.position:
		var hit_pos = result.position - (result.normal * 0.5)
		hit_pos = Vector3i(round(hit_pos.x), round(hit_pos.y), round(hit_pos.z))
		
		if remove_block:
			world.set_block_by_world_position(hit_pos, Block.BlockType.Air)
		else:
			# Calculate the block type based on height for placement
			hit_pos += Vector3i(result.normal)
			var block_type = get_block_type_for_height(hit_pos.y)
			world.set_block_by_world_position(hit_pos, block_type)

func get_block_type_for_height(height: int) -> Block.BlockType:
	# height thresholds for block types
	var stone_height = world.chunk_size * 1.2
	if height > stone_height:  # heights above 48 are stone
		return Block.BlockType.Stone
	else:  # Heights below are grass
		return Block.BlockType.Dirt
