extends Node2D

@export var bola_scene: PackedScene
@export var piso_scene: PackedScene
@export var cubo_scene: PackedScene
@export var teleportador_scene: PackedScene
@export var grid_tilemap: TileMap  # Referencia al TileMap de la cuadrícula
@export var esquina_scene: PackedScene
@export var esquinarampa_scene: PackedScene
@export var punto_teletransporte_scene: PackedScene

var modo = "Bola"  # Modo por defecto
var ultima_posicion_toque: Vector2  # Para rastrear el arrastre
var descongelado: bool = false  # Estado para indicar si las bolas están descongeladas
var seleccionando: bool = false #Estado para detectar si estamos en el modo de selección
var menu_moved_up: bool = false  # Estado para rastrear si el menú está movido hacia arriba
var menu_moved_right: bool = false # Estado para rastrear si las opciones se movieron hacia la derecha
var initial_BotonReiniciar_Position: Vector2 #Posición inicial del BotonReiniciar
var initial_BotonDescongelar_Position:Vector2 #Posición inicial del BotonDescongelar
var initial_BotonesMover_Position:Vector2 #Posición inicial de los botones para mover
var initial_menu_position: Vector2  # Posición inicial de $UI/Menu
var initial_options_position: Vector2 # Posición inicial de $UI/Opciones
var bola_initial_positions: Dictionary  # Diccionario para almacenar las posiciones originales de las bolas
var is_deleting: bool = false  # Nuevo: Estado para indicar si estamos en modo de eliminación
const ZOOM_MIN: float = 0.1  # Límite mínimo de zoom
const ZOOM_MAX: float = 2.0  # Límite máximo de zoom
const ZOOM_STEP: float = 0.1  # Incremento/decremento de zoom por clic
const MOVE_OFFSET: float = -250.0  # Desplazamiento relativo en píxeles
const ANIMATION_DURATION: float = 0.5  # Duración de la animación en segundos
const ANIMATION_DURATION2: float = 0.2  # Duración de la animación en segundos
const DRAG_THRESHOLD: float = 10.0  # Umbral en píxeles para considerar un arrastre
var ultimo_objeto_seleccionado = null  # Referencia al último objeto seleccionado
var is_boton_link_visible: bool = false  # Estado para rastrear si BotonLink está visible

# Diccionario para almacenar la última rotación por tipo de objeto (en grados)
var ultimas_rotaciones: Dictionary = {
	"Bola": 0.0,
	"Piso": 0.0,
	"Cubo": 0.0,
	"Teleportador": 0.0,
	"Esquina": 0.0,
	"EsquinaRampa": 0.0,
	"PuntoTeletransporte": 0.0
}

# Límites de la cámara
const CAMERA_LIMIT_LEFT: float = -5000.0   # Límite izquierdo (x mínimo)
const CAMERA_LIMIT_TOP: float = -10000.0   # Límite superior (y mínimo)
const CAMERA_LIMIT_RIGHT: float = 6000.0   # Límite derecho (x máximo)
const CAMERA_LIMIT_BOTTOM: float = 11000.0 # Límite inferior (y máximo)

# Variables para detectar arrastre
var is_dragging: bool = false  # Indica si estamos arrastrando
var initial_touch_position: Vector2  # Posición inicial del toque
var touch_over_buttons: bool = false  # Indica si el toque inicial fue sobre un botón

# Diccionario para rastrear qué tiles están ocupados por objetos
var ocupados: Dictionary = {}

#Materiales/Shaders
var material_base = load("res://materials/resaltado_emision.tres")

var plugin
var plugin_name = "GodotGetImage"

@onready var image_scene = preload("res://sprite_2d.tscn")

func _ready():
	# Guardar la posición inicial de $UI/Menu
	initial_menu_position = $UI/Menu.position
	initial_options_position = $UI/Opciones.position
	initial_BotonReiniciar_Position = $UI/Opciones/BotonReiniciar.position
	initial_BotonDescongelar_Position = $UI/Opciones/BotonDescongelar.position
	initial_BotonesMover_Position = $UI/Mover.position
	
	$UI/Menu/BotonMoverMenu.pivot_offset = $UI/Menu/BotonMoverMenu.size / 2
	
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
	$UI/Opciones/BotonLink.visible = false  # Ocultar el botón por defecto al iniciar
	
	# Añadir botones al grupo vía código
	$UI/Menu/BotonBola.add_to_group("spawn_buttons")
	$UI/Menu/BotonPiso.add_to_group("spawn_buttons")
	$UI/Menu/BotonCubo.add_to_group("spawn_buttons")
	$UI/Menu/BotonTeleportador.add_to_group("spawn_buttons")
	$UI/Menu/BotonEsquina.add_to_group("spawn_buttons")
	$UI/Menu/BotonEsquinaRampa.add_to_group("spawn_buttons")
	$UI/Menu/BotonMoverMenu.add_to_group("spawn_buttons")
	
	# Nuevo: Establecer la textura inicial de BotonEliminar
	$UI/Opciones/BotonEliminar.texture_normal = load("res://Texturas/basura.png")
	
	#Botones de Mover
	# Nueva conexión para el botón de mover arriba
	$UI/Mover/BotonArriba.pressed.connect(_mover_arriba)
	$UI/Mover/BotonAbajo.pressed.connect(_mover_abajo)
	$UI/Mover/BotonIzquierda.pressed.connect(_mover_izquierda)
	$UI/Mover/BotonDerecha.pressed.connect(_mover_derecha)
	$UI/Mover/BotonRotarIzquierda.pressed.connect(_rotar_izquierda)
	$UI/Mover/BotonRotarDerecha.pressed.connect(_rotar_derecha)
	
	if Engine.has_singleton(plugin_name):
		plugin = Engine.get_singleton(plugin_name)
	else:
		print("Could not load plugin: ", plugin_name)

