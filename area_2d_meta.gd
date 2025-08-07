extends Area2D

signal bola_alcanzo_meta() # Señal emitida cuando una bola colisiona con la meta

func _ready():
	# Configurar capas de colisión
	set_collision_layer_value(1, false) # No necesita estar en la capa 1
	set_collision_layer_value(2, false) # No seleccionable
	set_collision_layer_value(3, true)  # Capa para elementos indestructibles (como la meta)
	set_collision_mask_value(1, true)   # Detecta bolas (capa 1)
	set_collision_mask_value(2, false)
	set_collision_mask_value(3, false)
	
	# Conectar la señal de colisión
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
	if body.is_in_group("bolas") and body is RigidBody2D and not body.is_deactivated:
		emit_signal("bola_alcanzo_meta")
