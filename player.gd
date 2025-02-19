extends CharacterBody2D

class_name Player

@export var speed = 200.0
@export var jump_velocity = -300.0

var is_left = false
var can_jump = false
var input_pressed_time = 0
var is_in_start = true
var is_in_end = false

var run_time = 0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var gpu_particles: GPUParticles2D = $GPUParticles2D

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	$Camera.enabled = is_multiplayer_authority()

func _ready() -> void:
	reset()

func reset():
	position = get_tree().get_first_node_in_group("StartPoint").position
	velocity = Vector2.ZERO
	
	is_left = false
	input_pressed_time = 0
	is_in_start = true
	is_in_end = false
	gpu_particles.emitting = false
	run_time = 0

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		visible = not is_in_start
		return 
	
	visible = true
	
	if not is_in_start and not is_in_end:
		run_time += delta
		get_tree().root.get_node_or_null('Game').update_run_time(run_time, true)
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_released("Jump"):
		if input_pressed_time > 1:
			reset()
		input_pressed_time = 0
	elif Input.is_action_just_pressed("Jump"):
		if can_jump and not Dialog.is_active:
			velocity = Vector2(-speed if is_left else speed, jump_velocity)
			can_jump = false
	elif Input.is_action_pressed("Jump"):
			input_pressed_time += delta
			
	var velocity_x_before_move = velocity.x
	
	move_and_slide()
	
	if is_on_wall():
		velocity.x = -velocity_x_before_move
		is_left = not is_left
		can_jump = true
		
	if is_on_floor():
		can_jump = true
	
	gpu_particles.emitting = false
	if not is_on_floor():
		animated_sprite.play('jump')
	elif abs(velocity.x) > 0:
		animated_sprite.play('slide')
		gpu_particles.emitting = true
	else:
		animated_sprite.play('idle')
	
	animated_sprite.flip_h = is_left