#""" Set option for all following images """
	var options = {
		"image_height" : 250,
		"image_width" : 250,
		"keep_aspect" : true,
		"image_format" : "png"
		#"image_format" : "png"
	}

	if plugin:
		plugin.connect("image_request_completed", _on_image_request_completed)
		plugin.connect("error", _on_error)
		plugin.connect("permission_not_granted_by_user", _on_permission_not_granted_by_user)
		plugin.setOptions(options)

func _seleccionar_esquinarampa():
	if not descongelado:
		modo = "EsquinaRampa"

func _seleccionar_esquina():
	if not descongelado:
		modo = "Esquina"
	
func _seleccionar_teleportador():
	if not descongelado:
		modo = "Teleportador"
	
func _seleccionar_bola():
	if not descongelado:
		modo = "Bola"

func _seleccionar_piso():
	if not descongelado:
		modo = "Piso"
	
func _seleccionar_cubo():
	if not descongelado:
		modo = "Cubo"

func _zoom_in():
	var nuevo_zoom = $Camera2D.zoom + Vector2(ZOOM_STEP, ZOOM_STEP)
	$Camera2D.zoom = Vector2(clamp(nuevo_zoom.x, ZOOM_MIN, ZOOM_MAX), clamp(nuevo_zoom.y, ZOOM_MIN, ZOOM_MAX))

func _zoom_out():
	var nuevo_zoom = $Camera2D.zoom - Vector2(ZOOM_STEP, ZOOM_STEP)
	$Camera2D.zoom = Vector2(clamp(nuevo_zoom.x, ZOOM_MIN, ZOOM_MAX), clamp(nuevo_zoom.y, ZOOM_MIN, ZOOM_MAX))

func _rotar_izquierda():
	# Verificar si estamos en modo seleccionando y hay un objeto seleccionado
	if seleccionando and ultimo_objeto_seleccionado:
		# Rotar 45 grados a la izquierda (antihorario)
		ultimo_objeto_seleccionado.rotation_degrees -= 45
		
		# Determinar el tipo de objeto
		var tipo_objeto = ""
		if ultimo_objeto_seleccionado is RigidBody2D:
			tipo_objeto = "Bola"
		elif ultimo_objeto_seleccionado is StaticBody2D:
			# Verificar la escena instanciada para identificar Piso, Esquina o EsquinaRampa
			var scene_path = ultimo_objeto_seleccionado.get_meta("scene_path", "") if ultimo_objeto_seleccionado.has_meta("scene_path") else ""
			if scene_path == "res://Scenes/Esquina.tscn":
				tipo_objeto = "Esquina"
			elif scene_path == "res://Scenes/EsquinaRampa.tscn":
				tipo_objeto = "EsquinaRampa"
			else:
				tipo_objeto = "Piso"
		elif ultimo_objeto_seleccionado is Area2D and ultimo_objeto_seleccionado.get_script():
			var script_path = ultimo_objeto_seleccionado.get_script().resource_path
			if script_path == "res://cubo.gd":
				tipo_objeto = "Cubo"
			elif script_path == "res://teleportador.gd":
				tipo_objeto = "Teleportador"
			elif script_path == "res://punto_teletransporte.gd":
				tipo_objeto = "PuntoTeletransporte"
		
		# Guardar la rotación en el diccionario
		if tipo_objeto:
			ultimas_rotaciones[tipo_objeto] = ultimo_objeto_seleccionado.rotation_degrees
		
		# Si el objeto es una bola (RigidBody2D), actualizar su rotación guardada
		if ultimo_objeto_seleccionado is RigidBody2D:
			ultimo_objeto_seleccionado.saved_state.rotation = deg_to_rad(ultimo_objeto_seleccionado.rotation_degrees)
			ultimo_objeto_seleccionado.teleport(ultimo_objeto_seleccionado.position)

