extends CharacterBody2D

var health := 100

var accel = 150

func damage(damageAmount):
	health -= damageAmount

func _unhandled_input(_event):
	velocity = Vector2()
	if Input.is_action_pressed("_up"):
		velocity.y -= accel
	if Input.is_action_pressed("_down"):
		velocity.y += accel
	if Input.is_action_pressed("_left"):
		velocity.x -= accel
	if Input.is_action_pressed("_right"):
		velocity.x += accel
	if Input.is_action_just_pressed("_fire"):
		var bul: StaticBody2D = usapi.summonObject("playerBullet")
		bul.global_position = global_position
		bul.global_position += Vector2.RIGHT.rotated(rotation) * 32
		bul.rotation = rotation


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	look_at(get_global_mouse_position())
	move_and_slide()
