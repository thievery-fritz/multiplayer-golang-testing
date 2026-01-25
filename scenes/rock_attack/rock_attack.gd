extends Area2D

@export var radius: float = 40.0
@export var fall_duration_ticks: int = 40
var current_ticks: int = 0
@onready var rollback_sync: RollbackSynchronizer = $RollbackSynchronizer

var triggered = false

func _rollback_tick(_delta, _tick, _is_fresh):
	current_ticks += 1
	if current_ticks >= fall_duration_ticks:
		_explode()

func _explode():
	if triggered:
		return
	triggered = true
	process_mode = Node.PROCESS_MODE_DISABLED
	hide()
	if multiplayer.is_server():
		var bodies = get_overlapping_bodies()
		for body in bodies:
			# Damage/health isn't really a thing yet, still working on that part, just trying to get the basics syncing atm
			if body.has_method("take_damage"):
				body.take_damage(global_position)
		queue_free.call_deferred()

func _process(_delta):
	queue_redraw()

func _draw():
	if triggered:
		return
	var progress = float(current_ticks) / float(fall_duration_ticks)
	draw_circle(Vector2.ZERO, radius, Color(1, 0.4, 0.4, 0.2))
	var fill_radius = radius * progress
	draw_circle(Vector2.ZERO, fill_radius, Color(1, 0.2, 0.2, 0.5))
	if current_ticks >= fall_duration_ticks - 2:
		draw_circle(Vector2.ZERO, radius, Color.WHITE)