func _rotar_derecha():
	# Verificar si estamos en modo seleccionando y hay un objeto seleccionado
	if seleccionando and ultimo_objeto_seleccionado:
		# Rotar 45 grados a la derecha (horario)
		ultimo_objeto_seleccionado.rotation_degrees += 45
		
		# Determinar el tipo de objeto
		var tipo_objeto = ""
		if ultimo_objeto_seleccionado is RigidBody2D:
			tipo_objeto = "Bola"
		elif ultimo_objeto_seleccionado is StaticBody2D:
			# Verificar la escena instanciada para identificar Piso, Esquina o EsquinaRampa
			var scene_path = ultimo_objeto_seleccionado.get_meta("scene_path", "") if ultimo_objeto_seleccionado.has_meta("scene_path") else ""
			if scene_path == "res://Scenes/Esquina.tscn":
				tipo_objeto = "Esquina"
			elif scene_path == "res://Scenes/EsquinaRampa.tscn":
				tipo_objeto = "EsquinaRampa"
			else:
				tipo_objeto = "Piso"
		elif ultimo_objeto_seleccionado is Area2D and ultimo_objeto_seleccionado.get_script():
			var script_path = ultimo_objeto_seleccionado.get_script().resource_path
			if script_path == "res://cubo.gd":
				tipo_objeto = "Cubo"
			elif script_path == "res://teleportador.gd":
				tipo_objeto = "Teleportador"
			elif script_path == "res://punto_teletransporte.gd":
				tipo_objeto = "PuntoTeletransporte"
		
		# Guardar la rotación en el diccionario
		if tipo_objeto:
			ultimas_rotaciones[tipo_objeto] = ultimo_objeto_seleccionado.rotation_degrees
		
		# Si el objeto es una bola (RigidBody2D), actualizar su rotación guardada
		if ultimo_objeto_seleccionado is RigidBody2D:
			ultimo_objeto_seleccionado.saved_state.rotation = deg_to_rad(ultimo_objeto_seleccionado.rotation_degrees)
			ultimo_objeto_seleccionado.teleport(ultimo_objeto_seleccionado.position)
			
func _mover_objeto(direccion: Vector2):
	# Verificar si estamos en modo seleccionando y hay un objeto seleccionado
	if seleccionando and ultimo_objeto_seleccionado:
		var tile_size = 250
		
		# Guardar la posición actual como vieja posición antes de mover
		var vieja_posicion = ultimo_objeto_seleccionado.position
		# Calcular la nueva posición basada en la dirección
		var nueva_posicion = vieja_posicion + (direccion * tile_size)
		
		# Actualizar la posición del objeto
		ultimo_objeto_seleccionado.position = nueva_posicion
		
		# Si el objeto es una bola (RigidBody2D), usar teleport
		if ultimo_objeto_seleccionado is RigidBody2D:
			ultimo_objeto_seleccionado.teleport(nueva_posicion)
			if ultimo_objeto_seleccionado in bola_initial_positions:
				bola_initial_positions[ultimo_objeto_seleccionado] = nueva_posicion
		# Si el objeto es un teleportador, punto de teletransporte o cubo (Area2D), actualizar posición
		elif ultimo_objeto_seleccionado is Area2D and ultimo_objeto_seleccionado.get_script() and (ultimo_objeto_seleccionado.get_script().resource_path == "res://teleportador.gd" or ultimo_objeto_seleccionado.get_script().resource_path == "res://punto_teletransporte.gd" or ultimo_objeto_seleccionado.get_script().resource_path == "res://cubo.gd"):
			ultimo_objeto_seleccionado.position = nueva_posicion
		# Si el objeto es un piso o rampa (StaticBody2D), actualizar posición
		elif ultimo_objeto_seleccionado is StaticBody2D:
			ultimo_objeto_seleccionado.position = nueva_posicion
		
		# Actualizar el diccionario ocupados
		var vieja_tile = Vector2(floor(vieja_posicion.x / tile_size), floor(vieja_posicion.y / tile_size))
		var nueva_tile = Vector2(floor(nueva_posicion.x / tile_size), floor(nueva_posicion.y / tile_size))
		
		# Liberar el tile viejo si estaba ocupado
		if ocupados.has(vieja_tile):
			ocupados.erase(vieja_tile)
		
		# Marcar el tile nuevo como ocupado
		ocupados[nueva_tile] = true
		
func _mover_arriba():
	_mover_objeto(Vector2(0, -1))  # Mover hacia arriba (Y disminuye)

func _mover_abajo():
	_mover_objeto(Vector2(0, 1))   # Mover hacia abajo (Y aumenta)

func _mover_izquierda():
	_mover_objeto(Vector2(-1, 0))  # Mover hacia la izquierda (X disminuye)

func _mover_derecha():
	_mover_objeto(Vector2(1, 0))   # Mover hacia la derecha (X aumenta)

