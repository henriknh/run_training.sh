extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	var address: String = "138.199.166.206"
	var port: int = 9000
	multiplayer.server_disconnected.connect(func ():
		print('server_disconnected')
	)
	multiplayer.connected_to_server.connect(func():
		print('client connected')
	)
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
