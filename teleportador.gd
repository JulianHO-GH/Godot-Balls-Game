extends Area2D

var teleport_target: Node2D = null  # Lo asignaremos desde "main"
var is_deactivated: bool = false

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if body is RigidBody2D and teleport_target and is_instance_valid(teleport_target) and not is_deactivated:
		# Llamar a la función de teletransporte en el cuerpo, pasando la posición global del destino
		if body.has_method("teleport"):
			body.teleport(teleport_target.global_position)
