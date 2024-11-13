extends Area2D

@export var SPEED: int = 700

func _process(delta):
	# Mover la bala a la derecha o izquierda según la velocidad y el tiempo transcurrido
	global_position.x += SPEED * delta

func _on_body_entered(body):
	queue_free()
	if (body.has_method("take_damage2")):
		body.take_damage2()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
