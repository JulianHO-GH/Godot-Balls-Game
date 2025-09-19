extends StaticBody2D

var is_deactivated: bool = false
@onready var spriteRebotador = $Sprite2D
@onready var timer = $Timer
@onready var first_exit: bool = true

func _ready():
	await get_tree().create_timer(0.1).timeout
	spriteRebotador.texture = load("res://Texturas/rebotador.png")

func _on_area_2d_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	spriteRebotador.texture = load("res://Texturas/rebotadorcontacted.png")
	
	_animacion_rebotar(self.spriteRebotador)
	_play_boing_sound()

func _on_area_2d_body_shape_exited(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	timer.stop()
	timer.start()

func _on_timer_timeout() -> void:
	spriteRebotador.texture = load("res://Texturas/rebotador.png")
			
func _animacion_rebotar(path) -> void:
	print("animacion")
	var tween1 = create_tween()
	tween1.parallel().tween_property(path, "scale", Vector2(1.1, 1.1), 0.2)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK)
	await get_tree().create_timer(0.2).timeout
	var tween2 = create_tween()
	tween2.parallel().tween_property(path, "scale", Vector2(1.0, 1.0), 0.2)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BOUNCE)
		
func _play_boing_sound() -> void:
	# Obtener la cámara desde la escena principal
	var camera = get_node_or_null("/root/Main/Camera2D")
	if not camera:
		print("Error: No se encontró la cámara en /root/Main/Camera2D")
		return

	# Obtener la posición global del rebotador
	var rebotador_pos = global_position

	# Obtener el área visible de la cámara
	var viewport_size = get_viewport_rect().size
	var camera_zoom = camera.zoom
	var camera_pos = camera.global_position
	var camera_half_size = (viewport_size / camera_zoom) / 2.0

	# Definir un margen adicional para "cerca" (por ejemplo, 100 píxeles)
	var margin = 100.0
	var camera_rect = Rect2(
		camera_pos - camera_half_size - Vector2(margin, margin),
		viewport_size / camera_zoom + Vector2(margin * 2, margin * 2)
	)

	# Verificar si el rebotador está dentro o cerca del área visible
	if camera_rect.has_point(rebotador_pos):
		# Reproducir el sonido
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = load("res://sounds/Boing.wav")
		audio_player.volume_db = -3  # Ajusta el volumen si es necesario
		audio_player.pitch_scale = 1.0  # Ajusta el tono si es necesario
		add_child(audio_player)
		audio_player.play()
		audio_player.finished.connect(func():
			audio_player.queue_free()
		)
	else:
		print("Rebotador fuera de la cámara, sonido no reproducido")
