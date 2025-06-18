extends Node2D

@export var bola_scene: PackedScene
@export var piso_scene: PackedScene
@export var cubo_scene: PackedScene
@export var teleportador_scene: PackedScene
@export var grid_tilemap: TileMap  # Referencia al TileMap de la cuadrícula
@export var esquina_scene: PackedScene
@export var esquinarampa_scene: PackedScene
@export var punto_teletransporte_scene: PackedScene

# Instancia de GameState para gestionar datos
var game_state = preload("res://GameState.gd").new()

# Variables que ahora se gestionan en GameState
# (modo, descongelado, seleccionando, etc. se acceden vía game_state)

var ultima_posicion_toque: Vector2  # Para rastrear el arrastre
var initial_touch_position: Vector2  # Posición inicial del toque
var touch_over_buttons: bool = false  # Indica si el toque inicial fue sobre un botón
var ultimo_objeto_seleccionado = null  # Referencia al último objeto seleccionado
var is_dragging: bool = false  # Indica si estamos arrastrando
var selected_save_file: String = ""  # Archivo de guardado actual
var showing_popup: bool = false #Si se está mostrando un popup

# Constantes
const ZOOM_MIN: float = 0.1
const ZOOM_MAX: float = 2.0
const ZOOM_STEP: float = 0.1
const MOVE_OFFSET: float = -250.0
const ANIMATION_DURATION: float = 0.5
const ANIMATION_DURATION2: float = 0.2
const ANIMATION_DURATION3: float = 0.6
const DRAG_THRESHOLD: float = 10.0
const CAMERA_LIMIT_LEFT: float = -5000.0
const CAMERA_LIMIT_TOP: float = -10000.0
const CAMERA_LIMIT_RIGHT: float = 6000.0
const CAMERA_LIMIT_BOTTOM: float = 11000.0
const SAVE_DIR: String = "user://saved_levels/"

# Materiales/Shaders
var material_base = load("res://materials/resaltado_emision.tres")

# Plugin GodotGetImage
var plugin
var plugin_name = "GodotGetImage"
@onready var image_scene = preload("res://sprite_2d.tscn")


func _ready():
	# Crear el directorio de guardado si no existe
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	print("Directorio ", SAVE_DIR, " creado o ya existe")

	# Inicializar posiciones iniciales de la UI en GameState
	game_state.ui_menu_position = $UI/Menu.position
	game_state.ui_options_position = $UI/Opciones.position
	game_state.ui_boton_reiniciar_position = $UI/Opciones/BotonReiniciar.position
	game_state.ui_boton_descongelar_position = $UI/Opciones/BotonDescongelar.position
	game_state.ui_botones_mover_position = $UI/Mover.position

	$UI/Menu/BotonMoverMenu.pivot_offset = $UI/Menu/BotonMoverMenu.size / 2

	# Conectar señales de botones
	$UI/Menu/BotonBola.pressed.connect(_seleccionar_bola)
	$UI/Menu/BotonPiso.pressed.connect(_seleccionar_piso)
	$UI/Menu/BotonCubo.pressed.connect(_seleccionar_cubo)
	$UI/Menu/BotonTeleportador.pressed.connect(_seleccionar_teleportador)
	$UI/Menu/BotonEsquina.pressed.connect(_seleccionar_esquina)
	$UI/Menu/BotonMoverMenu.pressed.connect(_mover_menu)
	$UI/Opciones/BotonZoomIn.pressed.connect(_zoom_in)
	$UI/Opciones/BotonZoomOut.pressed.connect(_zoom_out)
	$UI/Opciones/BotonDescongelar.pressed.connect(_alternar_congelar_descongelar)
	$UI/Opciones/BotonReiniciar.pressed.connect(_reiniciar)
	$UI/Opciones/BotonEliminar.pressed.connect(_eliminar)
	$UI/Menu/BotonEsquinaRampa.pressed.connect(_seleccionar_esquinarampa)
	$UI/Opciones/BotonSelect.pressed.connect(_alternar_seleccionar)
	$UI/Opciones/BotonLink.pressed.connect(_on_boton_link_pressed)
	$UI/Opciones/BotonLink.visible = false
	$UI/Opciones/ButtonSave.pressed.connect(_save_level)
	$UI/Opciones/ButtonLoad.pressed.connect(_on_button_load_pressed)

	# Añadir botones al grupo
	$UI/Menu/BotonBola.add_to_group("spawn_buttons")
	$UI/Menu/BotonPiso.add_to_group("spawn_buttons")
	$UI/Menu/BotonCubo.add_to_group("spawn_buttons")
	$UI/Menu/BotonTeleportador.add_to_group("spawn_buttons")
	$UI/Menu/BotonEsquina.add_to_group("spawn_buttons")
	$UI/Menu/BotonEsquinaRampa.add_to_group("spawn_buttons")
	$UI/Menu/BotonMoverMenu.add_to_group("spawn_buttons")


	# Conectar botones de mover
	$UI/Mover/BotonArriba.pressed.connect(_mover_arriba)
	$UI/Mover/BotonAbajo.pressed.connect(_mover_abajo)
	$UI/Mover/BotonIzquierda.pressed.connect(_mover_izquierda)
	$UI/Mover/BotonDerecha.pressed.connect(_mover_derecha)
	$UI/Mover/BotonRotarIzquierda.pressed.connect(_rotar_izquierda)
	$UI/Mover/BotonRotarDerecha.pressed.connect(_rotar_derecha)

	# Configurar plugin GodotGetImage
	if Engine.has_singleton(plugin_name):
		plugin = Engine.get_singleton(plugin_name)
		plugin.connect("image_request_completed", _on_image_request_completed)
		plugin.connect("error", _on_error)
		plugin.connect("permission_not_granted_by_user", _on_permission_not_granted_by_user)
		plugin.setOptions({
			"keep_aspect": true,
			"image_format": "png",
			"image_quality": 80,
		})
	else:
		print("Could not load plugin: ", plugin_name)

	# Cargar el archivo de guardado seleccionado si existe
	if selected_save_file != "":
		_reload(selected_save_file)
	

func _seleccionar_esquinarampa():
	if not game_state.descongelado and not showing_popup:
		game_state.modo = "EsquinaRampa"

func _seleccionar_esquina():
	if not game_state.descongelado and not showing_popup:
		game_state.modo = "Esquina"

func _seleccionar_teleportador():
	if not game_state.descongelado and not showing_popup:
		game_state.modo = "Teleportador"

func _seleccionar_bola():
	if not game_state.descongelado and not showing_popup:
		game_state.modo = "Bola"

func _seleccionar_piso():
	if not game_state.descongelado and not showing_popup:
		game_state.modo = "Piso"

func _seleccionar_cubo():
	if not game_state.descongelado and not showing_popup:
		game_state.modo = "Cubo"