func _alternar_seleccionar():
	seleccionando = !seleccionando
	
	if seleccionando:
		var tween = create_tween()
		tween.tween_property($UI/Mover, "position:y", initial_BotonesMover_Position.y - 450, ANIMATION_DURATION2)\
			.set_ease(Tween.EASE_IN_OUT)\
			.set_trans(Tween.TRANS_QUINT)
	else:
		var tween2 = create_tween()
		tween2.tween_property($UI/Mover, "position:y", initial_BotonesMover_Position.y, ANIMATION_DURATION2)\
			.set_ease(Tween.EASE_IN_OUT)\
			.set_trans(Tween.TRANS_QUINT)
		# Desactivar el resaltado del último objeto seleccionado
		if ultimo_objeto_seleccionado:
			var sprite = ultimo_objeto_seleccionado.get_node_or_null("Sprite2D")
			if sprite and sprite.material:
				sprite.material.set_shader_parameter("seleccionado", false)
			ultimo_objeto_seleccionado = null
	#Cambiar la textura del botón según el estado
	if seleccionando:
		$UI/Opciones/BotonSelect.texture_normal = load("res://Texturas/deselect.png")
		# Oscurecer y desactivar estos botones
		$UI/Opciones/BotonEliminar.modulate = Color(0.25, 0.25, 0.25)
		$UI/Opciones/BotonEliminar.disabled = true
		$UI/Opciones/BotonDescongelar.modulate = Color(0.25, 0.25, 0.25)
		$UI/Opciones/BotonDescongelar.disabled = true
	else:
		$UI/Opciones/BotonSelect.texture_normal = load("res://Texturas/select.png")
		# Volver a la normalidad los botones
		$UI/Opciones/BotonEliminar.modulate = Color(1, 1, 1)
		$UI/Opciones/BotonEliminar.disabled = false
		$UI/Opciones/BotonDescongelar.modulate = Color(1, 1, 1)
		$UI/Opciones/BotonDescongelar.disabled = false
		
		$UI/Opciones/BotonLink.visible = false
		is_boton_link_visible = false
	
func _alternar_congelar_descongelar():
	
	$UI/Opciones/BotonSelect.modulate = Color(0.25, 0.25, 0.25)
	$UI/Opciones/BotonSelect.disabled = true

	
	#Mover BotonReiniciar
	var tween = create_tween()
	tween.tween_property($UI/Opciones/BotonReiniciar, "position:x", initial_BotonReiniciar_Position.x - 160 , ANIMATION_DURATION2)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_QUINT)
		
	#Mover a BotonDescongelar
	var tween2 = create_tween()
	tween2.tween_property($UI/Opciones/BotonDescongelar, "position:y", initial_BotonDescongelar_Position.y - 120 , ANIMATION_DURATION2)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_QUINT)
		
	descongelado = !descongelado  # Alternar el estado
	
	# Cambiar la textura del botón según el estado
	if descongelado:
		$UI/Opciones/BotonDescongelar.texture_normal = load("res://Texturas/Pausa.png")  # Cambiar a Pausa.png
		# Oscurecer y desactivar el boton eliminar
		$UI/Opciones/BotonEliminar.modulate = Color(0.25, 0.25, 0.25)
		$UI/Opciones/BotonEliminar.disabled = true
		# Descongelar (reanudar) todas las bolas
		for bola in get_tree().get_nodes_in_group("bolas"):
			if bola is RigidBody2D and not bola.is_deactivated:  # Solo reanudar bolas activas
				bola.resume_physics()
		for button in get_tree().get_nodes_in_group("spawn_buttons"):
			if button is BaseButton:
				button.modulate = Color(0.25, 0.25, 0.25)  # 75% más oscuro
	else:
		for button in get_tree().get_nodes_in_group("spawn_buttons"):
			if button is BaseButton:
				button.modulate = Color(1.0, 1.0, 1.0)  # Restaurar a normal (100% de brillo)
		
		$UI/Opciones/BotonDescongelar.texture_normal = load("res://Texturas/play.png")  # Restaurar a la textura original
		
		# Congelar (pausar) todas las bolas
		for bola in get_tree().get_nodes_in_group("bolas"):
			if bola is RigidBody2D and not bola.is_deactivated:  # Solo pausar bolas activas
				bola.pause_physics()
	
	# Deshabilitar/habilitar los botones de spawn
	var disabled_state = descongelado
	for button in get_tree().get_nodes_in_group("spawn_buttons"):
		if button is BaseButton:
			button.disabled = disabled_state
	

