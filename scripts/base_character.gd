extends CharacterBody2D

signal healthChanged(previousValue, currentValue)

@export var max_health := 5

@export var health = max_health : 
    set(value):
        if value == 0: return;
        healthChanged.emit(health, value)
        health = value

@export var defense = 0

@export var speed = 150

func damage(amount: int):
    health = health - clampi(amount - ceili(defense*0.2), 0, 2008)