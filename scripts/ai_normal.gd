extends CharacterBody2D

@onready var seeCast: RayCast2D = $playerSightCast
@onready var navAgent : NavigationAgent2D = $nav
@onready var pathfindTimer : Timer = Timer.new()
@onready var wanderTimer : Timer = Timer.new()
@onready var visibilityRange : Area2D = $visiblityRange
@export var phase: GlobalEnums.EnemyPhase = GlobalEnums.EnemyPhase.Wander

var pathfindTargetPos : Vector2 = Vector2(0,0)
var speed = 200
var health := 5
var max_health := 5

func damage(damageAmount):
    health -= damageAmount
    if health <= 0:
        queue_free()

func pathfind():
    navAgent.target_position = pathfindTargetPos
    nearPathfindTarget()
    if phase == GlobalEnums.EnemyPhase.Chase and pathfindTargetPos == Vector2(-1,-1) and checkIfFacingPlayerObject():
        print("finish chasing")
        phase = GlobalEnums.EnemyPhase.Wander
    if phase == GlobalEnums.EnemyPhase.Wander and pathfindTargetPos == Vector2(-1,-1):
        var target = usapi.getRandomTilePosOnTilemap([Vector2i(0,0), Vector2i(1,0)].pick_random())
        if !target: return;
        wanderTimer.start()
        pathfindTargetPos = target 

func _ready():
    pathfindTimer.wait_time = 0.1
    pathfindTimer.autostart = true
    pathfindTimer.one_shot = false
    pathfindTimer.timeout.connect(pathfind)
    wanderTimer.wait_time = 5.5
    wanderTimer.autostart = false
    wanderTimer.one_shot = true
    wanderTimer.timeout.connect(func()->void:
        if checkIfFacingPlayerObject(): return;
        pathfindTargetPos = Vector2(-1,-1)
    )
    add_child(pathfindTimer)
    add_child(wanderTimer)
    pathfindTargetPos = global_position

func nearPathfindTarget():
    if round(global_position.x + global_position.y) in [round(pathfindTargetPos.x + pathfindTargetPos.y), round(pathfindTargetPos.x + pathfindTargetPos.y)+1, round(pathfindTargetPos.x + pathfindTargetPos.y)-1, round(pathfindTargetPos.x + pathfindTargetPos.y)+2, round(pathfindTargetPos.x + pathfindTargetPos.y)-2]:
        pathfindTargetPos = Vector2(-1,-1)

func checkIfFacingPlayerObject() -> bool:
    for i in visibilityRange.get_overlapping_bodies():
        if !i.is_in_group("player"): continue;
        return true;
    return false;

func _process(_delta):
    seeCast.target_position = Vector2(0,0)
    for i in visibilityRange.get_overlapping_bodies():
        if !i.is_in_group("player"): continue;
        seeCast.target_position = to_local(i.global_position)
        if seeCast.get_collider() == i: pathfindTargetPos = i.global_position; phase = GlobalEnums.EnemyPhase.Chase;


func _physics_process(delta):
    if pathfindTargetPos == Vector2(-1, -1): return;
    var direction = Vector2.ZERO

    direction = navAgent.get_next_path_position() - global_position
    direction = direction.normalized()

    look_at(navAgent.get_next_path_position())

    velocity = velocity.lerp(direction*speed,10*delta)

    move_and_slide()


func _on_visiblity_range_body_entered(body:Node2D):
    if !body.is_in_group("player"): return;


func _on_visiblity_range_body_exited(body:Node2D):
    if !body.is_in_group("player"): return;
