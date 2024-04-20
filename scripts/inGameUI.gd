extends CanvasLayer

@export var UITarget: Node2D 

@onready var healthBar: TextureProgressBar = $control/textureProgressBar

# Called when the node enters the scene tree for the first time.
func _ready():
    if not UITarget: queue_free(); return;
    await UITarget.ready
    if UITarget.get("maxHealth"):
        healthBar.max_value = UITarget.maxHealth
    if UITarget.has_signal("healthChanged"):
        healthBar.value = UITarget.health
        UITarget.healthChanged.connect(func(_prev, current):
            healthBar.value = current
        )


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
    if !UITarget:
        healthBar.value = 0
        return;


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