func _mover_menu():
	# Alternar entre mover hacia arriba y hacia abajo, y entre izquierda y derecha
	menu_moved_up = !menu_moved_up
	menu_moved_right = !menu_moved_right
	
	# Mover el nodo Menu usando su posición inicial como referencia
	var target_y = initial_menu_position.y  # Usar la posición inicial como base
	var target_x = initial_options_position.x # Usar la posición inicial de las opciones como base
	
	if menu_moved_up:
		target_y -= MOVE_OFFSET  # Mover 300 píxeles hacia arriba desde la posición inicial
	else:
		target_y += 0.0  # Volver a la posición inicial (sin desplazamiento adicional)
		
	if menu_moved_right:
		target_x -= MOVE_OFFSET
	else:
		target_x += 0.0
	
	# Crear un Tween para animar el movimiento del nodo Menu
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
	$UI/Opciones/BotonSelect.modulate = Color(1, 1, 1)
	$UI/Opciones/BotonSelect.disabled = false
	
	descongelado = false  # Establecer el estado como si las bolas estuvieran pausadas
	
	$UI/Opciones/BotonDescongelar.texture_normal = load("res://Texturas/play.png")  # Actualizar la textura de BotonDescongelar
	$UI/Opciones/BotonEliminar.modulate = Color(1.0, 1.0, 1.0)  # Aclarar
	$UI/Opciones/BotonEliminar.disabled = false
	
	# Pausar las físicas de inmediato para todas las bolas
	for bola in get_tree().get_nodes_in_group("bolas"):
		if bola is RigidBody2D:
			# Usar global_transform.origin para mover la bola sin conflictos con las físicas
			if bola_initial_positions.has(bola):
				var target_position = bola_initial_positions[bola]
				# Reactivar la bola si está desactivada
				if bola.is_deactivated:
					bola.reactivate()
				
				bola.saved_state.linear_velocity = Vector2.ZERO  # Detener cualquier velocidad lineal
				bola.saved_state.angular_velocity = 0.0  # Detener cualquier rotación
				bola.saved_state.position = target_position
				bola.global_transform.origin = target_position  # Restaurar la posición original usando global_transform
				
				bola.restart_physics(target_position)
	
	# Deshabilitar/oscurecer los botones de spawn como si BotonDescongelar hubiera pausado
	var disabled_state = descongelado
	for button in get_tree().get_nodes_in_group("spawn_buttons"):
		if button is BaseButton:
			button.disabled = disabled_state
			if descongelado:
				button.modulate = Color(0.25, 0.25, 0.25)  # Oscurecer
			else:
				button.modulate = Color(1.0, 1.0, 1.0)  # Restaurar brillo
	
	# Nuevo: Habilitar BotonEliminar después de reiniciar, ya que las bolas están en su posición inicial
	$UI/Opciones/BotonEliminar.disabled = false
	
	#Mover BotonReiniciar
	var tween = create_tween()
	tween.tween_property($UI/Opciones/BotonReiniciar, "position:x", initial_BotonReiniciar_Position.x , ANIMATION_DURATION2)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_QUINT)
		
	#Mover a BotonDescongelar
	var tween2 = create_tween()
	tween2.tween_property($UI/Opciones/BotonDescongelar, "position:y", initial_BotonDescongelar_Position.y , ANIMATION_DURATION2)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_QUINT)

func _eliminar():
	# Alternar el modo de eliminación
	is_deleting = !is_deleting
	
	# Cambiar las texturas del botón según el estado
	if is_deleting:
		$UI/Opciones/BotonEliminar.texture_normal = load("res://Texturas/cancelar.png")  # Modo de eliminación
		for button in $UI/Menu.get_children():
			button.modulate = Color(0.25, 0.25, 0.25)  # Oscurecer
			button.disabled = true
			
		for button in $UI/Opciones.get_children():
			if button != $UI/Opciones/BotonEliminar:
				button.modulate = Color(0.25, 0.25, 0.25)  # Oscurecer
				button.disabled = true
	else:
		$UI/Opciones/BotonEliminar.texture_normal = load("res://Texturas/basura.png")  # Modo normal
		for button in $UI/Menu.get_children():
			button.modulate = Color(1.0, 1.0, 1.0)  # Oscurecer
			button.disabled = false
			
		for button in $UI/Opciones.get_children():
			button.modulate = Color(1.0, 1.0, 1.0)  # Oscurecer
			button.disabled = false

