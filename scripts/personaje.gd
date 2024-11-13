extends CharacterBody2D

# Constantes
const SPEED = 300.0  # Velocidad horizontal del personaje
const JUMP_VELOCITY = -550.0  # Velocidad del salto (negativa porque va hacia arriba)
const STAND_TO_IDLE_DELAY = 0.5  # Tiempo antes de pasar de "stand" a "idle"
const DUCK_DURATION = 0.2  # Duración de la animación "duck" al aterrizar después de un salto o caída


# Referencias a nodos
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D  # Referencia al sprite animado del personaje
@onready var HieloBalaScene1 = preload("res://hielo.tscn")  # Carga de la escena de la bala de hielo
@onready var FuegoBalaScene = preload("res://balafuego.tscn")
@onready var timer = $Timer
# Variables de estado
var stand_timer = 0.0  # Temporizador para cambiar de "stand" a "idle"
var duck_timer = 0.0  # Temporizador para controlar la duración de la animación "duck"
var was_in_air = false  # Indica si el personaje estaba en el aire (por salto o caída)
var is_ducking = false  # Indica si el personaje está actualmente agachado
var landed_from_jump = false  # Indica si el personaje acaba de aterrizar de un salto o caída

# ==========================================
# FUNCIONES PRINCIPALES
# ==========================================
var is_active: bool = true

# Función principal del ciclo de físicas que se ejecuta cada frame
func _physics_process(delta):
	handle_input(delta)  # Manejar la entrada del usuario
	update_state(delta)  # Actualizar el estado del personaje
	apply_physics()  # Aplicar movimiento y física

# ==========================================
# MANEJO DE LA ENTRADA
# ==========================================

# Función para manejar la entrada del usuario
func handle_input(delta):
	handle_movement()  # Manejar el movimiento horizontal
	handle_jump()  # Manejar el salto
	handle_manual_duck()  # Manejar el agachado manual
	handle_shooting()  # Manejar el disparo

# ==========================================
# ACTUALIZACIÓN DEL ESTADO DEL PERSONAJE
# ==========================================

# Función para actualizar el estado del personaje
func update_state(delta):
	if is_on_floor():
		update_idle_transition(delta)  # Controlar la transición a "idle" si está en el suelo
	handle_landing(delta)  # Verificar y manejar el aterrizaje

# Controla la transición de "stand" a "idle" si el personaje está quieto
func update_idle_transition(delta):
	if velocity.x == 0 and not is_ducking and not landed_from_jump:
		stand_timer += delta
		if stand_timer >= STAND_TO_IDLE_DELAY:
			sprite.play("idle")
	else:
		stand_timer = 0.0  # Reiniciar el temporizador si hay actividad

# Controla el aterrizaje después de un salto o caída
func handle_landing(delta):
	if not is_on_floor() and velocity.y > 0:
		sprite.play("fall")
		was_in_air = true
	elif was_in_air:
		sprite.play("duck")
		landed_from_jump = true
		was_in_air = false
		duck_timer = DUCK_DURATION
	if landed_from_jump:
		duck_timer -= delta
		if duck_timer <= 0:
			landed_from_jump = false
			sprite.play("stand")
			stand_timer = 0.0

# ==========================================
# APLICACIÓN DE LA FÍSICA
# ==========================================

# Función para aplicar la física y el movimiento del personaje
func apply_physics():
	handle_gravity()  # Aplicar la gravedad si no está en el suelo
	move_and_slide()  # Mover el personaje y aplicar la física de colisiones

# Aplica la gravedad cuando el personaje está en el aire
func handle_gravity():
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * get_physics_process_delta_time()

# ==========================================
# MANEJO DE ACCIONES ESPECÍFICAS
# ==========================================

# Controla el movimiento horizontal del personaje
func handle_movement():
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0 and not is_ducking and not landed_from_jump:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
		if is_on_floor():
			sprite.play("walk")
		reset_timers()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

# Verifica si el personaje debe saltar
func handle_jump():
	if Input.is_action_just_pressed("ui_up") and is_on_floor() and not is_ducking:
		velocity.y = JUMP_VELOCITY
		sprite.play("jump")
		was_in_air = true

# Maneja el agachado manual con la tecla hacia abajo
func handle_manual_duck():
	if Input.is_action_pressed("ui_down") and is_on_floor():
		sprite.play("duck")
		is_ducking = true
	elif Input.is_action_just_released("ui_down") and is_ducking:
		is_ducking = false
		sprite.play("stand")
		stand_timer = 0.0

# Función para manejar el disparo
func handle_shooting():
	if Input.is_action_just_pressed("ui_accept"):
		disparar_bala()

# Función para disparar una bala de hielo
func disparar_bala():
	if is_active == true:
		var bala = HieloBalaScene1.instantiate()
		get_parent().add_child(bala)
		bala.global_position = global_position
		var bala_sprite = bala.get_node("AnimatedSprite2D")
		if sprite.flip_h:
			bala.SPEED = -abs(bala.SPEED)
			bala_sprite.flip_h = true
		else:
			bala.SPEED = abs(bala.SPEED)
			bala_sprite.flip_h = false
	else:
		var bala = FuegoBalaScene.instantiate()
		get_parent().add_child(bala)
		bala.global_position = global_position
		if sprite.flip_h:
			bala.SPEED = -abs(bala.SPEED)
		else:
			bala.SPEED = abs(bala.SPEED)

# ==========================================
# UTILIDADES Y FUNCIONES AUXILIARES
# ==========================================

# Reinicia todos los temporizadores y estados
func reset_timers():
	stand_timer = 0.0
	duck_timer = 0.0
	landed_from_jump = false
	is_ducking = false



func take_track():
	iniciar_timer()
	timer.timeout.connect(Callable(self, "_on_timeout"))
	is_active = false

func _on_timer_timeout():
	print("Power-up desactivado")
	is_active = true


func iniciar_timer():
	timer.wait_time = 10
	timer.one_shot = true
	timer.start()
