extends CharacterBody2D

@onready var seePlayerCast: RayCast2D = $playerSightCast
@onready var player : CharacterBody2D
@onready var navAgent : NavigationAgent2D = $nav
@onready var pathfindTimer : Timer = Timer.new()
@export var phase: GlobalEnums.EnemyPhase = GlobalEnums.EnemyPhase.Wander

var pathfindTargetPos : Vector2 = Vector2(0,0)
var speed = 200
var health = 5

func damage(damageAmount):
	health -= damageAmount
	if health <= 0:
		queue_free()

func _ready():
	pathfindTimer.wait_time = 0.1
	pathfindTimer.autostart = true
	pathfindTimer.one_shot = false
	add_child(pathfindTimer)
	pathfindTimer.timeout.connect(pathfind)
	player = get_node_or_null('%player')

func _process(_delta):
	pathfindTargetPos = get_global_mouse_position()
	seePlayerCast.target_position = to_local(player.global_position if player else Vector2(0,0))

func _physics_process(delta):
	var direction = Vector2.ZERO

	direction = navAgent.get_next_path_position() - global_position
	direction = direction.normalized()

	look_at(pathfindTargetPos)

	velocity = velocity.lerp(direction*speed,10*delta)

	move_and_slide()

func pathfind():
	navAgent.target_position = pathfindTargetPos