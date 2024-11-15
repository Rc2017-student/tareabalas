extends Area2D


func _on_body_entered(body):
	if (body.has_method("guardar")):
		body.guardar()
		queue_free()
