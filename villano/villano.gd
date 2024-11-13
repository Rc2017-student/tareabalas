extends CharacterBody2D

@export var vida = 3  # Número de impactos que puede recibir antes de morir

# Función que se llama cuando el enemigo entra en la escena
func _ready():
	$AnimatedSprite2D.play("idle")  # Cambia a la animación de espera o patrullaje si existe

var health = 4
func take_damage():
	health -= 2
	if health == 0:
		queue_free()

func take_damage2():
	health -= 4
	if health == 0:
		queue_free()