func _zoom_in():
	if not showing_popup:
		var nuevo_zoom = $Camera2D.zoom + Vector2(ZOOM_STEP, ZOOM_STEP)
		$Camera2D.zoom = Vector2(clamp(nuevo_zoom.x, ZOOM_MIN, ZOOM_MAX), clamp(nuevo_zoom.y, ZOOM_MIN, ZOOM_MAX))
		game_state.camera_zoom = $Camera2D.zoom

func _zoom_out():
	if not showing_popup:
		var nuevo_zoom = $Camera2D.zoom - Vector2(ZOOM_STEP, ZOOM_STEP)
		$Camera2D.zoom = Vector2(clamp(nuevo_zoom.x, ZOOM_MIN, ZOOM_MAX), clamp(nuevo_zoom.y, ZOOM_MIN, ZOOM_MAX))
		game_state.camera_zoom = $Camera2D.zoom

func _rotar_izquierda():
	if game_state.seleccionando and ultimo_objeto_seleccionado and not showing_popup:
		ultimo_objeto_seleccionado.rotation_degrees -= 45
		var tipo_objeto = _get_object_type(ultimo_objeto_seleccionado)
		var obj_id = ultimo_objeto_seleccionado.get_meta("id", "")
		if tipo_objeto and obj_id:
			game_state.set_rotation(tipo_objeto, ultimo_objeto_seleccionado.rotation_degrees)
			game_state.update_object_rotation(obj_id, ultimo_objeto_seleccionado.rotation_degrees)
		if ultimo_objeto_seleccionado is RigidBody2D:
			ultimo_objeto_seleccionado.saved_state.rotation = deg_to_rad(ultimo_objeto_seleccionado.rotation_degrees)
			ultimo_objeto_seleccionado.teleport(ultimo_objeto_seleccionado.position)

func _rotar_derecha():
	if game_state.seleccionando and ultimo_objeto_seleccionado and not showing_popup:
		ultimo_objeto_seleccionado.rotation_degrees += 45
		var tipo_objeto = _get_object_type(ultimo_objeto_seleccionado)
		var obj_id = ultimo_objeto_seleccionado.get_meta("id", "")
		if tipo_objeto and obj_id:
			game_state.set_rotation(tipo_objeto, ultimo_objeto_seleccionado.rotation_degrees)
			game_state.update_object_rotation(obj_id, ultimo_objeto_seleccionado.rotation_degrees)
		if ultimo_objeto_seleccionado is RigidBody2D:
			ultimo_objeto_seleccionado.saved_state.rotation = deg_to_rad(ultimo_objeto_seleccionado.rotation_degrees)
			ultimo_objeto_seleccionado.teleport(ultimo_objeto_seleccionado.position)

func _mover_objeto(direccion: Vector2):
	if game_state.seleccionando and ultimo_objeto_seleccionado and not showing_popup:
		var tile_size = 250
		var vieja_posicion = ultimo_objeto_seleccionado.position
		var nueva_posicion = vieja_posicion + (direccion * tile_size)
		ultimo_objeto_seleccionado.position = nueva_posicion

		var obj_id = ultimo_objeto_seleccionado.get_meta("id", "")
		if obj_id:
			game_state.update_object_position(obj_id, nueva_posicion)
			if ultimo_objeto_seleccionado is RigidBody2D:
				ultimo_objeto_seleccionado.teleport(nueva_posicion)
				game_state.set_bola_initial_position(obj_id, nueva_posicion)
		
		var vieja_tile = Vector2(floor(vieja_posicion.x / tile_size), floor(vieja_posicion.y / tile_size))
		var nueva_tile = Vector2(floor(nueva_posicion.x / tile_size), floor(nueva_posicion.y / tile_size))
		game_state.set_tile_occupied(vieja_tile, false)
		game_state.set_tile_occupied(nueva_tile, true)

		# Actualizar la línea si es un teleportador o punto de teletransporte
		var tipo_objeto = _get_object_type(ultimo_objeto_seleccionado)
		if tipo_objeto == "Teleportador":
			var line = game_state.teleport_lines.get(obj_id)
			if line and is_instance_valid(line) and is_instance_valid(ultimo_objeto_seleccionado.teleport_target):
				line.set_point_position(0, nueva_posicion)
				line.set_point_position(1, ultimo_objeto_seleccionado.teleport_target.position)
				line.visible = not game_state.descongelado  # Asegurar visibilidad según estado
		elif tipo_objeto == "PuntoTeletransporte":
			for tele in get_tree().get_nodes_in_group("teleportadores"):
				if tele.teleport_target == ultimo_objeto_seleccionado:
					var tele_id = tele.get_meta("id", "")
					var line = game_state.teleport_lines.get(tele_id)
					if line and is_instance_valid(line):
						line.set_point_position(0, tele.position)
						line.set_point_position(1, nueva_posicion)
						line.visible = not game_state.descongelado  # Asegurar visibilidad según estado
					break

func _mover_arriba():
	_mover_objeto(Vector2(0, -1))

func _mover_abajo():
	_mover_objeto(Vector2(0, 1))

func _mover_izquierda():
	_mover_objeto(Vector2(-1, 0))

func _mover_derecha():
	_mover_objeto(Vector2(1, 0))

func _alternar_seleccionar():
	if not showing_popup:
		game_state.seleccionando = !game_state.seleccionando

		if game_state.seleccionando:
			var tween = create_tween()
			tween.tween_property($UI/Mover, "position:y", game_state.ui_botones_mover_position.y - 450, ANIMATION_DURATION3)\
				.set_ease(Tween.EASE_OUT)\
				.set_trans(Tween.TRANS_ELASTIC)
		else:
			var tween2 = create_tween()
			tween2.tween_property($UI/Mover, "position:y", game_state.ui_botones_mover_position.y, ANIMATION_DURATION3)\
				.set_ease(Tween.EASE_IN_OUT)\
				.set_trans(Tween.TRANS_ELASTIC)
			if ultimo_objeto_seleccionado and is_instance_valid(ultimo_objeto_seleccionado):
				var tipo_objeto = _get_object_type(ultimo_objeto_seleccionado)
				if tipo_objeto == "Cubo":
					var outline_sprite = ultimo_objeto_seleccionado.get_node_or_null("Sprite2D/Outline")
					var inline_sprite = ultimo_objeto_seleccionado.get_node_or_null("Sprite2D/Inline")
					if outline_sprite and outline_sprite.material:
						outline_sprite.material.set_shader_parameter("seleccionado", false)
					if inline_sprite and inline_sprite.material:
						inline_sprite.material.set_shader_parameter("seleccionado", false)
				else:
					var sprite = ultimo_objeto_seleccionado.get_node_or_null("Sprite2D")
					if sprite and sprite.material:
						sprite.material.set_shader_parameter("seleccionado", false)
				ultimo_objeto_seleccionado = null

		if game_state.seleccionando:
			$UI/Opciones/BotonSelect.texture_normal = load("res://Texturas/DeseleccionarButton.png")
			$UI/Opciones/BotonSelect.texture_pressed = load("res://Texturas/DeseleccionarButtonPressed.png")
			$UI/Opciones/BotonEliminar.modulate = Color(0.25, 0.25, 0.25)
			$UI/Opciones/BotonEliminar.disabled = true
			$UI/Opciones/BotonDescongelar.modulate = Color(0.25, 0.25, 0.25)
			$UI/Opciones/BotonDescongelar.disabled = true
		else:
			$UI/Opciones/BotonSelect.texture_normal = load("res://Texturas/SeleccionarButton.png")
			$UI/Opciones/BotonSelect.texture_pressed = load("res://Texturas/SeleccionarButtonPressed.png")
			$UI/Opciones/BotonEliminar.modulate = Color(1, 1, 1)
			$UI/Opciones/BotonEliminar.disabled = false
			$UI/Opciones/BotonDescongelar.modulate = Color(1, 1, 1)
			$UI/Opciones/BotonDescongelar.disabled = false
			$UI/Opciones/BotonLink.visible = false
			game_state.is_boton_link_visible = false

