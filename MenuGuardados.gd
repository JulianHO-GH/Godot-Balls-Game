extends Control

# Referencias a los nodos
@onready var boton_nuevo = $BotonNuevo
@onready var boton_cargar = $BotonCargar
@onready var item_list = $PopUp/ItemList
@onready var popup = $PopUp
@onready var aceptarButton = $PopUp/AceptarButton
@onready var cancelarButton = $PopUp/CancelarButton

# Directorio para archivos de guardado
const SAVE_DIR = "user://saved_levels/"

# Escena principal del juego
const MAIN_SCENE = "res://main.tscn"

func _ready():
	# Crear el directorio de guardado si no existe
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	print("Directorio ", SAVE_DIR, " creado o ya existe")

	# Conectar señales de los botones
	boton_cargar.pressed.connect(_on_boton_cargar_pressed)
	
	 # Conectar el botón OK (asegúrate de que esto esté después de cargar la escena)
	$NoSaveFilesAlert/OkButton.pressed.connect(_on_ok_button_pressed)
	
	# Inicialmente ocultar el alerta
	$NoSaveFilesAlert.visible = false



func _on_boton_cargar_pressed():
	var save_files = _get_save_files()
	if save_files.is_empty():
		# Configurar transparencia inicial (0 = invisible)
		$NoSaveFilesAlert.modulate.a = 0
		$NoSaveFilesAlert.visible = true
		$NoSaveFilesAlert/OkButton.disabled = false
		
		# Crear tween para fade in (ease in)
		var tween = create_tween()
		tween.tween_property($NoSaveFilesAlert, "modulate:a", 1.0, 0.1)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_SINE)
		$NoSaveFilesAlert.scale = Vector2(0.5, 0.5)
		tween.parallel().tween_property($NoSaveFilesAlert, "scale", Vector2(1.0, 1.0), 0.5)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_ELASTIC)
	else:
		item_list.clear()
		for file in save_files:
			# Remover la extensión .json antes de añadirlo al ItemList
			var display_name = file.replace(".json", "")
			item_list.add_item(display_name)
		popup.visible = true
		aceptarButton.disabled = false
		cancelarButton.disabled = false

func _on_ok_button_pressed():
	# Deshabilitar el botón inmediatamente para evitar múltiples clics
	$NoSaveFilesAlert/OkButton.disabled = true
	
	# Crear tween para fade out (ease out)
	var tween = create_tween()
	# En _on_ok_button_pressed (antes del fade out):
	tween.parallel().tween_property($NoSaveFilesAlert, "scale", Vector2(0.1, 0.1), 0.1)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property($NoSaveFilesAlert, "modulate:a", 0.0, 0.1)
	
	# Ocultar el TextureRect después de completar la animación
	tween.tween_callback(func(): 
		$NoSaveFilesAlert.visible = false
	)
	
func _get_save_files() -> Array:
	# Obtener la lista de archivos de guardado en SAVE_DIR
	var files = []
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	return files


func _on_aceptar_button_pressed() -> void:
	# Conectar la señal de confirmación
	var save_files = _get_save_files()
	var selected_items = item_list.get_selected_items()
	if selected_items.size() > 0:
		var selected_file = save_files[selected_items[0]]
		# Pasar el nombre del archivo seleccionado a la escena main
		var scene_tree = get_tree()
		var packed_scene = load(MAIN_SCENE)
		var main_instance = packed_scene.instantiate()
		main_instance.set("selected_save_file", selected_file)
		scene_tree.root.add_child(main_instance)
		scene_tree.current_scene = main_instance
		queue_free()


func _on_nombre_aceptado_pressed() -> void:
	var NombreInput = $/root/MenuGuardados/PopUp2/InputNombre
	var nombre_nivel = NombreInput.text.strip_edges()
	
	# Validar nombre
	if nombre_nivel.is_empty():
		nombre_nivel = "NoN"
	# Limpiar caracteres no válidos
	nombre_nivel = nombre_nivel.replace("/", "").replace("\\", "").replace(":", "").replace("*", "")\
				   .replace("?", "").replace("\"", "").replace("<", "").replace(">", "").replace("|", "")
	
	var level_file_path = SAVE_DIR + nombre_nivel + ".json"
	
	# Verificar si ya existe
	if FileAccess.file_exists(level_file_path):
		# Mostrar mensaje de error (puedes implementar esto similar al NoSaveFilesAlert)
		print("Ya existe un nivel con ese nombre")

		return
	
	# Crear archivo
	var level_file = FileAccess.open(level_file_path, FileAccess.WRITE)
	if level_file:
		level_file.store_string(JSON.stringify([], "  ", false))
		level_file.close()
		
		# Cambiar a la escena principal
		var scene_tree = get_tree()
		var packed_scene = load(MAIN_SCENE)
		var main_instance = packed_scene.instantiate()
		main_instance.set("selected_save_file", nombre_nivel + ".json")
		scene_tree.root.add_child(main_instance)
		scene_tree.current_scene = main_instance
		queue_free()
	else:
		print("Error al crear el archivo")
	