func _input(event):
	# Detectar cuando se inicia un toque
	if event is InputEventScreenTouch and event.pressed:
		# Guardar la posición inicial del toque
		initial_touch_position = event.position
		ultima_posicion_toque = event.position  # Guardar para el arrastre potencial
		is_dragging = false  # Reiniciar el estado de arrastre

		# Verificar si algún botón de $UI/Menu o $UI/Opciones está siendo presionado
		touch_over_buttons = false
		# Verificar botones en $UI/Menu
		for button in $UI/Menu.get_children():
			if button is BaseButton and button.is_pressed():
				touch_over_buttons = true
				break
		# Si no se encontró un botón presionado en $UI/Menu, verificar en $UI/Opciones
		if not touch_over_buttons:
			for button in $UI/Opciones.get_children():
				if button is BaseButton and button.is_pressed():
					touch_over_buttons = true
					break
		# Si no se encontró un botón presionado en $UI/Opciones, verificar en $UI/Mover
		if not touch_over_buttons:
			for button in $UI/Mover.get_children():
				if button is BaseButton and button.is_pressed():
					touch_over_buttons = true
					break

	# Detectar cuando el dedo se mueve mientras está presionado
	elif event is InputEventScreenDrag:
		var distance_moved = (event.position - initial_touch_position).length()
		# Si la distancia movida supera el umbral y el toque inicial no fue sobre un botón, mover la cámara
		if distance_moved > DRAG_THRESHOLD and not touch_over_buttons:
			is_dragging = true
			var delta = ultima_posicion_toque - event.position
			$Camera2D.position += delta
			# Aplicar límites a la posición de la cámara
			$Camera2D.position.x = clamp($Camera2D.position.x, CAMERA_LIMIT_LEFT, CAMERA_LIMIT_RIGHT)
			$Camera2D.position.y = clamp($Camera2D.position.y, CAMERA_LIMIT_TOP, CAMERA_LIMIT_BOTTOM)
			ultima_posicion_toque = event.position

	# Detectar cuando se suelta el toque
	elif event is InputEventScreenTouch and not event.pressed:
		# Si el toque inicial fue sobre un botón, no hacer nada
		if touch_over_buttons:
			return
			
		# Si no fue un arrastre, procesar el toque
		if not is_dragging:
			# Obtener el tamaño del viewport (pantalla)
			var viewport_size = get_viewport_rect().size
			# Convertir coordenadas de pantalla a coordenadas del mundo, considerando el zoom
			var screen_center = viewport_size / 2
			var camera_zoom = $Camera2D.zoom
			var posicion_mundo = $Camera2D.position + ((event.position - screen_center) / camera_zoom)

			# Si estamos en modo de eliminación, eliminar el objeto en la posición tocada
			if is_deleting:
				# Usar una consulta de física para detectar qué objeto está en la posición tocada
				var space_state = get_world_2d().direct_space_state
				var query = PhysicsPointQueryParameters2D.new()
				query.position = posicion_mundo
				query.collision_mask = (1 << 0) | (1 << 1)  # Detectar layer 1 (físico) y layer 2 (selección)
				query.collide_with_bodies = true
				query.collide_with_areas = true
				var results = space_state.intersect_point(query)
				
				# Depuración: Imprimir los nodos detectados
				for result in results:
					if result.collider and is_instance_valid(result.collider):
						print("Detectado: ", result.collider.name, " Tipo: ", result.collider.get_class(), " Script: ", result.collider.get_script().resource_path if result.collider.get_script() else "Ninguno")
					else:
						print("Detectado: Nodo inválido o eliminado")

				if results.size() > 0:
					# Filtrar el collider más relevante
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
						# Calcular el tile correspondiente a la posición del objeto
						var tile_size = 250
						var tile_pos = Vector2(floor(collider.position.x / tile_size), floor(collider.position.y / tile_size))
						var tile_key = Vector2(tile_pos.x, tile_pos.y)
						
						# Manejar eliminación de teleportadores y sus puntos asociados
						if collider is Area2D and collider.get_script() and collider.get_script().resource_path == "res://teleportador.gd":
							# Eliminar el punto de teletransporte asociado
							if collider.teleport_target and is_instance_valid(collider.teleport_target):
								var punto_tile_pos = Vector2(floor(collider.teleport_target.position.x / tile_size), floor(collider.teleport_target.position.y / tile_size))
								var punto_tile_key = Vector2(punto_tile_pos.x, punto_tile_pos.y)
								if ocupados.has(punto_tile_key):
									ocupados.erase(punto_tile_key)
								collider.teleport_target.queue_free()
						# Manejar eliminación de puntos de teletransporte y su teleportador asociado
						elif collider is Area2D and collider.get_script() and collider.get_script().resource_path == "res://punto_teletransporte.gd":
							# Buscar el teleportador que usa este punto como destino
							for teleportador in get_tree().get_nodes_in_group("teleportadores"):
								if teleportador.teleport_target == collider:
									# Liberar el tile del teleportador
									var tele_tile_pos = Vector2(floor(teleportador.position.x / tile_size), floor(teleportador.position.y / tile_size))
									var tele_tile_key = Vector2(tele_tile_pos.x, tele_tile_pos.y)  # Corregido: Usar tele_tile_pos consistentemente
									if ocupados.has(tele_tile_key):
										ocupados.erase(tele_tile_key)
									# Eliminar el teleportador
									teleportador.queue_free()
									break
						
						# Si el objeto es una bola, eliminarla del diccionario y del grupo
						if collider is RigidBody2D and collider in bola_initial_positions:
							bola_initial_positions.erase(collider)
							collider.remove_from_group("bolas")
						
						# Liberar el tile en el diccionario ocupados
						if ocupados.has(tile_key):
							ocupados.erase(tile_key)
						
						# Eliminar el objeto de la escena
						collider.queue_free()
						
						# Limpiar ultimo_objeto_seleccionado si fue eliminado
						if ultimo_objeto_seleccionado == collider:
							ultimo_objeto_seleccionado = null
							$UI/Opciones/BotonLink.visible = false
							is_boton_link_visible = false
						
						# Forzar la actualización del PhysicsServer para liberar nodos eliminados
						PhysicsServer2D.set_active(true)
						await get_tree().create_timer(0.0).timeout  # Esperar un frame para asegurar la liberación
			
			elif seleccionando:
				var space_state = get_world_2d().direct_space_state
				var query = PhysicsPointQueryParameters2D.new()
				query.position = posicion_mundo
				query.collision_mask = (1 << 0) | (1 << 1)  # Detectar layer 1 (físico) y layer 2 (selección)
				query.collide_with_bodies = true
				query.collide_with_areas = true
				var results = space_state.intersect_point(query)
				
				# Depuración: Imprimir los nodos detectados
				for result in results:
					if result.collider and is_instance_valid(result.collider):
						print("Detectado: ", result.collider.name, " Tipo: ", result.collider.get_class(), " Script: ", result.collider.get_script().resource_path if result.collider.get_script() else "Ninguno")
					else:
						print("Detectado: Nodo inválido o eliminado")

				if results.size() > 0:
					# Filtrar el collider más relevante
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
						var sprite = collider.get_node_or_null("Sprite2D")
						if sprite and sprite.material:
							# Desactivar el resaltado del objeto anterior
							if ultimo_objeto_seleccionado and ultimo_objeto_seleccionado != collider and is_instance_valid(ultimo_objeto_seleccionado):
								var sprite_anterior = ultimo_objeto_seleccionado.get_node_or_null("Sprite2D")
								if sprite_anterior and sprite_anterior.material:
									sprite_anterior.material.set_shader_parameter("seleccionado", false)
							# Activar el resaltado del objeto actual
							sprite.material.set_shader_parameter("seleccionado", true)
							ultimo_objeto_seleccionado = collider
							
							# Mostrar u ocultar BotonLink según si es una bola
							if collider.get_script() and collider.get_script().resource_path == "res://bola.gd":
								$UI/Opciones/BotonLink.visible = true
								is_boton_link_visible = true
							else:
								$UI/Opciones/BotonLink.visible = false
								is_boton_link_visible = false
			
			# Modo normal: spawnear un objeto si las bolas están congeladas
			elif not seleccionando and not is_deleting:
				if not descongelado:
					# Convertir la posición del mundo a coordenadas de la cuadrícula
					var tile_size = 250
					var tile_pos = Vector2(floor(posicion_mundo.x / tile_size), floor(posicion_mundo.y / tile_size))
					# Verificar si el tile ya está ocupado
					var tile_key = Vector2(tile_pos.x, tile_pos.y)
					if not ocupados.has(tile_key):
						# Spawnear el objeto en la posición del tile
						var spawn_pos = tile_pos * tile_size + Vector2(tile_size / 2.0, tile_size / 2.0)
						if modo == "Bola":
							spawn_bola(spawn_pos)
						elif modo == "Piso":
							spawn_piso(spawn_pos)
						elif modo == "Cubo":
							spawn_cubo(spawn_pos)
						elif modo == "Teleportador":
							spawn_teleportador(spawn_pos)
						elif modo == "Esquina":
							spawn_esquina(spawn_pos)
						elif modo == "EsquinaRampa":
							spawn_esquinarampa(spawn_pos)
						# Marcar el tile como ocupado
						ocupados[tile_key] = true
					else:
						print("Este tile ya está ocupado!")

