extends CharacterBody3D

@export var speed: float = 2.0
@export var gravity: float = 24.0
@export var jump_velocity: float = 4.5

# look / sensitivity
@export var look_sensitivity := 0.007
@export var pitch_min_deg := -45.0
@export var pitch_max_deg := 60.0

# Camera
@onready var pivot: Node3D = $Pivot
@onready var camera: Camera3D = $Pivot/SpringArm3D/Camera3D
@onready var ground_ray: RayCast3D = $GroundRay

# Joystick
var joystick: Node = null
var look_touch_id: int = -1

# --- Health ---
@export var max_health: int = 100
var health: int = max_health
@onready var health_bar: ProgressBar = get_tree().get_root().get_node_or_null("Main/HUD/HealthBar/Bar")

func take_damage(amount: int) -> void:
	print("⚡ take_damage CALLED with: ", amount)
	if health <= 0:
		return
	
	health -= amount
	if health < 0:
		health = 0

	print("💢 Player took damage! Health: ", health)

	if health_bar:
		health_bar.value = health
	else:
		print("❌ Health bar not found!")

	if health <= 0:
		print("☠️ _player_dead() will run now!")
		_player_dead()

func _player_dead() -> void:
	print("💀 Player is dead, changing scene!")
	set_process(false)
	if ResourceLoader.exists("res://Scene/game_over.tscn"):
		get_tree().change_scene_to_file("res://Scene/game_over.tscn")

func _ready() -> void:
	var root_scene = get_tree().get_current_scene()
	if root_scene:
		joystick = root_scene.get_node_or_null("HUD/Control/VirtualJoystick")
	if joystick == null:
		joystick = get_tree().get_root().get_node_or_null("Main/HUD/Control/VirtualJoystick")
	if joystick == null:
		push_warning("⚠️ VirtualJoystick not found. Ensure HUD path is HUD/Control/VirtualJoystick.")

	_clamp_pitch()

	if health_bar:
		print("✅ Health bar found!")
		health_bar.max_value = max_health
		health_bar.value = health
	else:
		print("❌ Health bar NOT found. Path should be Main/HUD/HealthBar/Bar")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x > get_viewport().size.x * 0.5:
			look_touch_id = event.index
		elif not event.pressed and event.index == look_touch_id:
			look_touch_id = -1
	elif event is InputEventScreenDrag and event.index == look_touch_id:
		rotation.y -= event.relative.x * look_sensitivity
		pivot.rotation.x = clamp(
			pivot.rotation.x - event.relative.y * look_sensitivity,
			deg_to_rad(pitch_min_deg),
			deg_to_rad(pitch_max_deg)
		)

func _physics_process(delta: float) -> void:
	# Movement input
	var joy_vec := Vector2.ZERO
	if joystick:
		joy_vec = joystick.output
	else:
		joy_vec = Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		)

	var cam_t := camera.global_transform
	var forward := -cam_t.basis.z
	var right := cam_t.basis.x
	forward.y = 0; right.y = 0
	forward = forward.normalized(); right = right.normalized()

	var input_dir := (forward * -joy_vec.y) + (right * joy_vec.x)

	if input_dir.length() > 0.001:
		input_dir = input_dir.normalized()
		velocity.x = input_dir.x * speed
		velocity.z = input_dir.z * speed
	else:
		velocity.x = lerp(velocity.x, 0.0, 0.2)
		velocity.z = lerp(velocity.z, 0.0, 0.2)

	# Gravity + Jump
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	# Ground Snap
	if ground_ray.is_colliding():
		var hit_pos = ground_ray.get_collision_point()
		var target_y = hit_pos.y + 0.9
		global_transform.origin.y = lerp(global_transform.origin.y, target_y, 8.0 * delta)

	move_and_slide()

func _clamp_pitch() -> void:
	pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))
