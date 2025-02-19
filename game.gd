extends Node2D

var peer = ENetMultiplayerPeer.new()

@export var spawn_root: Node2D
@export var player_scene: PackedScene
@export var map_scene: PackedScene

@onready var connection_lost = $CanvasLayer/ConnectionLost
@onready var loading = $CanvasLayer/Loading
@onready var loading_prompt1 = $CanvasLayer/Loading/MarginContainer/VBoxContainer/HBoxContainer/Prompt1
@onready var loading_prompt2 = $CanvasLayer/Loading/MarginContainer/VBoxContainer/HBoxContainer/Prompt2
@onready var loading_prompt3 = $CanvasLayer/Loading/MarginContainer/VBoxContainer/HBoxContainer2/Prompt3
@onready var loading_prompt4 = $CanvasLayer/Loading/MarginContainer/VBoxContainer/HBoxContainer3/Prompt4
@onready var loading_prompt5 = $CanvasLayer/Loading/MarginContainer/VBoxContainer/HBoxContainer3/Prompt5
@onready var next_letter_timer = $NextLetterTimer

@onready var run_time = $CanvasLayer/RunTime
@onready var run_time_label = $CanvasLayer/RunTime/Label

var loading_line = 0
var loading_line_index = 0
var loading_lines = []

var args = Array(OS.get_cmdline_args())
var is_server = '--server' in args
var address: String = "138.199.166.206"
var port: int = 9000
var is_client_connected = false

func _ready() -> void:
	
	connection_lost.visible = false
	run_time.visible = false
	
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
		
		_add_player()
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

func _add_player(id = 1):
	var player = player_scene.instantiate()
	player.name = str(id)
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
		return
	
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
		return
	
	var label = loading_lines[loading_line][0]
	var instant = loading_lines[loading_line][1]
	var delay = loading_lines[loading_line][2]
	var text = loading_lines[loading_line][3]
	
	if instant:
		label.text = text
	else:
		label.text = text.substr(0, loading_line_index)
	
	loading_line_index = loading_line_index + 1

	if not multiplayer.is_server() and text == "Connecting..." and not is_client_connected:
		await multiplayer.connected_to_server
	
	if label.text == text:
		loading_line = loading_line +  1
		loading_line_index = 0
		next_letter_timer.start(delay)
		return
	
	next_letter_timer.start(0.05 + randf_range(0.05, 0.2))
	
func update_run_time(time, show):
	run_time.visible = show
	var minutes = int(time) / 60
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 1000)  # Extract milliseconds
	run_time_label.text = "%02d:%02d.%03d" % [minutes, seconds, milliseconds]
	
