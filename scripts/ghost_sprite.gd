extends Sprite2D

func _ready():
	var tween = create_tween()
	tween.tween_property(self, "self_modulate:a", 0.0, 0.15)
	tween.finished.connect(queue_free)
