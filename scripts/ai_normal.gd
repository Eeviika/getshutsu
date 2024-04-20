extends "res://scripts/base_character.gd"

func _ready():
    health = maxHealth
    healthChanged.connect(func(_pv, cv):
        if cv <= 0:
            queue_free()
    )

func _process(delta):
    if !pathfinding.pathing:
        pathfindToPosition(usapi.getRandomTilePosOnTilemap(Vector2i(0,0)))

