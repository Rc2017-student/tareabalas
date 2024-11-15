extends CharacterBody2D

# Constantes
const SPEED = 300.0
const JUMP_VELOCITY = -550.0
const STAND_TO_IDLE_DELAY = 0.5
const DUCK_DURATION = 0.2

# Ruta para guardar el archivo
var ruta: String = "user://game_data.dat"

# Diccionario de datos predeterminado
var Datos: Dictionary = {
	"position": [200, 200]  # Posición inicial predeterminada
}

# Referencias a nodos
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var HieloBalaScene1 = preload("res://hielo.tscn")
@onready var FuegoBalaScene = preload("res://balafuego.tscn")
@onready var timer = $Timer

# Variables de estado
var stand_timer = 0.0
var duck_timer = 0.0
var was_in_air = false
var is_ducking = false
var landed_from_jump = false

# Estado activo para disparos
var is_active: bool = true

# ==========================================
# FUNCIONES PRINCIPALES
# ==========================================

func _ready():
	cargar()  # Cargar la posición inicial
	if Datos.has("position"):
		global_position = Vector2(Datos["position"][0], Datos["position"][1])
	print("Posición inicial:", global_position)

func _physics_process(delta):
	handle_input(delta)
	update_state(delta)
	apply_physics()

# ==========================================
# GUARDADO Y CARGA DE DATOS
# ==========================================

# Guardar los datos en el archivo
func guardar():
	Datos["position"] = [global_position.x, global_position.y]
	var archivo = FileAccess.open(ruta, FileAccess.WRITE)
	archivo.store_var(Datos)
	archivo = null
	print("Guardado con éxito en:", ruta)

# Cargar los datos del archivo
func cargar():
	if FileAccess.file_exists(ruta):
		var archivo = FileAccess.open(ruta, FileAccess.READ)
		Datos = archivo.get_var()
		archivo = null
		print("Datos cargados:", Datos)
	else:
		print("No se encontró archivo de guardado. Usando valores predeterminados.")

# ==========================================
# MANEJO DE LA ENTRADA
# ==========================================

func handle_input(delta):
	handle_movement()
	handle_jump()
	handle_manual_duck()
	handle_shooting()

# ==========================================
# ACTUALIZACIÓN DEL ESTADO DEL PERSONAJE
# ==========================================

func update_state(delta):
	if is_on_floor():
		update_idle_transition(delta)
	handle_landing(delta)

func update_idle_transition(delta):
	if velocity.x == 0 and not is_ducking and not landed_from_jump:
		stand_timer += delta
		if stand_timer >= STAND_TO_IDLE_DELAY:
			sprite.play("idle")
	else:
		stand_timer = 0.0

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

func apply_physics():
	handle_gravity()
	move_and_slide()

func handle_gravity():
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * get_physics_process_delta_time()

# ==========================================
# MANEJO DE ACCIONES ESPECÍFICAS
# ==========================================

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

func handle_jump():
	if Input.is_action_just_pressed("ui_up") and is_on_floor() and not is_ducking:
		velocity.y = JUMP_VELOCITY
		sprite.play("jump")
		was_in_air = true

func handle_manual_duck():
	if Input.is_action_pressed("ui_down") and is_on_floor():
		sprite.play("duck")
		is_ducking = true
	elif Input.is_action_just_released("ui_down") and is_ducking:
		is_ducking = false
		sprite.play("stand")
		stand_timer = 0.0

func handle_shooting():
	if Input.is_action_just_pressed("ui_accept"):
		disparar_bala()

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

func reset_timers():
	stand_timer = 0.0
	duck_timer = 0.0
	landed_from_jump = false
	is_ducking = false

func take_track():
	iniciar_timer()
	timer.timeout.connect(Callable(self, "_on_timer_timeout"))
	is_active = false

func _on_timer_timeout():
	print("Power-up desactivado")
	is_active = true

func iniciar_timer():
	timer.wait_time = 10
	timer.one_shot = true
	timer.start()
