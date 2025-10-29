extends Timer

var game_timer = self
@onready var timer_label = $Label
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Actualizar el Label con el tiempo restante del Timer
	if not game_timer.is_stopped():
		timer_label.visible = true
		var time_left = game_timer.time_left
		var minutes = int(time_left / 60)
		var seconds = int(time_left) % 60
		timer_label.text = str(seconds)
	else:
		timer_label.visible = false
