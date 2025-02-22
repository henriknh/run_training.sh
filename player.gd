extends CharacterBody2D

class_name Player

@export var speed = 200.0
@export var jump_velocity = -300.0

var is_left = false
var can_jump = false
var input_pressed_time = 0
var is_in_start = true
var is_in_end = false
var gravity_dir = -1
var run_time = 0
var is_in_cinematic = false
var has_completed_once = false
var candidate_id

var game_node: Node2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var gpu_particles: GPUParticles2D = $GPUParticles2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var camera = $Camera

@onready var computer1: AnimatedSprite2D = get_tree().get_first_node_in_group("Computer1")
@onready var computer2: AnimatedSprite2D = get_tree().get_first_node_in_group("Computer2")

@onready var sound_computer_on = $SoundComputerOn
@onready var sound_computer_off = $SoundComputerOff

var dialog_resource = preload("res://Dialog.tscn")


var epoch = 0
var dialogs_tutorial = []
var dialogs_end = []

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	$Camera.enabled = is_multiplayer_authority()

func _ready() -> void:
	game_node = get_tree().root.get_node_or_null('Game')
	candidate_id = game_node.candidate_id
	
	reset()
	
	dialogs_tutorial = [
		"Welcome candidate " + str(candidate_id) +"!",
		#"Today's training is the obstacle course.",
		#"Finish in the shortest possible time.",
		#"Your performance will be recorded.",
		#"Use [space] to navigate.",
		#"Restart by long pressing [space].",
		"Good luck and have fun!"
	]

	dialogs_end = [
		#"Run " + str(candidate_id) + " succeeded.",
		#"Time has been recorded.",
		"Recycle " + str(candidate_id) + " and rerun."
	]
	

	if is_multiplayer_authority():
		game_node.connect("loading_complete", func():
			run_intro()
		)

func reset():
	epoch += 1
	position = get_tree().get_first_node_in_group("StartPoint").position
	velocity = Vector2.ZERO
	
	is_left = false
	input_pressed_time = 0
	is_in_start = true
	is_in_end = false
	gpu_particles.emitting = false
	run_time = 0
	gravity_dir = 1
	animated_sprite.flip_h = is_left
	animated_sprite.flip_v = gravity_dir == -1
	collision_shape.position.y = -9 if gravity_dir == 1 else -15
	animated_sprite.play('idle')

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		visible = not is_in_start
		return 
	
	visible = true
	
	_update_visuals()
	
	if is_in_cinematic:
		if is_in_end:
			is_left = false
			position.x = lerpf(position.x, get_tree().get_first_node_in_group("EndPoint").position.x, 2 * delta)
			velocity.y += get_gravity().y * gravity_dir * delta
			move_and_slide()
		return
	
	if not is_in_start and not is_in_end:
		run_time += delta
		game_node.update_player_ui(run_time, true, epoch, has_completed_once, candidate_id)
	elif has_completed_once:
		game_node.update_player_ui(run_time, true, epoch, has_completed_once, candidate_id)
	else:
		game_node.update_player_ui(run_time, false, epoch, has_completed_once, candidate_id)

	velocity.y += get_gravity().y * gravity_dir * delta
	
	#camera.position.x = lerpf(camera.position.x, smoothstep(-speed, speed, velocity.x) * 128, 5 * delta)
	
	if Input.is_action_just_released("Jump"):
		if input_pressed_time > 1:
			reset()
		input_pressed_time = 0
	elif Input.is_action_just_pressed("Jump"):
		prints('can_jump', can_jump)
		if can_jump:
			velocity = Vector2(-speed if is_left else speed, jump_velocity * gravity_dir)
			can_jump = false
	elif Input.is_action_pressed("Jump"):
			input_pressed_time += delta
			
	var velocity_x_before_move = velocity.x
	
	move_and_slide()
	
	if not is_in_start and not is_in_end:
		velocity.x = -speed if is_left else speed
	
	if is_on_wall():
		velocity.x = -velocity_x_before_move
		is_left = not is_left
		can_jump = true
		
	_update_visuals()

func _update_visuals():
	var is_grounded = is_on_floor() if gravity_dir == 1 else is_on_ceiling()
	
	if is_grounded:
		can_jump = true
	
	gpu_particles.emitting = false
	if not is_grounded:
		animated_sprite.play('jump')
	elif abs(velocity.x) > 0:
		animated_sprite.play('slide')
		gpu_particles.emitting = true
	else:
		animated_sprite.play('idle')
	
	animated_sprite.flip_h = is_left
	animated_sprite.flip_v = gravity_dir == -1
	collision_shape.position.y = -9 if gravity_dir == 1 else -15
func run_intro():
	is_in_cinematic = true
	is_in_start = true
	
	await get_tree().create_timer(2).timeout
	computer1.play("idle")
	sound_computer_on.play()
	await get_tree().create_timer(1).timeout
	computer1.play("talking")
	
	for text in dialogs_tutorial:
		var dialog = dialog_resource.instantiate()
		dialog.global_position = computer1.position
		get_tree().root.add_child(dialog)
		dialog.display_text(text)
		await dialog.finished_displaying
		await get_tree().create_timer(1).timeout
		dialog.queue_free()
		
	computer1.play("idle")
	await get_tree().create_timer(2).timeout
	computer1.play("off")
	sound_computer_off.play()
	is_in_cinematic = false
	
func run_ending():
	
	game_node.register_player_time(run_time, candidate_id)
	is_in_end = true
	
	if has_completed_once:
		await get_tree().create_timer(1).timeout
		velocity = Vector2.ZERO
		reset()
		return
	
	has_completed_once = true
	is_in_cinematic = true
	
	await get_tree().create_timer(2).timeout
	computer2.play("idle")
	sound_computer_on.play()
	await get_tree().create_timer(1).timeout
	computer2.play("talking")
	
	
	for text in dialogs_end:
		var dialog = dialog_resource.instantiate()
		dialog.global_position = computer2.position
		get_tree().root.add_child(dialog)
		dialog.display_text(text)
		await dialog.finished_displaying
		await get_tree().create_timer(1).timeout
		dialog.queue_free()
		
	computer2.play("idle")
	await get_tree().create_timer(2).timeout
	computer2.play("off")
	sound_computer_off.play()
	await get_tree().create_timer(2).timeout
	
	reset()
	
	await get_tree().create_timer(2).timeout
	computer1.play("idle")
	sound_computer_on.play()
	await get_tree().create_timer(1).timeout
	computer1.play("talking")
	
	var dialog = dialog_resource.instantiate()
	dialog.global_position = computer1.position
	get_tree().root.add_child(dialog)
	dialog.display_text("Begin!")
	await dialog.finished_displaying
	await get_tree().create_timer(1).timeout
	dialog.queue_free()
	
	computer1.play("idle")
	await get_tree().create_timer(2).timeout
	computer1.play("off")
	sound_computer_off.play()
	await get_tree().create_timer(2).timeout
	
	is_in_cinematic = false
	
