extends CanvasLayer

@export var UITarget: CharacterBody2D 

@onready var healthBar: TextureProgressBar = $control/textureProgressBar

# Called when the node enters the scene tree for the first time.
func _ready():
    if not UITarget: queue_free()
    if UITarget.get("health"):
        var hp: int = UITarget.health
        


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    if !UITarget:
        healthBar.value = 0
        return;
    if UITarget.get("max_health"):
        healthBar.max_value = UITarget.max_health

func graduallyProgressVal(value, targetValue, maxStep):
    if value == targetValue:
        return value

    if abs(targetValue - value) <= maxStep:
        return targetValue

    var direction = sign(targetValue - value)
    return value + direction * maxStep

func graduallyDecreaseByPercentage(value, targetValue, percentage):
    var decreaseAmount = targetValue * (percentage / 100.0)
    if value <= targetValue + decreaseAmount:
        return targetValue
    else:
        return value - decreaseAmount