func _on_boton_link_pressed():
	""" Select single images from gallery """
	if plugin:
		plugin.getGalleryImage()
	else:
		print(plugin_name, " plugin not loaded!")
		
func _on_image_request_completed(dict):
	print("Image request completed. Dictionary received: ", dict)
	
	# Verificar si recibimos al menos una imagen
	if dict.values().size() > 0:
		var img_buffer = dict.values()[0]  # Tomar solo la primera imagen
		print("Image buffer size: ", img_buffer.size(), " bytes")

		# Crear una imagen y cargar el buffer
		var image = Image.new()
		var error = image.load_png_from_buffer(img_buffer)  # Intentar cargar como JPG
		if error != OK:
			_mover_abajo()
			print("Error loading PNG buffer: ", error)
			# Si falla PNG, intentar JPG
			error = image.load_jpg_from_buffer(img_buffer)
			if error != OK:
				print("Error loading JPG buffer: ", error)
				return
			else:
				print("Successfully loaded image as JPG")
		else:
			print("Successfully loaded image as PNG")
		
		var image_node = image_scene.instantiate()
		image_node.texture = ImageTexture.new().create_from_image(image)
		
		var sprite = ultimo_objeto_seleccionado.get_node_or_null("Sprite2D")
		sprite.texture = image_node.texture
		
		var texture_size = sprite.texture.get_size() if sprite.texture else Vector2(1, 1)
		# Calcular la escala para que la textura sea 250x250 píxeles
		var scale_x = 250.0 / texture_size.x
		var scale_y = 250.0 / texture_size.y
		
		
		var scale = min(scale_x, scale_y)
		sprite.scale = Vector2(scale, scale)
		
		print("Texture assigned to Sprite2D")
	else:
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
	
	# Set the plugin to ask user for permission again
	plugin.resendPermission()
	
		
