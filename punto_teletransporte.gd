extends Area2D

func _ready():
	# Añadir Sprite2D para visualización
	if not has_node("Sprite2D"):
		var sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		sprite.texture = load("res://Texturas/punto_teletransporte.png")  # Ajusta la textura según tu proyecto
		sprite.scale = Vector2(0.5, 0.5)  # Escala para visibilidad
		add_child(sprite)
		sprite.owner = self
	
	
	
	# Configurar layer de colisión exclusivo para selección (por ejemplo, layer 2)
	set_collision_layer_value(1, false)  # Desactivar layer físico (bolas, etc.)
	set_collision_layer_value(2, true)   # Activar layer 2 para selección
	set_collision_mask_value(1, false)   # No detectar bolas u otros objetos
