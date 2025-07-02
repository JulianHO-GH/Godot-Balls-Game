extends StaticBody2D

# Similar al piso, pero con animación
func _ready():
	$AnimatedSprite2D.play("default")  # Asegúrate de tener esta animación configurada
