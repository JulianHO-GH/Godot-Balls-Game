extends StaticBody2D

@export var fuerza_viento: float = 2000.0
@export var mostrar_zona_viento: bool = false

func _ready():
	$AnimatedSprite2D.play("default")
	
	
	# Conectar señales correctamente
	$Area2D.body_entered.connect(_on_viento_body_entered)
	$Area2D.body_exited.connect(_on_viento_body_exited)
	$Area2D.body_shape_entered.connect(_on_viento_body_shape_entered)


func _on_viento_body_entered(body: Node):
	print("on_viento_body_entered1")


func _on_viento_body_exited(body: Node):
	pass

func _on_viento_body_shape_entered(body_rid: RID, body: Node, body_shape_idx: int, area_shape_idx: int):
	if body is RigidBody2D and not body.is_deactivated:
		body.freeze = true
		
		print(body.linear_velocity)
		
	print("on_viento_body_shape_entered2")

func aplicar_fuerza_continua(body: RigidBody2D):
	var direccion = Vector2.RIGHT.rotated(global_rotation)
	body.apply_central_force(direccion * fuerza_viento * body.mass)

func _physics_process(delta):
	for body in $Area2D.get_overlapping_bodies():
		if body is RigidBody2D and not body.is_deactivated and not body.is_paused:
			body.freeze = false
			aplicar_fuerza_continua(body)
