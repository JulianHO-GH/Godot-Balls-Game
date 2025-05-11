extends Control

# Referencias a los nodos
@onready var boton_nuevo = $BotonNuevo
@onready var boton_cargar = $BotonCargar

# Directorio para archivos de guardado
const SAVE_DIR = "user://saved_levels/"

# Escena principal del juego
const MAIN_SCENE = "res://main.tscn"

func _ready():
	# Crear el directorio de guardado si no existe
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	print("Directorio ", SAVE_DIR, " creado o ya existe")

	# Conectar señales de los botones
	boton_nuevo.pressed.connect(_on_boton_nuevo_pressed)
	boton_cargar.pressed.connect(_on_boton_cargar_pressed)

func _on_boton_nuevo_pressed():
	# Generar un nombre único para el nuevo archivo de guardado
	var save_index = 1
	var level_file_path = SAVE_DIR + "saved_level_" + str(save_index) + ".json"
	while FileAccess.file_exists(level_file_path):
		save_index += 1
		level_file_path = SAVE_DIR + "saved_level_" + str(save_index) + ".json"
	
	# Crear un archivo de guardado vacío
	var level_file = FileAccess.open(level_file_path, FileAccess.WRITE)
	if level_file:
		level_file.store_string(JSON.stringify([], "  ", false))  # Guardar un array vacío
		level_file.close()
		print("Nuevo archivo de guardado creado: ", level_file_path)
	else:
		print("Error al crear el archivo: ", level_file_path)
		return
	
	# Cambiar a main.tscn y pasar el nombre del archivo
	var scene_tree = get_tree()
	var packed_scene = load(MAIN_SCENE)
	var main_instance = packed_scene.instantiate()
	main_instance.set("selected_save_file", "saved_level_" + str(save_index) + ".json")
	scene_tree.root.add_child(main_instance)
	scene_tree.current_scene = main_instance
	queue_free()

func _on_boton_cargar_pressed():
	# Mostrar un menú con los archivos de guardado disponibles
	var save_files = _get_save_files()
	if save_files.is_empty():
		# Mostrar un mensaje si no hay archivos de guardado
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "No hay archivos de guardado disponibles."
		dialog.ok_button_text = "Aceptar"
		add_child(dialog)
		dialog.popup_centered()
		return

	# Crear un diálogo para seleccionar el archivo
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Selecciona un archivo de guardado:"
	var item_list = ItemList.new()
	for file in save_files:
		item_list.add_item(file)
	dialog.add_child(item_list)
	
	# Conectar la señal de confirmación
	dialog.confirmed.connect(func():
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
	)
	
	# Mostrar el diálogo
	add_child(dialog)
	dialog.popup_centered(Vector2i(400, 300))

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
