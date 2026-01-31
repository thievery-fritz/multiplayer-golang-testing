extends Area2D

@export var radius: float = 40.0
@export var fall_duration_ticks: int = 40
var current_ticks: int = 0
@onready var rollback_sync: RollbackSynchronizer = $RollbackSynchronizer
var wait_for_deletion_tick_count: int = 60
var queue_free_tick: int = -1
var did_explode = false

func _ready():
	NetworkTime.after_tick_loop.connect(_after_tick_loop)

func _rollback_tick(_delta, tick, _is_fresh):
	if did_explode:
		return
	current_ticks += 1
	if current_ticks >= fall_duration_ticks:
		_explode(tick)

func _after_tick_loop():
	if did_explode and (NetworkTime.tick > queue_free_tick + wait_for_deletion_tick_count):
		print("Deleting on %d" % multiplayer.get_unique_id())
		NetworkTime.after_tick_loop.disconnect(_after_tick_loop)
		#hide()
		#queue_free()

func _explode(tick):
	if did_explode:
		return
	#if multiplayer.is_server():
		#var bodies = get_overlapping_bodies()
		#for body in bodies:
			## Damage/health isn't really a thing yet, still working on that part, just trying to get the basics syncing atm
			#if body.has_method("take_damage"):
				#body.take_damage(global_position)
	queue_free_tick = tick
	#hide()
	did_explode = true

func _process(_delta):
	queue_redraw()

func _draw():
	if did_explode:
		return
	var progress = float(current_ticks) / float(fall_duration_ticks)
	draw_circle(Vector2.ZERO, radius, Color(1, 0.4, 0.4, 0.2))
	var fill_radius = radius * progress
	draw_circle(Vector2.ZERO, fill_radius, Color(1, 0.2, 0.2, 0.5))
	if current_ticks >= fall_duration_ticks - 2:
		draw_circle(Vector2.ZERO, radius, Color.WHITE)
