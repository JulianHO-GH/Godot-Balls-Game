extends RefCounted
class_name GameState

# Diccionarios para datos del juego
var ocupados: Dictionary = {}  # Tiles ocupados: Vector2 -> bool

var teleport_lines: Dictionary = {}  # ID de teleportador -> Line2D
var bola_initial_positions: Dictionary = {}  # ID de bola -> Vector2
var ultimas_rotaciones: Dictionary = {
	"Bola": 0.0,
	"Piso": 0.0,
	"Cubo": 0.0,
	"Teleportador": 0.0,
	"Esquina": 0.0,
	"EsquinaRampa": 0.0,
	"PuntoTeletransporte": 0.0,
	"Ventilador": 0.0
}

# Lista de objetos instanciados
var objects: Array = []  # Array de diccionarios con propiedades de cada objeto

# Estados del juego
var modo: String = "Bola"
var descongelado: bool = false
var seleccionando: bool = false
var is_deleting: bool = false
var menu_moved_up: bool = false
var menu_moved_right: bool = false
var is_boton_link_visible: bool = false


# Configuraciones de la cámara
var camera_position: Vector2 = Vector2.ZERO
var camera_zoom: Vector2 = Vector2(1.0, 1.0)

# Configuraciones de la UI
var ui_menu_position: Vector2 = Vector2.ZERO
var ui_options_position: Vector2 = Vector2.ZERO
var ui_boton_reiniciar_position: Vector2 = Vector2.ZERO
var ui_boton_descongelar_position: Vector2 = Vector2.ZERO
var ui_botones_mover_position: Vector2 = Vector2.ZERO

# Contador para generar IDs únicos
var _id_counter: int = 0

# Directorio para guardar imágenes
const IMAGE_DIR: String = "user://images/"

func _init():
	# Crear el directorio para imágenes si no existe
	DirAccess.make_dir_recursive_absolute(IMAGE_DIR)

# Generar un ID único para un objeto
func generate_id() -> String:
	_id_counter += 1
	return str(_id_counter)

# Añadir un objeto al estado
# En la función add_object, añade el parámetro has_outline (por defecto true)
func add_object(scene_path: String, position: Vector2, rotation_degrees: float, 
			   texture_path: String = "", extra_data: Dictionary = {}, 
			   has_outline: bool = true) -> String:
	var id = generate_id()
	var obj_data = {
		"id": id,
		"scene_path": scene_path,
		"position": position,
		"rotation_degrees": rotation_degrees,
		"texture_path": texture_path,
		"color": Color.WHITE,
		"extra_data": extra_data,
		"has_outline": has_outline  # Nuevo campo
	}
	objects.append(obj_data)
	return id

# Añade esta función para actualizar el estado del outline
func update_object_outline(obj_id: String, has_outline: bool):
	for obj in objects:
		if obj.id == obj_id:
			obj.has_outline = has_outline
			break

func update_object_color(obj_id: String, color: Color) -> void:
	for obj in objects:
		if obj.id == obj_id:
			obj.color = color
			break
			

# Actualizar la posición de un objeto
func update_object_position(id: String, position: Vector2):
	for obj in objects:
		if obj.id == id:
			obj.position = position
			break

# Actualizar la rotación de un objeto
func update_object_rotation(id: String, rotation_degrees: float):
	for obj in objects:
		if obj.id == id:
			obj.rotation_degrees = rotation_degrees
			break

# Actualizar la textura de un objeto
func update_object_texture(id: String, texture_path: String):
	for obj in objects:
		if obj.id == id:
			obj.texture_path = texture_path
			break

# Eliminar un objeto
func remove_object(id: String):
	for i in range(objects.size() - 1, -1, -1):
		if objects[i].id == id:
			objects.remove_at(i)
			break

# Obtener un objeto por ID
func get_object(id: String) -> Dictionary:
	for obj in objects:
		if obj.id == id:
			return obj
	return {}

# Guardar una imagen y devolver su ruta
func save_image(image: Image, obj_id: String) -> String:
	var path = IMAGE_DIR + "image_" + obj_id + ".png"
	image.save_png(path)
	return path

