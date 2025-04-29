extends Area2D

var is_deactivated: bool = false

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if body is RigidBody2D and not is_deactivated:  # Verifica si es una bola
		body.deactivate()  # Desactivar la bola en lugar de destruirla
