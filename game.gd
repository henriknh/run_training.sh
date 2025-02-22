extends Node2D

var peer = ENetMultiplayerPeer.new()

@export var spawn_root: Node2D
@export var player_scene: PackedScene
@export var map_scene: PackedScene

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

var leaderboard_times = []
var leaderboard_ids = []
var personal_best = INF

var loading_line = 0
var loading_line_index = 0
var loading_lines = []

var args = Array(OS.get_cmdline_args())
var is_server = '--server' in args
var address: String = "138.199.166.206"
var port: int = 9000
var is_client_connected = false

var candidate_id = randi_range(500000, 1000000)

signal loading_complete

func _ready() -> void:
	
	connection_lost.visible = false
	title.visible = false
	loading.visible = false
	run_ui.visible = false
	
	for arg in args:
		if '--address' in arg:
			var split = arg.split('=')
			address = split[1]
		if '--port' in arg:
			var split = arg.split('=')
			port = int(split[1])

	if is_server:
		prints('Starting server on port', 9000)
		
		peer.create_server(port)
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(_add_player)
		
		var map = map_scene.instantiate()
		spawn_root.add_child.call_deferred(map)
		
		#_add_player()
	else:
		prints('Connecting to server at', address, 'and port', 9000)
	
		multiplayer.server_disconnected.connect(func ():
			connection_lost.visible = true
		)
		multiplayer.connected_to_server.connect(func():
			is_client_connected = true
		)
		
		peer.create_client(address, port)
		multiplayer.multiplayer_peer = peer
	
	run_intro()

func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		update_leaderboard.rpc(leaderboard_times, leaderboard_ids)

func _add_player(id = 1):
	var player = player_scene.instantiate()
	player.name = str(id)
	player.position = get_tree().get_first_node_in_group("StartPoint").position
	player.is_in_cinematic = true
	spawn_root.add_child.call_deferred(player)

func _generate_loading_lines():
	loading_lines = [
		[loading_prompt1, true,  0.550, OS.has_environment("USERNAME") if OS.has_environment("USERNAME") else "user" + "@workstation ~"],
		[loading_prompt2, false,  0.1, "ssh root@" + address],
		[loading_prompt3, true, 1.100, "Connecting..."],
		[loading_prompt3, true, 0.1, "Welcome to the Training Terminal."],
		[loading_prompt4, true, 1.150, "root@terminal ~"],
		[loading_prompt5, false, 0.250, "./run_training.sh"]
	]

func run_intro():
	if is_server:
		loading.visible = false
		loading_complete.emit()
		return
		
	title.visible = true
	
	await get_tree().create_timer(1).timeout
	animation_player.play("TitleFade")
	await animation_player.animation_finished
	await get_tree().create_timer(0.5).timeout
	
	title.visible = false
	loading.visible = true
	
	_generate_loading_lines()
	
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

func _format_time(time):
	var minutes = int(time) / 60
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 1000)  # Extract milliseconds
	return "%02d:%02d.%03d" % [minutes, seconds, milliseconds]
	
func update_player_ui(time, show, epoch, show_epoch, candidate_id):
	run_ui.visible = show
	
	leaderboard.visible = show_epoch
	
	player_ai_model_training.visible = show_epoch
	player_name.text = ("Run ID " + str(candidate_id)) if show_epoch else ("Candidate " + str(candidate_id))
	player_epochs.text = (str(epoch) + " of 1000000 epochs") if show_epoch else (str(epoch) + " attempts")
	player_time.text = _format_time(time)

@rpc("authority", "call_remote", "reliable")
func update_leaderboard(leaderboard_times, leaderboard_ids):
	#prints("update_leaderboard", multiplayer.is_server(), leaderboard_times, leaderboard_ids)
	
	leaderboard_candidate1.visible = leaderboard_times.size() >= 1
	leaderboard_candidate2.visible = leaderboard_times.size() >= 2
	leaderboard_candidate3.visible = leaderboard_times.size() >= 3
	
	if leaderboard_times.size() >= 1:
		leaderboard_candidate1_id.text = str(leaderboard_ids[0])
		leaderboard_candidate1_time.text = _format_time(leaderboard_times[0])
	
	if leaderboard_times.size() >= 2:
		leaderboard_candidate2_id.text = str(leaderboard_ids[1])
		leaderboard_candidate2_time.text = _format_time(leaderboard_times[1])
	
	if leaderboard_times.size() >= 3:
		leaderboard_candidate3_id.text = str(leaderboard_ids[2])
		leaderboard_candidate3_time.text = _format_time(leaderboard_times[2])
	
	leaderboard_personal_best.visible = personal_best != INF
	leaderboard_personal_best_time.text = _format_time(personal_best)

@rpc("any_peer", "call_remote", "reliable")
func register_time(time, id):
	prints('register_time', multiplayer.is_server(), time, id)
	
	prints(leaderboard_times)
	prints(leaderboard_ids)
	

	
	if leaderboard_times.size() >= 1 and time < leaderboard_times[0]:
		leaderboard_times.insert(0, time)
		leaderboard_ids.insert(0, id)
	
	elif leaderboard_times.size() >= 2 and time < leaderboard_times[1]:
		leaderboard_times.insert(1, time)
		leaderboard_ids.insert(1, id)
	
	elif leaderboard_times.size() >= 3 and time < leaderboard_times[2]:
		leaderboard_times.insert(2, time)
		leaderboard_ids.insert(2, id)
	elif leaderboard_times.size() < 3:
		leaderboard_times.append(time)
		leaderboard_ids.append(id)
	
	if leaderboard_times.size() > 3:
		leaderboard_times = leaderboard_times.slice(0, 3)
		leaderboard_ids = leaderboard_ids.slice(0, 3)
	
	prints(leaderboard_times)
	prints(leaderboard_ids)

func register_player_time(time, id):
	prints('register_player_time', time, id)
	if time < personal_best:
		personal_best = time
	
	register_time.rpc_id(1, time, id)
