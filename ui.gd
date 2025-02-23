extends Control

@onready var animation_player = $AnimationPlayer
@onready var connection_lost = $CanvasLayer/ConnectionLost
@onready var title = $CanvasLayer/Title
@onready var loading = $CanvasLayer/Loading
@onready var loading_prompt1 = $CanvasLayer/Loading/MarginContainer/VBoxContainer/HBoxContainer/Prompt1
@onready var loading_prompt2 = $CanvasLayer/Loading/MarginContainer/VBoxContainer/HBoxContainer/Prompt2
@onready var loading_prompt3 = $CanvasLayer/Loading/MarginContainer/VBoxContainer/HBoxContainer2/Prompt3
@onready var loading_prompt4 = $CanvasLayer/Loading/MarginContainer/VBoxContainer/HBoxContainer3/Prompt4
@onready var loading_prompt5 = $CanvasLayer/Loading/MarginContainer/VBoxContainer/HBoxContainer3/Prompt5
@onready var next_letter_timer = $NextLetterTimer

@onready var run_ui = $CanvasLayer/RunUI
@onready var player_ai_model_training = $CanvasLayer/RunUI/MarginContainer/HBoxContainer/PlayerStats/AIModel
@onready var player_name = $CanvasLayer/RunUI/MarginContainer/HBoxContainer/PlayerStats/Name
@onready var player_epochs = $CanvasLayer/RunUI/MarginContainer/HBoxContainer/PlayerStats/Epochs
@onready var player_parallel_runs = $CanvasLayer/RunUI/MarginContainer/HBoxContainer/PlayerStats/ParallelRuns
@onready var player_time = $CanvasLayer/RunUI/MarginContainer/HBoxContainer/PlayerStats/Time

@onready var leaderboard = $CanvasLayer/RunUI/MarginContainer/HBoxContainer/Leaderboard
@onready var leaderboard_candidate1 = $CanvasLayer/RunUI/MarginContainer/HBoxContainer/Leaderboard/VBoxContainer
@onready var leaderboard_candidate1_id = $CanvasLayer/RunUI/MarginContainer/HBoxContainer/Leaderboard/VBoxContainer/HBoxContainer/Candidate1
@onready var leaderboard_candidate1_time = $CanvasLayer/RunUI/MarginContainer/HBoxContainer/Leaderboard/VBoxContainer/Time1
@onready var leaderboard_candidate2 = $CanvasLayer/RunUI/MarginContainer/HBoxContainer/Leaderboard/VBoxContainer2
@onready var leaderboard_candidate2_id = $CanvasLayer/RunUI/MarginContainer/HBoxContainer/Leaderboard/VBoxContainer2/HBoxContainer/Candidate2
@onready var leaderboard_candidate2_time = $CanvasLayer/RunUI/MarginContainer/HBoxContainer/Leaderboard/VBoxContainer2/Time2
@onready var leaderboard_candidate3 = $CanvasLayer/RunUI/MarginContainer/HBoxContainer/Leaderboard/VBoxContainer3
@onready var leaderboard_candidate3_id = $CanvasLayer/RunUI/MarginContainer/HBoxContainer/Leaderboard/VBoxContainer3/HBoxContainer/Candidate3
@onready var leaderboard_candidate3_time = $CanvasLayer/RunUI/MarginContainer/HBoxContainer/Leaderboard/VBoxContainer3/Time3
@onready var leaderboard_personal_best = $CanvasLayer/RunUI/MarginContainer/HBoxContainer/Leaderboard/VBoxContainer4
@onready var leaderboard_personal_best_time = $CanvasLayer/RunUI/MarginContainer/HBoxContainer/Leaderboard/VBoxContainer4/Time4

@onready var sound_amient = $SoundAmbient
@onready var sound_key_press = $SoundKeyPress

var is_client_connected = false

var loading_line = 0
var loading_line_index = 0
var loading_lines = []

signal loading_complete

func _ready() -> void:
	connection_lost.visible = false
	title.visible = false
	loading.visible = false
	run_ui.visible = false

func _generate_loading_lines(address):
	loading_lines = [
		[loading_prompt1, true,  0.550, OS.has_environment("USERNAME") if OS.has_environment("USERNAME") else "user" + "@workstation ~"],
		[loading_prompt2, false,  0.1, "ssh root@" + address],
		[loading_prompt3, true, 1.100, "Connecting..."],
		[loading_prompt3, true, 0.1, "Welcome to the Training Terminal."],
		[loading_prompt4, true, 1.150, "root@terminal ~"],
		[loading_prompt5, false, 0.250, "./run_training.sh"]
	]

func run_intro(address):
	title.visible = true
	
	await get_tree().create_timer(1).timeout
	animation_player.play("TitleFade")
	await animation_player.animation_finished
	await get_tree().create_timer(0.5).timeout
	
	title.visible = false
	loading.visible = true
	
	_generate_loading_lines(address)
	
	loading_prompt1.text = ''
	loading_prompt2.text = ''
	loading_prompt3.text = ''
	loading_prompt4.text = ''
	loading_prompt5.text = ''
	
	_next_letter()

func _next_letter():
	if loading_line >= loading_lines.size():
		loading.visible = false
		loading_complete.emit()
		
		sound_amient.play()
		return
	
	var label = loading_lines[loading_line][0]
	var instant = loading_lines[loading_line][1]
	var delay = loading_lines[loading_line][2]
	var text = loading_lines[loading_line][3]
	
	if instant:
		label.text = text
	else:
		label.text = text.substr(0, loading_line_index)
		sound_key_press.play()
	
	loading_line_index = loading_line_index + 1

	if not multiplayer.is_server() and text == "Connecting..." and not is_client_connected:
		await multiplayer.connected_to_server
	
	if label.text == text:
		loading_line = loading_line +  1
		loading_line_index = 0
		next_letter_timer.start(delay)
		return
	
	next_letter_timer.start(0.05 + randf_range(0.05, 0.2))
