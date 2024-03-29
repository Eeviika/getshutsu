extends CanvasLayer

@export var UITarget: Node2D 

@onready var healthBar: TextureProgressBar = $control/textureProgressBar

# Called when the node enters the scene tree for the first time.
func _ready():
    if not UITarget: queue_free(); return;
    await UITarget.ready
    if UITarget.get("max_health"):
        healthBar.max_value = UITarget.max_health
    if UITarget.has_signal("healthChanged"):
        healthBar.value = UITarget.health
        UITarget.healthChanged.connect(func(_prev, current):
            var tween := healthBar.create_tween()
            tween.tween_property(healthBar, "value", current, 0.5).set_ease(Tween.EASE_IN)
        )
        UITarget.damage(50)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
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
