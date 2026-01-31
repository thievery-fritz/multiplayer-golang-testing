extends Node2D


@export var shoot_cooldown: float = 0.5
@export var damage: int = 10
@export var push_back_force: int = 100

@export var player: CharacterBody2D
@export var shoot_rewindable_action: RewindableAction
@export var rbs: RollbackSynchronizer
@export var input: PlayerInput

@onready var rock_attack_scene: PackedScene = preload("res://scenes/rock_attack/rock_attack.tscn")

var last_shoot: int = -1
var last_rock: Area2D = null

func _ready() -> void:
	shoot_rewindable_action.mutate(self)
	shoot_rewindable_action.mutate(player)
	NetworkTime.after_tick_loop.connect(_after_tick_loop)

func _rollback_tick(_dt, tick, _if):
	var want_to_shoot = input.is_shooting and _can_shoot()
	shoot_rewindable_action.set_active(want_to_shoot, tick)
	match shoot_rewindable_action.get_status():
		RewindableAction.CONFIRMING, RewindableAction.ACTIVE:
			_shoot(tick)
		RewindableAction.CANCELLING:
			_undo_shoot(tick)

func _after_tick_loop():
	if shoot_rewindable_action.has_confirmed():
		# In the example, this is where they played the sound, maybe animation here?
		pass
	pass

func _can_shoot() -> bool:
	return NetworkTime.seconds_between(last_shoot, NetworkRollback.tick) >= shoot_cooldown

func _shoot(tick):
	if shoot_rewindable_action.has_context(tick):
		return
	var rock_spawn_pos = global_position + (input.movement.normalized() * 60.0)
	var rock = rock_attack_scene.instantiate() as Area2D
	rock.set_multiplayer_authority(1)
	rock.global_position = rock_spawn_pos
	if multiplayer.is_server():
		NetworkManager.rock_attack_container.add_child(rock, true)
	last_shoot = tick
	shoot_rewindable_action.set_context(rock, tick)

func _undo_shoot(tick):
	print("Undoing shoot on %d" % multiplayer.get_unique_id())
	var rock = shoot_rewindable_action.get_context(tick)
	if is_instance_valid(rock):
		rock.queue_free()
	shoot_rewindable_action.erase_context(tick)
