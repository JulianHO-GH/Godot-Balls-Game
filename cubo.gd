extends Area2D

var is_deactivated: bool = false

func _ready():
	connect("body_entered", _on_body_entered)
	

func _on_body_entered(body):
	var main = get_node("/root/Main") as Node2D
	if body is RigidBody2D and not is_deactivated:  # Verifica si es una bola
		
		if main and main.game_state and main.game_state.descongelado:#Solo desactivarla si el juego está descongelado
			body.deactivate()  # Desactivar la bola en lugar de destruirla
			