func _alternar_congelar_descongelar():
	if not showing_popup:
		$UI/Opciones/BotonSelect.modulate = Color(0.25, 0.25, 0.25)
		$UI/Opciones/BotonSelect.disabled = true

		var tween = create_tween()
		tween.tween_property($UI/Opciones/BotonReiniciar, "position:x", game_state.ui_boton_reiniciar_position.x - 160, ANIMATION_DURATION2)\
			.set_ease(Tween.EASE_IN_OUT)\
			.set_trans(Tween.TRANS_QUINT)

		var tween2 = create_tween()
		tween2.tween_property($UI/Opciones/BotonDescongelar, "position:y", game_state.ui_boton_descongelar_position.y - 130, ANIMATION_DURATION2)\
			.set_ease(Tween.EASE_IN_OUT)\
			.set_trans(Tween.TRANS_QUINT)

		game_state.descongelado = !game_state.descongelado

		if game_state.descongelado:
			$UI/Opciones/BotonDescongelar.texture_normal = load("res://Texturas/PausaButton.png")
			$UI/Opciones/BotonDescongelar.texture_pressed = load("res://Texturas/PausaButtonPressed.png")
			$UI/Opciones/BotonEliminar.modulate = Color(0.25, 0.25, 0.25)
			$UI/Opciones/BotonEliminar.disabled = true
			for bola in get_tree().get_nodes_in_group("bolas"):
				if bola is RigidBody2D and not bola.is_deactivated:
					bola.resume_physics()
			for button in get_tree().get_nodes_in_group("spawn_buttons"):
				if button is BaseButton:
					button.modulate = Color(0.25, 0.25, 0.25)
		else:
			for button in get_tree().get_nodes_in_group("spawn_buttons"):
				if button is BaseButton:
					button.modulate = Color(1.0, 1.0, 1.0)
			$UI/Opciones/BotonDescongelar.texture_normal = load("res://Texturas/PlayButton.png")
			$UI/Opciones/BotonDescongelar.texture_pressed = load("res://Texturas/PlayButtonPressed.png")
			for bola in get_tree().get_nodes_in_group("bolas"):
				if bola is RigidBody2D and not bola.is_deactivated:
					bola.pause_physics()

		var disabled_state = game_state.descongelado
		for button in get_tree().get_nodes_in_group("spawn_buttons"):
			if button is BaseButton:
				button.disabled = disabled_state

		# Actualizar visibilidad de todas las líneas
		for line in game_state.teleport_lines.values():
			if is_instance_valid(line):
				line.visible = not game_state.descongelado

func _mover_menu():
	if not showing_popup:
		game_state.menu_moved_up = !game_state.menu_moved_up
		game_state.menu_moved_right = !game_state.menu_moved_right

		var target_y = game_state.ui_menu_position.y
		var target_x = game_state.ui_options_position.x

		if game_state.menu_moved_up:
			target_y -= MOVE_OFFSET
		if game_state.menu_moved_right:
			target_x -= MOVE_OFFSET

		var tween = create_tween()
		tween.tween_property($UI/Menu, "position:y", target_y, ANIMATION_DURATION)\
			.set_ease(Tween.EASE_IN_OUT)\
			.set_trans(Tween.TRANS_QUINT)

		var tween2 = create_tween()
		tween2.tween_property($UI/Opciones, "position:x", target_x, ANIMATION_DURATION)\
			.set_ease(Tween.EASE_IN_OUT)\
			.set_trans(Tween.TRANS_QUINT)

		var tween3 = create_tween()
		tween3.tween_property($UI/Menu/BotonMoverMenu, "rotation_degrees", $UI/Menu/BotonMoverMenu.rotation_degrees + 180.0, ANIMATION_DURATION)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_BOUNCE)

func _reiniciar():
	if game_state.descongelado and not showing_popup:
		_alternar_congelar_descongelar()
		
		game_state.descongelado = false
		$UI/Opciones/BotonDescongelar.texture_normal = load("res://Texturas/PlayButton.png")
		$UI/Opciones/BotonEliminar.modulate = Color(1.0, 1.0, 1.0)
		$UI/Opciones/BotonEliminar.disabled = false
		$UI/Opciones/BotonSelect.modulate = Color(1, 1, 1)
		$UI/Opciones/BotonSelect.disabled = false

		for bola in get_tree().get_nodes_in_group("bolas"):
			if bola is RigidBody2D:
				var obj_id = bola.get_meta("id", "")
				if obj_id and game_state.get_bola_initial_position(obj_id):
					var target_position = game_state.get_bola_initial_position(obj_id)
					if bola.is_deactivated:
						bola.reactivate()
					bola.saved_state.linear_velocity = Vector2.ZERO
					bola.saved_state.angular_velocity = 0.0
					bola.saved_state.position = target_position
					bola.global_transform.origin = target_position
					bola.restart_physics(target_position)

		var disabled_state = game_state.descongelado
		for button in get_tree().get_nodes_in_group("spawn_buttons"):
			if button is BaseButton:
				button.disabled = disabled_state
				if game_state.descongelado:
					button.modulate = Color(0.25, 0.25, 0.25)
				else:
					button.modulate = Color(1.0, 1.0, 1.0)

		var tween = create_tween()
		tween.tween_property($UI/Opciones/BotonReiniciar, "position:x", game_state.ui_boton_reiniciar_position.x, ANIMATION_DURATION2)\
			.set_ease(Tween.EASE_IN_OUT)\
			.set_trans(Tween.TRANS_QUINT)

		var tween2 = create_tween()
		tween2.tween_property($UI/Opciones/BotonDescongelar, "position:y", game_state.ui_boton_descongelar_position.y, ANIMATION_DURATION2)\
			.set_ease(Tween.EASE_IN_OUT)\
			.set_trans(Tween.TRANS_QUINT)

