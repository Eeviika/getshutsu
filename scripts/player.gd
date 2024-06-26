extends "res://scripts/base_character.gd"

@onready var camera : Camera2D = $camera2d
@onready var bodySprite : AnimatedSprite2D = $sprites/body
@onready var flashlight : PointLight2D = $lights/flashLight

enum AnimationState{WalkNW, WalkW, WalkSW, WalkS, WalkSE, WalkE, WalkNE, WalkN}

enum Direction {NorthWest, West, SouthWest, South, SouthEast, East, NorthEast, North}

var currentAnimationState: AnimationState

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
        var bullet: StaticBody2D = usapi.objects.summonObject("playerBullet")
        # usapi.bindVisibilityToObject(self, bullet)
        bullet.global_position = global_position
        bullet.global_position += Vector2.RIGHT.rotated(rotation) * 32
        bullet.look_at(get_global_mouse_position())

func getMouseDirection(returnVectorInstead:bool=false):
    # Determine what direction we're looking in.
    # okay so future note to self
    # DO NOT ROUND EXPECTING IT TO BECOME A TYPE INT BECAUSE IT WONT HOLY SHIT I SPENT LIKE 3 DAYS SO FUCKING ANNOYED OVER THIS AAAAAAAAAAAAAAAA

    # Main 4 cardinal directions w/ dead zones
    if int(round(get_global_mouse_position().y)) <= int(round(global_position.y)) and range(global_position.x-100, global_position.x+75).has(int(round(get_global_mouse_position().x))):
        if returnVectorInstead: return Vector2( 0,-1)
        return Direction.North
    if int(round(get_global_mouse_position().y)) > int(round(global_position.y)) and range(global_position.x-100, global_position.x+ 75).has(int(round(get_global_mouse_position().x))):
        if returnVectorInstead: return Vector2( 0, 1)
        return Direction.South
    if int(round(get_global_mouse_position().x)) >= int(round(global_position.x)) and range(global_position.y-100, global_position.y+75).has(int(round(get_global_mouse_position().y))):
        if returnVectorInstead: return Vector2( 1, 0)
        return Direction.East
    if int(round(get_global_mouse_position().x)) < int(round(global_position.x)) and range(global_position.y-100, global_position.y+ 75).has(int(round(get_global_mouse_position().y))):
        if returnVectorInstead: return Vector2(-1, 0)
        return Direction.West
    
    # The other 4 cardinal directions
    if get_global_mouse_position().x >= global_position.x and get_global_mouse_position().y <= global_position.y:
        if returnVectorInstead: return Vector2( 1,-1)
        return Direction.NorthEast
    if get_global_mouse_position().x < global_position.x and get_global_mouse_position().y <= global_position.y:
        if returnVectorInstead: return Vector2(-1,-1)
        return Direction.NorthWest
    if get_global_mouse_position().x >= global_position.x and get_global_mouse_position().y > global_position.y:
        if returnVectorInstead: return Vector2( 1, 1)
        return Direction.SouthEast
    if get_global_mouse_position().x < global_position.x and get_global_mouse_position().y > global_position.y:
        if returnVectorInstead: return Vector2(-1, 1)
        return Direction.SouthWest
    return Direction.South
    

func animate():
    # Do body animation & check if we are moving (velocity is not (0,0))
    if velocity != Vector2(0,0):
        if bodySprite.animation != ("walk_" + str(getMouseDirection())): bodySprite.play("walk_" + str(getMouseDirection())) # Check if current anim is already playing (playing it anyways will cause visual glitchy thing)
    else: # We likely aren't moving then
        if bodySprite.animation != ("idle_" + str(getMouseDirection())): bodySprite.play("idle_" + str(getMouseDirection())) # Check if current anim is already playing (playing it anyways will cause visual glitchy thing)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta): 
    camera.offset = Vector2(0,0)
    camera.offset.x = clamp(-(global_position.x - get_global_mouse_position().x) * 0.05, -100, 100)
    camera.offset.y = clamp(-(global_position.y - get_global_mouse_position().y) * 0.05, -100, 100)
    flashlight.look_at( get_global_mouse_position() )
    animate()
    move_and_slide()
