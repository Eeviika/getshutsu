extends StaticBody2D

var damage = 1

func _ready():
	var timer = Timer.new()
	timer.wait_time = 5
	timer.autostart = true
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(func() -> void:
		queue_free()
	)

func _physics_process(_delta):
	var collision := move_and_collide(Vector2.RIGHT.rotated(rotation) * 15)
	if collision:
		var collider = collision.get_collider()
		if collider.has_method("damage"): collider.damage(damage);
		queue_free()