func _eliminar():
	if not showing_popup:
			
		if not game_state.is_deleting and ultimo_objeto_seleccionado:
			var collider = ultimo_objeto_seleccionado
			var obj_id = collider.get_meta("id", "")
			
			if collider is RigidBody2D and obj_id:
				game_state.remove_bola_initial_position(obj_id)
				collider.remove_from_group("bolas")
			if obj_id:
				game_state.remove_object(obj_id)
			
			if collider.is_in_group("teleportadores"):
				var target = collider.teleport_target
				if target and target.has_meta("id"):
					var target_id = target.get_meta("id", "")
					game_state.remove_object(target_id)
					target.queue_free()
				# Eliminar la línea asociada
				var line = game_state.teleport_lines.get(obj_id)
				if line and is_instance_valid(line):
					line.queue_free()
					game_state.teleport_lines.erase(obj_id)
			elif collider.is_in_group("puntos_teletransporte"):
				for tele in get_tree().get_nodes_in_group("teleportadores"):
					if tele.teleport_target == collider:
						var tele_id = tele.get_meta("id", "")
						game_state.remove_object(tele_id)
						# Eliminar la línea asociada
						var line = game_state.teleport_lines.get(tele_id)
						if line and is_instance_valid(line):
							line.queue_free()
							game_state.teleport_lines.erase(tele_id)
						tele.queue_free()
						break
			
			var tile_pos = Vector2(floor(collider.position.x / 250), floor(collider.position.y / 250))
			game_state.set_tile_occupied(tile_pos, false)
			collider.queue_free()
			ultimo_objeto_seleccionado = null
		
		# Alternar modo de eliminación
		game_state.is_deleting = !game_state.is_deleting
		if game_state.is_deleting:
			$UI/Opciones/BotonEliminar.texture_normal = load("res://Texturas/CancelarButton.png")
			$UI/Opciones/BotonEliminar.texture_pressed = load("res://Texturas/CancelarButtonPressed.png")
			for button in $UI/Menu.get_children():
				button.modulate = Color(0.25, 0.25, 0.25)
				button.disabled = true
			for button in $UI/Opciones.get_children():
				if button != $UI/Opciones/BotonEliminar:
					button.modulate = Color(0.25, 0.25, 0.25)
					button.disabled = true
		else:
			$UI/Opciones/BotonEliminar.texture_normal = load("res://Texturas/EliminarButton.png")
			$UI/Opciones/BotonEliminar.texture_pressed = load("res://Texturas/EliminarButtonPressed.png")
			for button in $UI/Menu.get_children():
				button.modulate = Color(1.0, 1.0, 1.0)
				button.disabled = false
			for button in $UI/Opciones.get_children():
				button.modulate = Color(1.0, 1.0, 1.0)
				button.disabled = false

