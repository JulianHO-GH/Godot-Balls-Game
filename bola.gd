extends RigidBody2D

var teleport_to: Vector2 = Vector2.ZERO  # Posición objetivo para el teletransporte
var should_teleport: bool = false  # Bandera para activar el teletransporte
var is_paused: bool = true  # Estado para indicar si la bola está pausada (congelada manualmente)
var is_restarting: bool = false
var is_deactivated: bool = false  # Estado para indicar si la bola está desactivada
var saved_state = {  # Guardar el estado físico
	"position": Vector2.ZERO,
	"linear_velocity": Vector2.ZERO,
	"angular_velocity": 0.0,
	"rotation": 0.0  # Añadir rotación inicial
}

func _ready():
	saved_state.rotation = rotation  # Guardar la rotación inicial
	# Pausar la bola por defecto (desactivar físicas manualmente)
	pause_physics()

func _integrate_forces(state):
	if should_teleport:
		# Guardar el estado actual antes del teletransporte
		saved_state.position = state.transform.origin
		saved_state.linear_velocity = state.linear_velocity
		saved_state.angular_velocity = state.angular_velocity
		
		# Actualizar la posición directamente en el estado físico usando la posición global del destino
		state.transform.origin = teleport_to
		should_teleport = false  # Resetear la bandera
		
		# Actualizar saved_state con la nueva posición teletransportada
		saved_state.position = teleport_to
		
		# Mantener el estado de pausa actual en lugar de forzar una pausa, SOLO si no es para reinicio
		if is_paused:
			pause_physics()
		else:
			resume_physics()
	
		# Limpiar teleport_to después del teletransporte
		teleport_to = Vector2.ZERO
		
	elif is_restarting:
		state.transform = Transform2D(saved_state.rotation, teleport_to)  # Restablecer posición y rotación
		# Actualizar la posición directamente en el estado físico usando la posición global del destino
		state.transform.origin = teleport_to
		
		is_restarting = false  # Resetear la bandera
		
		# Actualizar saved_state con la nueva posición teletransportada
		saved_state.position = teleport_to
		
		teleport_to = Vector2.ZERO # Limpiar teleport_to después del teletransporte
		# Guardar el estado actual
		saved_state.position = state.transform.origin
		saved_state.linear_velocity = state.linear_velocity
		saved_state.angular_velocity = state.angular_velocity

func teleport(target_position: Vector2):
	# Establecer la posición objetivo (global) y activar el teletransporte
	teleport_to = target_position
	should_teleport = true

func pause_physics():
	# Congelar manualmente la bola guardando su estado actual
	is_paused = true
	saved_state.position = position
	saved_state.linear_velocity = linear_velocity
	saved_state.angular_velocity = angular_velocity
	# Desactivar las físicas usando freeze
	freeze = true
	
func restart_physics(target_position: Vector2):
	is_paused = true
	freeze = true
	# Establecer la posición objetivo (global) y activar el teletransporte
	teleport_to = target_position
	is_restarting = true
	rotation = saved_state.rotation  # Actualizar la rotación visual inmediatamente
	
	
func resume_physics():
	# Reanudar manualmente la bola restaurando su estado
	is_paused = false
	# Restaurar el estado guardado, pero solo si no estamos en un teletransporte reciente
	if teleport_to == Vector2.ZERO:  # Solo restaurar si no hay un teletransporte pendiente
		position = saved_state.position
		linear_velocity = saved_state.linear_velocity
		angular_velocity = saved_state.angular_velocity
	# Activar las físicas quitando freeze
	freeze = false

func deactivate():
	is_deactivated = true
	$Sprite2D.visible = false
	$CollisionShape2D.disabled = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	saved_state.linear_velocity = Vector2.ZERO
	saved_state.angular_velocity = 0.0
	# Excluir la bola de todas las capas y máscaras de colisión
	set_collision_layer_value(1, false)  # Desactivar la capa de colisión
	set_collision_mask_value(1, false)   # Desactivar la máscara de colisión

func reactivate():
	is_deactivated = false
	$Sprite2D.visible = true
	$CollisionShape2D.disabled = false
	# Restaurar las capas y máscaras de colisión
	set_collision_layer_value(1, true)  # Reactivar la capa de colisión
	set_collision_mask_value(1, true)   # Reactivar la máscara de colisión
