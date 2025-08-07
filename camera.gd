extends Camera2D

# Referencia al nodo principal para acceder a game_state
@onready var main = get_node("/root/Main")

# Velocidad de suavizado para el seguimiento de la cámara
@export var smoothing_speed: float = 5.0

func _physics_process(delta):
	if main and main.game_state and main.game_state.descongelado and not main.game_state.meta_alcanzada:
		# Obtener todas las bolas activas
		var bolas = get_tree().get_nodes_in_group("bolas")
		var bola_mas_abajo = null
		var max_y = -INF

		# Encontrar la bola más hacia abajo (mayor valor de y)
		for bola in bolas:
			if bola is RigidBody2D and not bola.is_deactivated:
				if bola.position.y > max_y:
					max_y = bola.position.y
					bola_mas_abajo = bola

		# Si hay una bola válida, seguirla con suavizado
		if bola_mas_abajo:
			var target_position = Vector2(bola_mas_abajo.position.x, bola_mas_abajo.position.y)
			position = position.lerp(target_position, smoothing_speed * delta)
			# Actualizar la posición en game_state para mantener consistencia
			main.game_state.camera_position = position
	else:
		# Mantener la posición actual si el juego no está descongelado o la meta fue alcanzada
		if main and main.game_state:
			position = main.game_state.camera_position