func _input(event):
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed and not showing_popup:
		initial_touch_position = event.position
		ultima_posicion_toque = event.position
		is_dragging = false
		touch_over_buttons = false
		for button in $UI/Menu.get_children():
			if button is BaseButton and button.is_pressed():
				touch_over_buttons = true
				break
		if not touch_over_buttons:
			for button in $UI/Opciones.get_children():
				if button is BaseButton and button.is_pressed():
					touch_over_buttons = true
					break
		if not touch_over_buttons:
			for button in $UI/Mover.get_children():
				if button is BaseButton and button.is_pressed():
					touch_over_buttons = true
					break

	elif event is InputEventScreenDrag and not showing_popup:
		var distance_moved = (event.position - initial_touch_position).length()
		if distance_moved > DRAG_THRESHOLD and not touch_over_buttons:
			is_dragging = true
			var delta = ultima_posicion_toque - event.position
			$Camera2D.position += delta
			$Camera2D.position.x = clamp($Camera2D.position.x, CAMERA_LIMIT_LEFT, CAMERA_LIMIT_RIGHT)
			$Camera2D.position.y = clamp($Camera2D.position.y, CAMERA_LIMIT_TOP, CAMERA_LIMIT_BOTTOM)
			ultima_posicion_toque = event.position
			game_state.camera_position = $Camera2D.position

	elif (event is InputEventScreenTouch or event is InputEventMouseButton) and not event.pressed and not showing_popup:
		if touch_over_buttons:
			return
		if not is_dragging:
			var viewport_size = get_viewport_rect().size
			var screen_center = viewport_size / 2
			var camera_zoom = $Camera2D.zoom
			var posicion_mundo = $Camera2D.position + ((event.position - screen_center) / camera_zoom)

			if game_state.is_deleting:
				var space_state = get_world_2d().direct_space_state
				var query = PhysicsPointQueryParameters2D.new()
				query.position = posicion_mundo
				query.collision_mask = (1 << 0) | (1 << 1)
				query.collide_with_bodies = true
				query.collide_with_areas = true
				var results = space_state.intersect_point(query)

				if results.size() > 0:
					var collider = null
					for result in results:
						var candidate = result.collider
						if candidate and is_instance_valid(candidate):
							if ((candidate is Area2D and candidate.get_script() and (
								candidate.get_script().resource_path == "res://teleportador.gd" or
								candidate.get_script().resource_path == "res://punto_teletransporte.gd" or
								candidate.get_script().resource_path == "res://cubo.gd")) or
								candidate is RigidBody2D or candidate is StaticBody2D):
								collider = candidate
								break

					if collider:
						var tile_size = 250
						var tile_pos = Vector2(floor(collider.position.x / tile_size), floor(collider.position.y / tile_size))
						var tile_key = Vector2(tile_pos.x, tile_pos.y)
						var obj_id = collider.get_meta("id", "")

						if collider is Area2D and collider.get_script() and collider.get_script().resource_path == "res://teleportador.gd":
							if collider.teleport_target and is_instance_valid(collider.teleport_target):
								var punto_tile_pos = Vector2(floor(collider.teleport_target.position.x / tile_size), floor(collider.position.y / tile_size))
								var punto_tile_key = Vector2(punto_tile_pos.x, punto_tile_pos.y)
								if game_state.is_tile_occupied(punto_tile_key):
									game_state.set_tile_occupied(punto_tile_key, false)
								var punto_id = collider.teleport_target.get_meta("id", "")
								if punto_id:
									game_state.remove_object(punto_id)
								collider.teleport_target.queue_free()
						elif collider is Area2D and collider.get_script() and collider.get_script().resource_path == "res://punto_teletransporte.gd":
							for teleportador in get_tree().get_nodes_in_group("teleportadores"):
								if teleportador.teleport_target == collider:
									var tele_tile_pos = Vector2(floor(teleportador.position.x / tile_size), floor(teleportador.position.y / tile_size))
									var tele_tile_key = Vector2(tele_tile_pos.x, tele_tile_pos.y)
									if game_state.is_tile_occupied(tele_tile_key):
										game_state.set_tile_occupied(tele_tile_key, false)
									var tele_id = teleportador.get_meta("id", "")
									if tele_id:
										game_state.remove_object(tele_id)
									teleportador.queue_free()
									break

						if collider is RigidBody2D and obj_id:
							game_state.remove_bola_initial_position(obj_id)
							collider.remove_from_group("bolas")

						if game_state.is_tile_occupied(tile_key):
							game_state.set_tile_occupied(tile_key, false)

						if obj_id:
							game_state.remove_object(obj_id)

						collider.queue_free()

						if ultimo_objeto_seleccionado == collider:
							ultimo_objeto_seleccionado = null
							$UI/Opciones/BotonLink.visible = false
							game_state.is_boton_link_visible = false

						PhysicsServer2D.set_active(true)
						await get_tree().create_timer(0.0).timeout

			elif game_state.seleccionando:
				var space_state = get_world_2d().direct_space_state
				var query = PhysicsPointQueryParameters2D.new()
				query.position = posicion_mundo
				query.collision_mask = (1 << 0) | (1 << 1)
				query.collide_with_bodies = true
				query.collide_with_areas = true
				var results = space_state.intersect_point(query)

				if results.size() > 0:
					var collider = null
					for result in results:
						var candidate = result.collider
						if candidate and is_instance_valid(candidate):
							if ((candidate is Area2D and candidate.get_script() and (
								candidate.get_script().resource_path == "res://teleportador.gd" or
								candidate.get_script().resource_path == "res://punto_teletransporte.gd" or
								candidate.get_script().resource_path == "res://cubo.gd")) or
								candidate is RigidBody2D or candidate is StaticBody2D):
								collider = candidate
								break

					if collider:
						# Desactivar el shader del objeto anteriormente seleccionado
						if ultimo_objeto_seleccionado and ultimo_objeto_seleccionado != collider and is_instance_valid(ultimo_objeto_seleccionado):
							var tipo_anterior = _get_object_type(ultimo_objeto_seleccionado)
							if tipo_anterior == "Cubo":
								var outline_anterior = ultimo_objeto_seleccionado.get_node_or_null("Sprite2D/Outline")
								var inline_anterior = ultimo_objeto_seleccionado.get_node_or_null("Sprite2D/Inline")
								if outline_anterior and outline_anterior.material:
									outline_anterior.material.set_shader_parameter("seleccionado", false)
								if inline_anterior and inline_anterior.material:
									inline_anterior.material.set_shader_parameter("seleccionado", false)
							else:
								var sprite_anterior = ultimo_objeto_seleccionado.get_node_or_null("Sprite2D")
								if sprite_anterior and sprite_anterior.material:
									sprite_anterior.material.set_shader_parameter("seleccionado", false)

						# Activar el shader en el objeto seleccionado
						var tipo_objeto = _get_object_type(collider)
						if tipo_objeto == "Cubo":
							var outline_sprite = collider.get_node_or_null("Sprite2D/Outline")
							var inline_sprite = collider.get_node_or_null("Sprite2D/Inline")
							if outline_sprite and outline_sprite.material:
								outline_sprite.material.set_shader_parameter("seleccionado", true)
							if inline_sprite and inline_sprite.material:
								inline_sprite.material.set_shader_parameter("seleccionado", true)
						else:
							var sprite = collider.get_node_or_null("Sprite2D")
							if sprite and sprite.material:
								sprite.material.set_shader_parameter("seleccionado", true)

						ultimo_objeto_seleccionado = collider
						# Mostrar BotonLink si es un cubo o bola
						if has_script(collider, "res://bola.gd"):
							$UI/Opciones/BotonLink.visible = true
							game_state.is_boton_link_visible = true
							$UI/Opciones/ButtonColor.visible = false
						elif has_script(collider, "res://cubo.gd"):
							$UI/Opciones/BotonLink.visible = false
							game_state.is_boton_link_visible = false
							$UI/Opciones/ButtonColor.visible = true
						else:
							$UI/Opciones/BotonLink.visible = false
							game_state.is_boton_link_visible = false
							$UI/Opciones/ButtonColor.visible = false

			elif not game_state.seleccionando and not game_state.is_deleting:
				if not game_state.descongelado:
					var tile_size = 250
					var tile_pos = Vector2(floor(posicion_mundo.x / tile_size), floor(posicion_mundo.y / tile_size))
					var tile_key = Vector2(tile_pos.x, tile_pos.y)
					if not game_state.is_tile_occupied(tile_key):
						var spawn_pos = tile_pos * tile_size + Vector2(tile_size / 2.0, tile_size / 2.0)
						var obj_id = ""
						if game_state.modo == "Bola":
							obj_id = spawn_bola(spawn_pos)
						elif game_state.modo == "Piso":
							obj_id = spawn_piso(spawn_pos)
						elif game_state.modo == "Cubo":
							obj_id = spawn_cubo(spawn_pos)
						elif game_state.modo == "Teleportador":
							obj_id = spawn_teleportador(spawn_pos)
						elif game_state.modo == "Esquina":
							obj_id = spawn_esquina(spawn_pos)
						elif game_state.modo == "EsquinaRampa":
							obj_id = spawn_esquinarampa(spawn_pos)
						if obj_id:
							game_state.set_tile_occupied(tile_key, true)
					else:
						print("Este tile ya está ocupado!")

# Función auxiliar para verificar el script
func has_script(node: Node, script_path: String) -> bool:
	var script = node.get_script()
	if script and script.resource_path == script_path:
		return true
	return false
	
func _on_boton_link_pressed():
	if not plugin:
		print(plugin_name, " plugin not loaded!")
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "Error: El plugin GodotGetImage no está cargado."
		dialog.ok_button_text = "Aceptar"
		add_child(dialog)
		dialog.popup_centered()
		return
		
	request_storage_permissions()
	plugin.getGalleryImage()


func request_storage_permissions():
	if OS.has_feature("android"):
		var permissions = [
			"android.permission.READ_EXTERNAL_STORAGE",
			"android.permission.READ_MEDIA_IMAGES"
		]
		print("Solicitando permisos: ", permissions)
		OS.request_permissions()  # Solicita todos los permisos declarados
		# Esperar un breve momento para que los permisos se procesen
		await get_tree().create_timer(0.5).timeout
		var granted = OS.get_granted_permissions()
		print("Permisos otorgados: ", granted)
		
	else:
		print("No está ejecutándose en Android, no se requieren permisos.")
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "Esta función solo está disponible en Android."
		dialog.ok_button_text = "Aceptar"
		add_child(dialog)
		dialog.popup_centered()

