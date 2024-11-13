extends Area2D




func _on_body_entered(body):
	if (body.has_method("take_track")):
		body.take_track()
		queue_free()
