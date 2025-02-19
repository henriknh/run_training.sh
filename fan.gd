extends Node2D

@export var speed = 5

@onready var blades = $Blades

func _process(delta: float) -> void:
	blades.rotation_degrees -= speed * delta
