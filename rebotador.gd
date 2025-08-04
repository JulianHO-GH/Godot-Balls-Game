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
