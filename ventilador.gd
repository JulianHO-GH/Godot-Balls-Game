extends StaticBody2D

@export var fuerza_viento: float = 1000.0
@export var mostrar_zona_viento: bool = false
@export var empuje_continuo: bool = true  # Fuerza constante vs. impulso

func _ready():
	$AnimatedSprite2D.play("default")
	
	
	# Conectar señales correctamente
	$Area2D.body_entered.connect(_on_viento_body_entered)
	$Area2D.body_exited.connect(_on_viento_body_exited)
	
	if empuje_continuo:
		$Area2D.body_shape_entered.connect(_on_viento_body_shape_entered)


func _on_viento_body_entered(body: Node):
	if body is RigidBody2D and not body.is_deactivated:
		if !empuje_continuo:
			aplicar_impulso_viento(body)

func _on_viento_body_exited(body: Node):
	if body.has_meta("en_viento"):
		body.remove_meta("en_viento")

func _on_viento_body_shape_entered(body_rid: RID, body: Node, body_shape_idx: int, area_shape_idx: int):
	if empuje_continuo and body is RigidBody2D and not body.is_deactivated:
		body.set_meta("en_viento", true)
		aplicar_fuerza_continua(body)

func aplicar_impulso_viento(body: RigidBody2D):
	var direccion = Vector2.RIGHT.rotated(global_rotation)
	body.apply_central_impulse(direccion * fuerza_viento * body.mass)

func aplicar_fuerza_continua(body: RigidBody2D):
	var direccion = Vector2.RIGHT.rotated(global_rotation)
	body.apply_central_force(direccion * fuerza_viento * body.mass)

func _physics_process(delta):
	if !empuje_continuo:
		return
		
	for body in $Area2D.get_overlapping_bodies():
		if body is RigidBody2D and not body.is_deactivated and body.has_meta("en_viento"):
			aplicar_fuerza_continua(body)
