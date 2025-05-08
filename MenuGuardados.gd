extends Control

@onready var item_list = $VBoxContainer/ItemList
@onready var button_load = $VBoxContainer/HBoxContainer/ButtonLoad
@onready var button_delete = $VBoxContainer/HBoxContainer/ButtonDelete
var game_state = preload("res://GameState.gd").new()

func _ready():
	# Crear directorio de guardados si no existe
	DirAccess.make_dir_recursive_absolute("user://saves/")
	
	# Listar archivos de guardado
	update_save_list()
	
	# Conectar señales de los botones
	$VBoxContainer/HBoxContainer/ButtonNew.pressed.connect(_on_new_pressed)
	$VBoxContainer/HBoxContainer/ButtonLoad.pressed.connect(_on_load_pressed)
	$VBoxContainer/HBoxContainer/ButtonDelete.pressed.connect(_on_delete_pressed)
	
	# Conectar señal de selección del ItemList
	item_list.item_selected.connect(_on_item_selected)
	
	# Desactivar botones hasta que se seleccione un elemento
	button_load.disabled = true
	button_delete.disabled = true

func update_save_list():
	item_list.clear()
	var dir = DirAccess.open("user://saves/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				item_list.add_item(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

func _on_item_selected(index: int):
	button_load.disabled = false
	button_delete.disabled = false

func _on_new_pressed():
	# Generar un nombre único para el nuevo guardado
	var save_number = 1
	var save_file = "save_%d.json" % save_number
	var dir = DirAccess.open("user://saves/")
	while dir.file_exists(save_file):
		save_number += 1
		save_file = "save_%d.json" % save_number
	
	# Establecer el nuevo archivo de guardado
	game_state.current_save_file = save_file
	# Cambiar a la escena principal
	get_tree().change_scene_to_file("res://main.tscn")

func _on_load_pressed():
	if item_list.is_anything_selected():
		var selected_index = item_list.get_selected_items()[0]
		var save_file = item_list.get_item_text(selected_index)
		game_state.current_save_file = save_file
		get_tree().change_scene_to_file("res://main.tscn")

func _on_delete_pressed():
	if item_list.is_anything_selected():
		var selected_index = item_list.get_selected_items()[0]
		var save_file = item_list.get_item_text(selected_index)
		var full_path = "user://saves/" + save_file
		if DirAccess.remove_absolute(full_path) == OK:
			print("Archivo eliminado: ", full_path)
			update_save_list()
			button_load.disabled = true
			button_delete.disabled = true
		else:
			print("Error al eliminar el archivo: ", full_path)
