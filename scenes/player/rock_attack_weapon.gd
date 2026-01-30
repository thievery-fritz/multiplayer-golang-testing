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

func _rollback_tick(_dt, _tick, _if):
	if rbs.is_predicting():
		return

	shoot_rewindable_action.set_active(input.is_shooting and _can_shoot())
	match shoot_rewindable_action.get_status():
		RewindableAction.CONFIRMING, RewindableAction.ACTIVE:
			_shoot()
		RewindableAction.CANCELLING:
			_undo_shoot()

func _after_tick_loop():
	if shoot_rewindable_action.has_confirmed():
		# In the example, this is where they played the sound, maybe animation here?
		pass
	pass

func _can_shoot() -> bool:
	return NetworkTime.seconds_between(last_shoot, NetworkRollback.tick) >= shoot_cooldown

func _shoot():
	print("Shooting from %d" % multiplayer.get_unique_id())
	last_shoot = NetworkRollback.tick
	var rock_spawn_pos = global_position + (input.movement.normalized() * 60.0)
	var rock = rock_attack_scene.instantiate() as Area2D
	rock.set_multiplayer_authority(1)
	rock.global_position = rock_spawn_pos
	NetworkManager.rock_attack_container.add_child(rock, true)

func _undo_shoot():
	shoot_rewindable_action.erase_context()
	if last_rock:
		last_rock.queue_free()
