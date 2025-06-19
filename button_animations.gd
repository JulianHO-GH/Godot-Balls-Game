extends Node
	
func buttonDown(path):
	var tween1 = create_tween()
	tween1.parallel().tween_property(path, "scale", Vector2(1.1, 1.1), 0.5)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_ELASTIC)
		
func buttonUp(path):
	var tween2 = create_tween()
	tween2.parallel().tween_property(path, "scale", Vector2(1.0, 1.0), 0.5)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_ELASTIC)
		
func popIn(path):
	# Crear tween para fade in (ease in)
	var tween = create_tween()
	tween.tween_property(path, "modulate:a", 1.0, 0.1)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_SINE)
	path.scale = Vector2(0.5, 0.5)
	tween.parallel().tween_property(path, "scale", Vector2(1.0, 1.0), 0.5)\
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
	
func popOut2(path):
	# Crear tween para fade out (ease out)
	var tween = create_tween()
	# En _on_ok_button_pressed (antes del fade out):
	tween.parallel().tween_property(path, "scale", Vector2(0.1, 0.1), 0.2)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(path, "modulate:a", 0.0, 0.2)
	
	# Ocultar el TextureRect después de completar la animación
	tween.tween_callback(func(): 
		path.visible = false
	)

func _on_boton_nuevo_button_down() -> void:
	buttonDown($/root/MenuGuardados/BotonNuevo)

func _on_boton_nuevo_button_up() -> void:
	buttonUp($/root/MenuGuardados/BotonNuevo)

func _on_boton_cargar_button_down() -> void:
	buttonDown($/root/MenuGuardados/BotonCargar)

func _on_boton_cargar_button_up() -> void:
	buttonUp($/root/MenuGuardados/BotonCargar)


func _on_aceptar_button_button_down() -> void:
	buttonDown($/root/MenuGuardados/PopUp/AceptarButton)


func _on_aceptar_button_button_up() -> void:
	buttonUp($/root/MenuGuardados/PopUp/AceptarButton)


func _on_cancelar_button_button_down() -> void:
	buttonDown($/root/MenuGuardados/PopUp/CancelarButton)


func _on_cancelar_button_button_up() -> void:
	buttonUp($/root/MenuGuardados/PopUp/CancelarButton)


func _on_boton_cargar_pressed() -> void:
	popIn($/root/MenuGuardados/PopUp)


func _on_cancelar_button_pressed() -> void:
	popOut($/root/MenuGuardados/PopUp)
	$/root/MenuGuardados/PopUp/AceptarButton.disabled = true
	$/root/MenuGuardados/PopUp/CancelarButton.disabled = true


func _on_nombre_aceptado_button_down() -> void:
	buttonDown($/root/MenuGuardados/PopUp2/NombreAceptado)


func _on_nombre_aceptado_button_up() -> void:
	buttonUp($/root/MenuGuardados/PopUp2/NombreAceptado)


func _on_nombre_cancelado_button_down() -> void:
	buttonDown($/root/MenuGuardados/PopUp2/NombreCancelado)


func _on_nombre_cancelado_button_up() -> void:
	buttonUp($/root/MenuGuardados/PopUp2/NombreCancelado)


	
func _on_nombre_cancelado_pressed() -> void:
	popOut2($/root/MenuGuardados/PopUp2)
	$/root/MenuGuardados/PopUp2.visible = false
	var tween3 = create_tween()
	tween3.tween_property($/root/MenuGuardados/FondoGris, "modulate:a", 0.0, 0.2)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.3).timeout
	$/root/MenuGuardados/FondoGris.visible = false
	


func _on_boton_nuevo_pressed() -> void:
	$/root/MenuGuardados/PopUp2.visible = true
	popIn($/root/MenuGuardados/PopUp2)
	$/root/MenuGuardados/FondoGris.visible = true
	var tween3 = create_tween()
	tween3.tween_property($/root/MenuGuardados/FondoGris, "modulate:a", 1.0, 0.2)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.3).timeout
	
