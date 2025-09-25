extends CharacterBody3D

@export var speed: float = 1.5
@export var attack_range: float = 2.0
@export var attack_damage: int = 25
@export var attack_cooldown: float = 1.5  # seconds

var player: Node = null
var last_attack_time: float = 0.0

func _ready() -> void:
	player = get_tree().get_root().find_child("Player", true, false)
	if player:
		print("✅ Ghost found player")
	else:
		print("❌ Ghost did not find player")

func _physics_process(delta: float) -> void:
	if not player:
		return

	var dir = player.global_transform.origin - global_transform.origin
	var dist = dir.length()

	# move toward player
	if dist > 0.1:
		dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

	# attack check
	var now = Time.get_ticks_msec() / 1000.0  # seconds
	if dist <= attack_range and now - last_attack_time >= attack_cooldown:
		_attack_player()
		last_attack_time = now

func _attack_player() -> void:
	print("👻 Ghost ATTACK function called!")
	if player and player.has_method("take_damage"):
		player.take_damage(attack_damage)
		print("✅ Player hit, damage dealt: ", attack_damage)
	else:
		print("❌ Could not call take_damage()")