func _on_image_request_completed(dict):
	print("Image request completed. Dictionary received: ", dict)
	
	if dict.values().size() > 0:
		var img_buffer = dict.values()[0]
		print("Image buffer size: ", img_buffer.size(), " bytes")

		var image = Image.new()
		var error = image.load_png_from_buffer(img_buffer)
		if error != OK:
			print("Error loading PNG buffer: ", error)
			error = image.load_jpg_from_buffer(img_buffer)
			if error != OK:
				print("Error loading JPG buffer: ", error)
				return
			else:
				print("Successfully loaded image as JPG")
		else:
			print("Successfully loaded image as PNG")

		if image.get_format() != Image.FORMAT_RGBA8:
			image.convert(Image.FORMAT_RGBA8)

		var width = image.get_width()
		var height = image.get_height()
		var center = Vector2(width / 2.0, height / 2.0)
		var radius = min(width, height) / 2.0
		var opcionesButtons = $/root/Main/UI/Opciones
		
		var sepuede: bool = true
		
		if width < 250 or height < 250:
			await get_tree().create_timer(0.5).timeout
			opcionesButtons._on_minsize_detected()
			sepuede = false
		if width > 3000 or height > 3000:
			await get_tree().create_timer(0.5).timeout
			opcionesButtons._on_maxsize_detected()
			sepuede = false
			
		if sepuede:
			for x in range(width):
				for y in range(height):
					var pixel_pos = Vector2(x, y)
					var distance = pixel_pos.distance_to(center)
					if distance > radius:
						image.set_pixel(x, y, Color(0, 0, 0, 0))

			var texture_path = game_state.save_image(image)
			var image_node = image_scene.instantiate()
			image_node.texture = ImageTexture.create_from_image(image)

			var sprite = ultimo_objeto_seleccionado.get_node_or_null("Sprite2D")
			if sprite:
				sprite.texture = image_node.texture
				var texture_size = sprite.texture.get_size()
				var circle_diameter = min(texture_size.x, texture_size.y)
				var target_diameter = 250.0
				var scale = target_diameter / circle_diameter
				sprite.scale = Vector2(scale, scale)

				var obj_id = ultimo_objeto_seleccionado.get_meta("id", "")
				if obj_id:
					game_state.update_object_texture(obj_id, texture_path)

				print("Circular texture assigned to Sprite2D with diameter of 250 pixels")
	else:
		
		var dialog = get_node_or_null("AcceptDialog")
		dialog.window_title = "Error"
		dialog.dialog_text = "No image buffers received in dictionary"
		dialog.ok_button_text = "Aceptar"
		dialog.popup_centered(Vector2i(300, 150))  # Tamaño ajustado para móviles
		print("No image buffers received in dictionary")

func _on_error(e):
	var dialog = get_node("AcceptDialog")
	dialog.window_title = "Error!"
	dialog.dialog_text = e
	dialog.show()

func _on_permission_not_granted_by_user(permission):
	print("User won't grant permission, explain why it's important!")
	var dialog = get_node("AcceptDialog")
	dialog.window_title = "Permission necessary"
	var permission_text = permission.capitalize().split(".")[-1]
	dialog.dialog_text = permission_text + "\n permission is necessary"
	dialog.show()
	plugin.resendPermission()

func spawn_bola(pos, rotation_degrees: float = -1.0, texture_path: String = "") -> String:
	var bola = bola_scene.instantiate()
	bola.position = pos
	var rot = rotation_degrees if rotation_degrees != -1.0 else game_state.get_rotation("Bola")
	var obj_id = game_state.add_object("res://Bola.tscn", pos, rot, texture_path)
	bola.set_meta("id", obj_id)

	var sprite = bola.get_node("Sprite2D")
	if sprite:
		sprite.material = material_base.duplicate()
		if texture_path != "":
			var image = game_state.load_image(texture_path)
			if image:
				sprite.texture = ImageTexture.create_from_image(image)
		var texture_size = sprite.texture.get_size() if sprite.texture else Vector2(1, 1)
		var circle_diameter = min(texture_size.x, texture_size.y)
		var target_diameter = 250.0
		var scale = target_diameter / circle_diameter if circle_diameter > 0 else 1.0
		sprite.scale = Vector2(scale, scale)

	var collision_shape = bola.get_node("CollisionShape2D")
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.scale = Vector2(1.0, 1.0)
		collision_shape.shape.radius = 125.0

	bola.add_to_group("bolas")
	game_state.set_bola_initial_position(obj_id, pos)
	add_child(bola)
	bola.rotation_degrees = rot
	if rot != 0.0:
		bola.saved_state.rotation = deg_to_rad(rot)
		bola.teleport(bola.position)
	return obj_id

func spawn_piso(pos, rotation_degrees: float = -1.0) -> String:
	var piso = piso_scene.instantiate()
	piso.position = pos
	var rot = rotation_degrees if rotation_degrees != -1.0 else game_state.get_rotation("Piso")
	var obj_id = game_state.add_object("res://Piso.tscn", pos, rot)
	piso.set_meta("id", obj_id)
	piso.set_meta("scene_path", "res://Piso.tscn")
	var sprite = piso.get_node("Sprite2D")
	if sprite:
		sprite.material = material_base.duplicate()
	piso.rotation_degrees = rot
	piso.add_to_group("pisos")
	add_child(piso)
	return obj_id

func spawn_cubo(pos, rotation_degrees: float = -1.0, texture_path: String = "") -> String:
	var cubo = cubo_scene.instantiate()
	cubo.position = pos
	var rot = rotation_degrees if rotation_degrees != -1.0 else game_state.get_rotation("Cubo")
	var obj_id = game_state.add_object("res://Cubo.tscn", pos, rot, texture_path)
	cubo.set_meta("id", obj_id)
	
	var outline_sprite = cubo.get_node("Sprite2D/Outline")
	var inline_sprite = cubo.get_node("Sprite2D/Inline")
	var sprite = cubo.get_node("Sprite2D")
	if sprite:
		sprite.material = material_base.duplicate()
		if texture_path != "":
			var image = game_state.load_image(texture_path)
			if image:
				sprite.texture = ImageTexture.create_from_image(image)
	
	if outline_sprite:
		outline_sprite.material = material_base.duplicate()
		if texture_path != "":
			var image = game_state.load_image(texture_path)
			if image:
				outline_sprite.texture = ImageTexture.create_from_image(image)
	
	if inline_sprite:
		inline_sprite.material = material_base.duplicate()
		if texture_path != "":
			var image = game_state.load_image(texture_path)
			if image:
				inline_sprite.texture = ImageTexture.create_from_image(image)
		# Aplicar el color almacenado
		for obj in game_state.objects:
			if obj.id == obj_id:
				inline_sprite.modulate = obj.color
				break
	
	cubo.add_to_group("cubos")
	cubo.rotation_degrees = rot
	cubo.set_collision_layer_value(1, true)
	cubo.set_collision_mask_value(1, true)
	add_child(cubo)
	return obj_id

