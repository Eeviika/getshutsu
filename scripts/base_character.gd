extends CharacterBody2D

# Signals

## Fires every time health is updated.
signal healthChanged(previousValue: int, currentValue: int)

## Fires whenever navAgent begins moving towards its target.
signal startPathfinding(targetPosition: Vector2)

## Fires whenever navAgent reached its target.
signal completedPathfinding(currentPosition: Vector2)

# Export variables

## Amount of damage that is nullified. Equation for calculating damage is as follows:[br][br][code]clampi( damage - ceili( defense * 0.2 ), 0, 2008 )[/code]
@export var defense: int = 0

## Maximum amount of health this Character can have.
@export var maxHealth : int = 100

## Whether pathfinding is enabled or not. Enabling this will enable processing for the navAgent node.
@export var enablePathfinding: bool = false

@export var speed: int = 150

# Onready variables

@onready var navigationAgent: NavigationAgent2D = $NavAgent

# Normal variables

var health = maxHealth:
    set(value):
        healthChanged.emit(health, value)
        health = value

var pathfinding := {
    "pathing" = false,
    "targetPosition" = Vector2(),
}

# Functions

## Damages the Character.[br]Note that no changes will be made to [code]health[/code] if it is already 0.
func damage(amount: int) -> void:
    health -= clampi(amount - ceili(defense * 0.2), 1, 2008)

## Pathfinds to the given target position. Returns [code]OK[/code] if success.[br]Will return [code]ERR_UNCONFIGURED[/code] if pathfinding is disabled for this character.[br]Will return [code]ERR_ALREADY_EXISTS[/code] if we are already going to that position.
func pathfindToPosition(targetPosition: Vector2):
    if !enablePathfinding: usapi.doLog("Cannot pathfind; pathfinding not enabled for Node " + name, usapi.LogLevels.Fatal); return ERR_UNCONFIGURED;
    if pathfinding.targetPosition == targetPosition: usapi.doLog("Cannot pathfind; pathfinding to same target for Node " + name, usapi.LogLevels.Log); return ERR_ALREADY_EXISTS;
    if navigationAgent.process_mode == Node.PROCESS_MODE_DISABLED: navigationAgent.process_mode = Node.PROCESS_MODE_INHERIT
    navigationAgent.target_position = targetPosition
    pathfinding.targetPosition = targetPosition
    pathfinding.pathing = true
    startPathfinding.emit(targetPosition)
    return OK

## Updates the path to the target position. Returns [code]OK[/code] if success.[br]Will return [code]ERR_UNCONFIGURED[/code] if pathfinding is disabled for this character.[br]Will return [code]ERR_DOES_NOT_EXIST[/code] if we are no longer pathing.
func updatePath():
    if !enablePathfinding: usapi.doLog("Cannot update path; pathfinding not enabled for Node " + name, usapi.LogLevels.Warn); return ERR_UNCONFIGURED;
    if !pathfinding.pathing: return ERR_DOES_NOT_EXIST;
    navigationAgent.target_position = pathfinding.targetPosition
    return OK

## Moves towards the target using the current path.[br]This will not update the path. You must use [code]base_character.updatePath()[/code] for that.
func moveTowardsTarget(delta):
    if !enablePathfinding: usapi.doLog("Cannot move towards path target; pathfinding not enabled for Node " + name, usapi.LogLevels.Warn); return ERR_UNCONFIGURED;
    if !pathfinding.pathing: return ERR_DOES_NOT_EXIST;
    if round(global_position.x) == pathfinding.targetPosition.x and round(global_position.y) == pathfinding.targetPosition.y:
        print("We reached the target position, so not continuing.");
        pathfinding.pathing = false
        global_position = pathfinding.targetPosition
        completedPathfinding.emit(global_position)
        velocity = Vector2(0,0)
        return;
    var direction = (navigationAgent.get_next_path_position() - global_position).normalized()
    velocity = velocity.lerp(direction*speed,10*delta)
    return OK