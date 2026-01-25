extends CharacterBody2D

@export var speed = 100.0
@export var roll_multiplier = 2.5
@export var roll_duration_ticks = 10
@export var roll_cooldown_ticks = 30
@export var input: PlayerInput
@onready var rock_scene: PackedScene = preload("res://scenes/rock_attack/rock_attack.tscn")

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite = $Sprite2D
var spawn_position: Vector2 = Vector2.ZERO
var roll_timer = 0
var cooldown_timer = 0
var roll_direction = Vector2.ZERO
@export var play_roll_animation: bool = false
@export var recovery_duration_ticks = 10
var recovery_timer = 0

func _ready():
	global_position = spawn_position

func _rollback_tick(_delta, _tick, is_fresh):
	if input.is_shooting and is_fresh and multiplayer.is_server():
		var rock_spawn_pos = global_position + (input.movement.normalized() * 60.0)
		_server_spawn_rock(rock_spawn_pos)
	if cooldown_timer > 0:
		cooldown_timer -= 1
	if recovery_timer > 0:
		recovery_timer -= 1
	if roll_timer > 0:
		var roll_progress = float(roll_timer) / float(roll_duration_ticks)
		var current_roll_speed = speed * (1.0 + (roll_multiplier * roll_progress))
		velocity = roll_direction * current_roll_speed
		roll_timer -= 1
		if roll_timer == 0:
			recovery_timer = recovery_duration_ticks
	else:
		velocity = lerp(velocity, input.movement.normalized() * speed, 0.75)
		if input.is_rolling and cooldown_timer == 0 and input.movement != Vector2.ZERO and is_fresh:
			roll_timer = roll_duration_ticks
			cooldown_timer = roll_cooldown_ticks
			roll_direction = input.movement.normalized()
			velocity = roll_direction * (speed * roll_multiplier)

	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor

func _server_spawn_rock(rock_spawn_pos: Vector2):
	if multiplayer.is_server():
		var rock = rock_scene.instantiate() as Area2D
		rock.global_position = rock_spawn_pos
		NetworkManager.rock_attack_container.add_child(rock, true)

# Just using process for animations at this point, so no need to run them on the server as it is headless
func _process(_delta: float) -> void:
	if not multiplayer.is_server():
		if roll_timer > 0:
			anim_player.play("roll")
			_spawn_ghost()
		else:
			anim_player.stop()

func _spawn_ghost():
	if roll_timer > 0 and Engine.get_frames_drawn() % 3 == 0:
		var ghost = Sprite2D.new()
		ghost.texture = sprite.texture
		ghost.hframes = sprite.hframes
		ghost.vframes = sprite.vframes
		ghost.frame = sprite.frame
		ghost.flip_h = sprite.flip_h
		ghost.global_position = sprite.global_position
		ghost.rotation = sprite.rotation
		ghost.scale = sprite.scale
		ghost.z_index = -1
		ghost.self_modulate = Color(0.6, 0.8, 2.0, 0.7) # Slightly blue/glowy
		ghost.set_script(load("res://scripts/ghost_sprite.gd"))
		get_tree().current_scene.add_child(ghost)