# Cargar una imagen desde una ruta
func load_image(path: String) -> Image:
	var image = Image.new()
	var error = image.load(path)
	if error == OK:
		var texture = ImageTexture.new() #Genera una copia nueva
		texture.set_image(image)
		return texture
	return null

# Métodos para gestionar tiles ocupados
func set_tile_occupied(tile_pos: Vector2, occupied: bool):
	if occupied:
		ocupados[tile_pos] = true
	else:
		ocupados.erase(tile_pos)

func is_tile_occupied(tile_pos: Vector2) -> bool:
	return ocupados.has(tile_pos)

# Métodos para gestionar posiciones iniciales de bolas
func set_bola_initial_position(bola_id: String, position: Vector2):
	bola_initial_positions[bola_id] = position

func get_bola_initial_position(bola_id: String) -> Vector2:
	return bola_initial_positions.get(bola_id, Vector2.ZERO)

func remove_bola_initial_position(bola_id: String):
	bola_initial_positions.erase(bola_id)

# Métodos para gestionar rotaciones
func set_rotation(tipo: String, rotation_degrees: float):
	ultimas_rotaciones[tipo] = rotation_degrees

func get_rotation(tipo: String) -> float:
	return ultimas_rotaciones.get(tipo, 0.0)

# Serializar el estado a un diccionario (para guardar en JSON)
func to_dict() -> Dictionary:
	return {
		"ocupados": ocupados,
		"bola_initial_positions": bola_initial_positions,
		"ultimas_rotaciones": ultimas_rotaciones,
		"objects": objects,
		"modo": modo,
		"descongelado": descongelado,
		"seleccionando": seleccionando,
		"is_deleting": is_deleting,
		"menu_moved_up": menu_moved_up,
		"menu_moved_right": menu_moved_right,
		"is_boton_link_visible": is_boton_link_visible,
		"camera_position": [camera_position.x, camera_position.y],
		"camera_zoom": [camera_zoom.x, camera_zoom.y],
		"ui_menu_position": [ui_menu_position.x, ui_menu_position.y],
		"ui_options_position": [ui_options_position.x, ui_options_position.y],
		"ui_boton_reiniciar_position": [ui_boton_reiniciar_position.x, ui_boton_reiniciar_position.y],
		"ui_boton_descongelar_position": [ui_boton_descongelar_position.x, ui_boton_descongelar_position.y],
		"ui_botones_mover_position": [ui_botones_mover_position.x, ui_botones_mover_position.y]
	}

# Deserializar el estado desde un diccionario (para cargar desde JSON)
func from_dict(data: Dictionary):
	ocupados = data.get("ocupados", {})
	bola_initial_positions = data.get("bola_initial_positions", {})
	ultimas_rotaciones = data.get("ultimas_rotaciones", ultimas_rotaciones)
	objects = data.get("objects", [])
	modo = data.get("modo", "Bola")
	descongelado = data.get("descongelado", false)
	seleccionando = data.get("seleccionando", false)
	is_deleting = data.get("is_deleting", false)
	menu_moved_up = data.get("menu_moved_up", false)
	menu_moved_right = data.get("menu_moved_right", false)
	is_boton_link_visible = data.get("is_boton_link_visible", false)
	camera_position = Vector2(data.get("camera_position", [0, 0])[0], data.get("camera_position", [0, 0])[1])
	camera_zoom = Vector2(data.get("camera_zoom", [1, 1])[0], data.get("camera_zoom", [1, 1])[1])
	ui_menu_position = Vector2(data.get("ui_menu_position", [0, 0])[0], data.get("ui_menu_position", [0, 0])[1])
	ui_options_position = Vector2(data.get("ui_options_position", [0, 0])[0], data.get("ui_options_position", [0, 0])[1])
	ui_boton_reiniciar_position = Vector2(data.get("ui_boton_reiniciar_position", [0, 0])[0], data.get("ui_boton_reiniciar_position", [0, 0])[1])
	ui_boton_descongelar_position = Vector2(data.get("ui_boton_descongelar_position", [0, 0])[0], data.get("ui_boton_descongelar_position", [0, 0])[1])
	ui_botones_mover_position = Vector2(data.get("ui_botones_mover_position", [0, 0])[0], data.get("ui_botones_mover_position", [0, 0])[1])