func spawn_bola(pos):
	var bola = bola_scene.instantiate()
	bola.position = pos
	
	# Ajustar el Sprite2D a 250x250 píxeles
	var sprite = bola.get_node("Sprite2D")
	if sprite:
		sprite.material = material_base.duplicate()
		# Obtener el tamaño de la textura
		var texture_size = sprite.texture.get_size() if sprite.texture else Vector2(1, 1)
		# Calcular la escala para que la textura sea 250x250 píxeles
		var scale_x = 250.0 / texture_size.x
		var scale_y = 250.0 / texture_size.y
		# Usar la escala más pequeña para mantener proporciones (opcional)
		var scale = min(scale_x, scale_y)
		sprite.scale = Vector2(scale, scale)
	
	# Ajustar el CollisionShape2D a 250x250 píxeles
	var collision_shape = bola.get_node("CollisionShape2D")
	if collision_shape and collision_shape.shape is CircleShape2D:
		# Asegurarnos de que el CollisionShape2D no esté escalado
		collision_shape.scale = Vector2(1.0, 1.0)
		# Ajustar el radio para que el diámetro sea 250 píxeles (radio = 125)
		collision_shape.shape.radius = 125.0
	
	bola.add_to_group("bolas")
	bola_initial_positions[bola] = bola.global_transform.origin
	add_child(bola)
	# Aplicar la rotación guardada
	bola.rotation_degrees = ultimas_rotaciones["Bola"]
	if bola.rotation_degrees != 0.0:
		bola.saved_state.rotation = deg_to_rad(bola.rotation_degrees)
		bola.teleport(bola.position)

func spawn_piso(pos):
	var piso = piso_scene.instantiate()
	piso.position = pos
	var sprite = piso.get_node("Sprite2D")
	if sprite:
		sprite.material = material_base.duplicate()
	# Aplicar la rotación guardada
	piso.rotation_degrees = ultimas_rotaciones["Piso"]
	# Añadir metadato para identificar la escena
	piso.set_meta("scene_path", "res://Scenes/Piso.tscn")
	add_child(piso)

func spawn_cubo(pos):
	var cubo = cubo_scene.instantiate()
	cubo.position = pos
	var sprite = cubo.get_node("Sprite2D")
	if sprite:
		sprite.material = material_base.duplicate()
	add_child(cubo)
	# Aplicar la rotación guardada
	cubo.rotation_degrees = ultimas_rotaciones["Cubo"]
	# Configuración de colisión para cubos
	cubo.set_collision_layer_value(1, true)  # Layer 1 para detección en selección/eliminación
	cubo.set_collision_mask_value(1, true)   # Detectar bolas en layer 1

func spawn_teleportador(pos):
	var teleportador = teleportador_scene.instantiate()
	teleportador.position = pos
	teleportador.get_node("Sprite2D").scale = Vector2(1.0, 1.0)
	var sprite = teleportador.get_node("Sprite2D")
	if sprite:
		sprite.material = material_base.duplicate()
	var collision_shape = teleportador.get_node("CollisionShape2D")
	collision_shape.shape.radius = 125.0
	
	# Spawnear el punto de teletransporte en el tile de arriba
	var tile_size = 250
	var punto_pos = pos + Vector2(0, -tile_size)  # Tile de arriba (y disminuye)
	var punto = punto_teletransporte_scene.instantiate()
	punto.position = punto_pos
	var punto_sprite = punto.get_node("Sprite2D")
	if punto_sprite:
		punto_sprite.material = material_base.duplicate()
	
	# Asociar el punto al teleportador
	teleportador.teleport_target = punto
	
	teleportador.add_to_group("teleportadores")
	
	# Configuración de colisión para teleportadores
	teleportador.set_collision_layer_value(1, true)  # Layer 1 para detección en selección/eliminación
	teleportador.set_collision_mask_value(1, true)   # Detectar bolas en layer 1
	# Añadir el teleportador y el punto a la escena
	add_child(teleportador)
	add_child(punto)
	# Aplicar la rotación guardada al teleportador y su punto
	teleportador.rotation_degrees = ultimas_rotaciones["Teleportador"]
	punto.rotation_degrees = ultimas_rotaciones["PuntoTeletransporte"]
	
	# Marcar el tile del punto como ocupado
	var punto_tile_pos = Vector2(floor(punto_pos.x / tile_size), floor(punto_pos.y / tile_size))
	var punto_tile_key = Vector2(punto_tile_pos.x, punto_tile_pos.y)
	ocupados[punto_tile_key] = true

func spawn_esquina(pos):
	var esquina = esquina_scene.instantiate()
	esquina.position = pos
	var sprite = esquina.get_node("Sprite2D")
	if sprite:
		sprite.material = material_base.duplicate()
	# Aplicar la rotación guardada
	esquina.rotation_degrees = ultimas_rotaciones["Esquina"]
	# Añadir metadato para identificar la escena
	esquina.set_meta("scene_path", "res://Scenes/Esquina.tscn")
	add_child(esquina)

func spawn_esquinarampa(pos):
	var esquinarampa = esquinarampa_scene.instantiate()
	esquinarampa.position = pos
	var sprite = esquinarampa.get_node("Sprite2D")
	if sprite:
		sprite.material = material_base.duplicate()
	# Aplicar la rotación guardada
	esquinarampa.rotation_degrees = ultimas_rotaciones["EsquinaRampa"]
	# Añadir metadato para identificar la escena
	esquinarampa.set_meta("scene_path", "res://Scenes/EsquinaRampa.tscn")
	add_child(esquinarampa)
