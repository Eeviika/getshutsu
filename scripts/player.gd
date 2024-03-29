extends "res://scripts/base_character.gd"

# Weaponized Artificial Life Leech

func _unhandled_input(_event):
    velocity = Vector2()
    if Input.is_action_pressed("_up"):
        velocity.y -= speed
    if Input.is_action_pressed("_down"):
        velocity.y += speed
    if Input.is_action_pressed("_left"):
        velocity.x -= speed
    if Input.is_action_pressed("_right"):
        velocity.x += speed
    if Input.is_action_just_pressed("_fire"):
        var bullet: StaticBody2D = usapi.summonObject("playerBullet")
        # usapi.bindVisibilityToObject(self, bullet)
        bullet.global_position = global_position
        bullet.global_position += Vector2.RIGHT.rotated(rotation) * 32
        bullet.rotation = rotation
        


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
    look_at(get_global_mouse_position())
    move_and_slide()