func spawn_teleportador(tele_pos: Vector2, tele_rotation_degrees: float = -1.0, tele_texture_path: String = "", 
					   target_pos: Vector2 = Vector2.ZERO, target_rotation_degrees: float = -1.0, target_texture_path: String = "") -> String:
	var teleportador = teleportador_scene.instantiate()
	teleportador.position = tele_pos
	var tele_rot = tele_rotation_degrees if tele_rotation_degrees != -1.0 else game_state.get_rotation("Teleportador")
	var tele_id = game_state.add_object("res://Teleportador.tscn", tele_pos, tele_rot, tele_texture_path)
	teleportador.set_meta("id", tele_id)
	
	var tele_sprite = teleportador.get_node("Sprite2D")
	if tele_sprite:
		tele_sprite.material = material_base.duplicate()
		if tele_texture_path != "":
			var image = game_state.load_image(tele_texture_path)
			if image:
				tele_sprite.texture = ImageTexture.create_from_image(image)
	
	var punto = punto_teletransporte_scene.instantiate()
	var target_rot = target_rotation_degrees if target_rotation_degrees != -1.0 else game_state.get_rotation("PuntoTeletransporte")
	var target_id = game_state.add_object("res://PuntoTeletransporteIndividual.tscn", target_pos, target_rot, target_texture_path, {"teleportador_id": tele_id})
	punto.set_meta("id", target_id)
	
	var punto_sprite = punto.get_node("Sprite2D")
	if punto_sprite:
		punto_sprite.material = material_base.duplicate()
		if target_texture_path != "":
			var image = game_state.load_image(target_texture_path)
			if image:
				punto_sprite.texture = ImageTexture.create_from_image(image)
	
	teleportador.teleport_target = punto
	teleportador.add_to_group("teleportadores")
	punto.add_to_group("puntos_teletransporte")
	
	teleportador.rotation_degrees = tele_rot
	punto.rotation_degrees = target_rot
	punto.position = target_pos if target_pos != Vector2.ZERO else tele_pos + Vector2(250, 0)
	
	# Crear la línea
	var line = Line2D.new()
	line.add_point(tele_pos)
	line.add_point(punto.position)
	line.default_color = Color.RED
	line.width = 5.0  # Ancho de la línea (ajusta según necesites)
	line.z_index = -1  # Asegura que la línea esté detrás de los objetos
	line.visible = not game_state.descongelado  # Oculta la línea si el juego está despausado
	add_child(line)
	
	# Almacenar la línea en GameState
	game_state.teleport_lines[tele_id] = line
	
	add_child(teleportador)
	add_child(punto)
	return tele_id

func spawn_esquina(pos, rotation_degrees: float = -1.0) -> String:
	var esquina = esquina_scene.instantiate()
	esquina.position = pos
	var rot = rotation_degrees if rotation_degrees != -1.0 else game_state.get_rotation("Esquina")
	var obj_id = game_state.add_object("res://piso_esquina.tscn", pos, rot)
	esquina.set_meta("id", obj_id)
	esquina.set_meta("scene_path", "res://piso_esquina.tscn")
	var sprite = esquina.get_node("Sprite2D")
	if sprite:
		sprite.material = material_base.duplicate()
	esquina.rotation_degrees = rot
	esquina.add_to_group("esquinas")
	add_child(esquina)
	return obj_id

func spawn_esquinarampa(pos, rotation_degrees: float = -1.0) -> String:
	var esquinarampa = esquinarampa_scene.instantiate()
	esquinarampa.position = pos
	var rot = rotation_degrees if rotation_degrees != -1.0 else game_state.get_rotation("EsquinaRampa")
	var obj_id = game_state.add_object("res://esquina_rampa.tscn", pos, rot)
	esquinarampa.set_meta("id", obj_id)
	esquinarampa.set_meta("scene_path", "res://esquina_rampa.tscn")
	var sprite = esquinarampa.get_node("Sprite2D")
	if sprite:
		sprite.material = material_base.duplicate()
	esquinarampa.rotation_degrees = rot
	esquinarampa.add_to_group("esquinas_rampa")
	add_child(esquinarampa)
	return obj_id

func _get_object_type(obj) -> String:
	if obj is RigidBody2D:
		return "Bola"
	elif obj is StaticBody2D:
		var scene_path = obj.get_meta("scene_path", "")
		if scene_path == "res://piso_esquina.tscn":
			return "Esquina"
		elif scene_path == "res://esquina_rampa.tscn":
			return "EsquinaRampa"
		elif scene_path == "res://Piso.tscn":
			return "Piso"
		return "Piso"
	elif obj is Area2D and obj.get_script():
		var script_path = obj.get_script().resource_path
		if script_path == "res://cubo.gd":
			return "Cubo"
		elif script_path == "res://teleportador.gd":
			return "Teleportador"
		elif script_path == "res://punto_teletransporte.gd":
			return "PuntoTeletransporte"
	return ""

func _save_level():
	if not showing_popup:
		if selected_save_file == "":
			print("Error: No hay un archivo de guardado seleccionado")
			var dialog = AcceptDialog.new()
			dialog.dialog_text = "No se puede guardar: No hay un archivo de guardado seleccionado."
			dialog.ok_button_text = "Aceptar"
			add_child(dialog)
			dialog.popup_centered()
			return

		var level_file_path = SAVE_DIR + selected_save_file
		var level_data = []
		var valid_object_ids = {}
		for obj in get_tree().get_nodes_in_group("bolas") + get_tree().get_nodes_in_group("cubos") + \
				  get_tree().get_nodes_in_group("teleportadores") + get_tree().get_nodes_in_group("puntos_teletransporte") + \
				  get_tree().get_nodes_in_group("pisos") + get_tree().get_nodes_in_group("esquinas") + \
				  get_tree().get_nodes_in_group("esquinas_rampa"):
			var obj_id = obj.get_meta("id", "")
			if obj_id:
				valid_object_ids[obj_id] = true
		
		for obj in game_state.objects:
			if obj.scene_path in ["res://Bola.tscn", "res://Cubo.tscn", "res://Teleportador.tscn", 
								 "res://PuntoTeletransporteIndividual.tscn", "res://Piso.tscn", 
								 "res://piso_esquina.tscn", "res://esquina_rampa.tscn"] and \
			   valid_object_ids.has(obj.id):
				var data = {
					"id": obj.id,
					"scene_path": obj.scene_path,
					"position": [obj.position.x, obj.position.y],
					"rotation_degrees": obj.rotation_degrees,
					"texture_path": obj.texture_path,
					"color": [obj.color.r, obj.color.g, obj.color.b, obj.color.a]  # Guardar color
				}
				if obj.scene_path == "res://Teleportador.tscn":
					for target_obj in game_state.objects:
						if target_obj.scene_path == "res://PuntoTeletransporteIndividual.tscn" and \
						   target_obj.extra_data.get("teleportador_id", "") == obj.id:
							data["target_id"] = target_obj.id
							break
				level_data.append(data)
		
		var level_file = FileAccess.open(level_file_path, FileAccess.WRITE)
		if level_file:
			level_file.store_string(JSON.stringify(level_data, "  ", false))
			level_file.close()
			print("Nivel guardado en: ", level_file_path)
		else:
			print("Error al guardar el archivo en: ", level_file_path)

