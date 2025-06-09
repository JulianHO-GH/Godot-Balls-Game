extends Node
	
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
