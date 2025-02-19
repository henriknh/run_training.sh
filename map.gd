@tool

extends Node2D

func _ready() -> void:
	var start_zone_collision_shape: CollisionShape2D = $StartZone/CollisionShape2D
	var start_zone_shape: RectangleShape2D = start_zone_collision_shape.shape
	var start_zone_color_rect: ColorRect = $StartZone/ColorRect
	start_zone_color_rect.size = start_zone_shape.size
	start_zone_color_rect.position = start_zone_collision_shape.position - start_zone_shape.size / 2
	
	var end_zone_collision_shape: CollisionShape2D = $EndZone/CollisionShape2D
	var end_zone_shape: RectangleShape2D = end_zone_collision_shape.shape
	var end_zone_color_rect: ColorRect = $EndZone/ColorRect
	end_zone_color_rect.size = end_zone_shape.size
	end_zone_color_rect.position = end_zone_collision_shape.position - end_zone_shape.size / 2

func _on_start_zone_body_entered(body: Node2D) -> void:
	if body is Player:
		body.is_in_start = false
		body.run_time = 0

func _on_end_zone_body_entered(body: Node2D) -> void:
	if body is Player:
		body.is_in_end = true
