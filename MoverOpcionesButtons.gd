extends Control

func buttonDown(path):
	var tween1 = create_tween()
	#path.scale = Vector2(0.5, 0.5)
	tween1.parallel().tween_property(path, "scale", Vector2(1.1, 1.1), 0.5)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_ELASTIC)
		
func buttonUp(path):
	var tween2 = create_tween()
	#path.scale = Vector2(0.5, 0.5)
	tween2.parallel().tween_property(path, "scale", Vector2(1.0, 1.0), 0.5)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_ELASTIC)
		
func popIn(path):
	# Crear tween para fade in (ease in)
	var tween = create_tween()
	path.visible = true
	tween.tween_property(path, "modulate:a", 1.0, 0.1)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_SINE)
	path.scale = Vector2(0.5, 0.5)
	tween.parallel().tween_property(path, "scale", Vector2(1.0, 1.0), 0.5)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_ELASTIC)
		
func popInDoubleSize(path):
	# Crear tween para fade in (ease in)
	var tween = create_tween()
	path.visible = true
	tween.tween_property(path, "modulate:a", 1.0, 0.1)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_SINE)
	path.scale = Vector2(1.0, 1.0)
	tween.parallel().tween_property(path, "scale", Vector2(2.0, 2.0), 0.5)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_ELASTIC)
		
func popOut(path):
	# Crear tween para fade out (ease out)
	var tween = create_tween()
	# En _on_ok_button_pressed (antes del fade out):
	tween.parallel().tween_property(path, "scale", Vector2(0.1, 0.1), 0.1)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(path, "modulate:a", 0.0, 0.1)
	
	# Ocultar el TextureRect después de completar la animación
	tween.tween_callback(func(): 
		path.visible = false
	)
	
			
func _on_boton_zoom_in_button_down() -> void:
	buttonDown($BotonZoomIn)


func _on_boton_zoom_in_button_up() -> void:
	buttonUp($BotonZoomIn)


func _on_boton_zoom_out_button_down() -> void:
	buttonDown($BotonZoomOut)


func _on_boton_zoom_out_button_up() -> void:
	buttonUp($BotonZoomOut)


func _on_boton_descongelar_button_down() -> void:
	buttonDown($BotonDescongelar)


func _on_boton_descongelar_button_up() -> void:
	buttonUp($BotonDescongelar)


func _on_boton_reiniciar_button_down() -> void:
	buttonDown($BotonReiniciar)


func _on_boton_reiniciar_button_up() -> void:
	buttonUp($BotonReiniciar)


func _on_boton_eliminar_button_down() -> void:
	buttonDown($BotonEliminar)


func _on_boton_eliminar_button_up() -> void:
	buttonUp($BotonEliminar)


func _on_boton_select_button_down() -> void:
	buttonDown($BotonSelect)


func _on_boton_select_button_up() -> void:
	buttonUp($BotonSelect)


func _on_button_save_button_down() -> void:
	buttonDown($ButtonSave)


func _on_button_save_button_up() -> void:
	buttonUp($ButtonSave)


func _on_button_load_button_down() -> void:
	buttonDown($ButtonLoad)


func _on_button_load_button_up() -> void:
	buttonUp($ButtonLoad)


func _on_boton_link_button_down() -> void:
	buttonDown($BotonLink)


func _on_boton_link_button_up() -> void:
	buttonUp($BotonLink)


func _on_boton_rotar_derecha_button_down() -> void:
	buttonDown($/root/Main/UI/Mover/BotonRotarDerecha)


func _on_boton_rotar_derecha_button_up() -> void:
	buttonUp($/root/Main/UI/Mover/BotonRotarDerecha)


func _on_boton_rotar_izquierda_button_down() -> void:
	buttonDown($/root/Main/UI/Mover/BotonRotarIzquierda)


func _on_boton_rotar_izquierda_button_up() -> void:
	buttonUp($/root/Main/UI/Mover/BotonRotarIzquierda)


func _on_boton_derecha_button_down() -> void:
	buttonDown($/root/Main/UI/Mover/BotonDerecha)


func _on_boton_derecha_button_up() -> void:
	buttonUp($/root/Main/UI/Mover/BotonDerecha)


func _on_boton_abajo_button_down() -> void:
	buttonDown($/root/Main/UI/Mover/BotonAbajo)


func _on_boton_abajo_button_up() -> void:
	buttonUp($/root/Main/UI/Mover/BotonAbajo)


func _on_boton_arriba_button_down() -> void:
	buttonDown($/root/Main/UI/Mover/BotonArriba)


func _on_boton_arriba_button_up() -> void:
	buttonUp($/root/Main/UI/Mover/BotonArriba)


func _on_boton_izquierda_button_down() -> void:
	buttonDown($/root/Main/UI/Mover/BotonIzquierda)


func _on_boton_izquierda_button_up() -> void:
	buttonUp($/root/Main/UI/Mover/BotonIzquierda)


func _on_ok_button_pressed() -> void:
	popOut($/root/Main/Camera2D/MaxLayer/MaxSizeAlert)
	$/root/Main/Camera2D/MaxLayer/MaxSizeAlert/OkButton.disabled = true


func _on_ok_button_button_up() -> void:
	buttonUp($/root/Main/Camera2D/MaxLayer/MaxSizeAlert/OkButton)


func _on_ok_button_button_down() -> void:
	buttonDown($/root/Main/Camera2D/MaxLayer/MaxSizeAlert/OkButton)

func _on_maxsize_detected() -> void:
	popIn($/root/Main/Camera2D/MaxLayer/MaxSizeAlert)
	$/root/Main/Camera2D/MaxLayer/MaxSizeAlert/OkButton.disabled = false


func _on_ok_button_2_pressed() -> void:
	popOut($/root/Main/Camera2D/MinLayer/MinSizeAlert)
	$/root/Main/Camera2D/MinLayer/MinSizeAlert/OkButton2.disabled = true


func _on_ok_button_2_button_up() -> void:
	buttonUp($/root/Main/Camera2D/MinLayer/MinSizeAlert/OkButton2)


func _on_ok_button_2_button_down() -> void:
	buttonDown($/root/Main/Camera2D/MinLayer/MinSizeAlert/OkButton2)

func _on_minsize_detected() -> void:
	popIn($/root/Main/Camera2D/MinLayer/MinSizeAlert)
	$/root/Main/Camera2D/MinLayer/MinSizeAlert/OkButton2.disabled = false


func _on_button_color_button_down() -> void:
	buttonDown($/root/Main/UI/Opciones/ButtonColor)


func _on_button_color_button_up() -> void:
	buttonUp($/root/Main/UI/Opciones/ButtonColor)


func _on_texture_button_button_down() -> void:
	buttonDown($/root/Main/CanvasColor/TextureButton)


func _on_texture_button_button_up() -> void:
	buttonUp($/root/Main/CanvasColor/TextureButton)