func _on_button_load_pressed():
	if not showing_popup:
		get_tree().change_scene_to_file("res://MenuGuardados.tscn")
	
func _reload(file_name: String):
	var file_path = SAVE_DIR + file_name
	if not FileAccess.file_exists(file_path):
		print("No se encontró el archivo de guardado: ", file_path)
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Error al abrir el archivo: ", file_path)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		print("Error al parsear JSON: ", json.get_error_message(), " en la línea ", json.get_error_line())
		return
	
	var level_data = json.get_data()
	if not level_data is Array:
		print("Datos inválidos: se esperaba un array")
		return
	
	var objects_by_id = {}
	for obj_data in level_data:
		objects_by_id[obj_data.id] = obj_data
	
	# Limpiar el estado actual
	for node in get_tree().get_nodes_in_group("bolas") + get_tree().get_nodes_in_group("cubos") + \
				get_tree().get_nodes_in_group("teleportadores") + get_tree().get_nodes_in_group("puntos_teletransporte") + \
				get_tree().get_nodes_in_group("pisos") + get_tree().get_nodes_in_group("esquinas") + \
				get_tree().get_nodes_in_group("esquinas_rampa"):
		node.queue_free()
	
	for line in game_state.teleport_lines.values():
		if is_instance_valid(line):
			line.queue_free()
	game_state.teleport_lines.clear()
	
	game_state.objects.clear()
	game_state.ocupados.clear()
	game_state.bola_initial_positions.clear()
	
	for obj_data in level_data:
		var scene_path = obj_data.scene_path
		var pos = Vector2(obj_data.position[0], obj_data.position[1])
		var rotation_degrees = obj_data.rotation_degrees
		var texture_path = obj_data.texture_path
		var color = Color(obj_data.color[0], obj_data.color[1], obj_data.color[2], obj_data.color[3]) if obj_data.has("color") else Color.WHITE
		var new_obj_id
		
		if scene_path == "res://Bola.tscn":
			new_obj_id = spawn_bola(pos, rotation_degrees, texture_path)
			game_state.set_rotation("Bola", rotation_degrees)
		elif scene_path == "res://Cubo.tscn":
			new_obj_id = spawn_cubo(pos, rotation_degrees, texture_path)
			game_state.set_rotation("Cubo", rotation_degrees)
			if new_obj_id:
				game_state.update_object_color(new_obj_id, color)
		elif scene_path == "res://Teleportador.tscn":
			var target_id = obj_data.get("target_id", "")
			var target_data = objects_by_id.get(target_id, {})
			var target_pos = Vector2(target_data.position[0], target_data.position[1]) if target_data.has("position") else pos + Vector2(250, 0)
			var target_rotation_degrees = target_data.get("rotation_degrees", 0.0)
			var target_texture_path = target_data.get("texture_path", "")
			new_obj_id = spawn_teleportador(pos, rotation_degrees, texture_path, target_pos, target_rotation_degrees, target_texture_path)
			game_state.set_rotation("Teleportador", rotation_degrees)
			if target_data.has("rotation_degrees"):
				game_state.set_rotation("PuntoTeletransporte", target_rotation_degrees)
		elif scene_path == "res://PuntoTeletransporteIndividual.tscn":
			continue
		elif scene_path == "res://Piso.tscn":
			new_obj_id = spawn_piso(pos, rotation_degrees)
			game_state.set_rotation("Piso", rotation_degrees)
		elif scene_path == "res://piso_esquina.tscn":
			new_obj_id = spawn_esquina(pos, rotation_degrees)
			game_state.set_rotation("Esquina", rotation_degrees)
		elif scene_path == "res://esquina_rampa.tscn":
			new_obj_id = spawn_esquinarampa(pos, rotation_degrees)
			game_state.set_rotation("EsquinaRampa", rotation_degrees)
		else:
			print("Scene path desconocido: ", scene_path)
		
		if new_obj_id:
			var tile_size = 250
			var tile_pos = Vector2(floor(pos.x / tile_size), floor(pos.y / tile_size))
			game_state.set_tile_occupied(tile_pos, true)


func _on_button_color_pressed() -> void:
	
	
	var colorpicker = $CanvasColor
	var opciones = $UI/Opciones
	colorpicker.visible = true
	$CanvasColor/TextureButton.disabled = false
	opciones.popInDoubleSize($/root/Main/CanvasColor/ColorPicker)
	opciones.popInDoubleSize($/root/Main/CanvasColor/TextureRect)
	opciones.popIn($/root/Main/CanvasColor/TextureButton)
	showing_popup = true
	print(showing_popup)



func _on_texture_button_pressed() -> void: #Boton de "OK" del colorPicker
	
	
	var colorpickerUI = $CanvasColor
	var colorpicker = $CanvasColor/ColorPicker
	var opciones = $UI/Opciones
	opciones.popOut($/root/Main/CanvasColor/ColorPicker)
	opciones.popOut($/root/Main/CanvasColor/TextureRect)
	opciones.popOut($/root/Main/CanvasColor/TextureButton)
	
	if ultimo_objeto_seleccionado and is_instance_valid(ultimo_objeto_seleccionado):
		
		var tipo_objeto = _get_object_type(ultimo_objeto_seleccionado)
		if tipo_objeto == "Cubo":
			
			var inline_sprite = ultimo_objeto_seleccionado.get_node_or_null("Sprite2D/InlineFalso")
			if inline_sprite:
				
				# Generar un color
				var new_color = colorpicker.color
				inline_sprite.modulate = new_color
				
				# Actualizar GameState para persistir el color
				var obj_id = ultimo_objeto_seleccionado.get_meta("id", "")
				if obj_id:
					print("Bienobjid")
					game_state.update_object_color(obj_id, new_color)
		else:
			
			$UI/Opciones/ButtonColor.modulate = Color(0.25, 0.25, 0.25)
	showing_popup = false
	print(showing_popup)
