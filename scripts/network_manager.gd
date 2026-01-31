extends Node

const PLAYER_SCENE = preload("res://scenes/player/player.tscn")
var peer = ENetMultiplayerPeer.new()
var player_container: Node2D = null
var spawn_point_container: Node2D = null
var rock_attack_container: Node2D = null
var rock_spawner: MultiplayerSpawner = null
var players: Dictionary = {}

func _ready():
	NetworkEvents.on_client_start.connect(_on_client_start)
	NetworkEvents.on_client_stop.connect(_handle_stop)
	NetworkEvents.on_peer_join.connect(_on_peer_join)
	NetworkEvents.on_peer_leave.connect(_on_peer_leave)
	NetworkEvents.on_server_start.connect(_on_server_start)
	NetworkEvents.on_server_stop.connect(_handle_stop)
	var args = OS.get_cmdline_user_args()
	if "--server" in args:
		var port = _get_arg_value(args, "--port", "8080").to_int()
		start_server(port)

func start_server(port: int):
	if peer.create_server(port) != OK:
		print("Failed to listen on port %s" % port)
	multiplayer.multiplayer_peer = peer


func start_client(ip: String, port: int):
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer
	print("Connecting to ", ip, ":", port)

func _on_server_start():
	print("_on_server_start (%d)" % multiplayer.get_unique_id())

func _on_client_start(id: int):
	print("_on_client_start (%d)" % multiplayer.get_unique_id())
	_spawn_player(id)

func _handle_stop():
	print("_handle_stop (%d)" % multiplayer.get_unique_id())
	for p in players.values():
		p.queue_free()
	players.clear()

func _on_peer_join(id: int):
	print("peer join id %d" % id)
	if id != 1:
		print("_on_peer_join (%d)" % multiplayer.get_unique_id())
		_spawn_player(id)
		#var player_avatar = _spawn_player(id)
		#player_avatar.visible = false
		#while not NetworkTime.is_client_synced(id):
			#await NetworkTime.after_client_sync
		#player_avatar.visible = true

func _on_peer_leave(id: int):
	print("_on_peer_leave (%d)" % multiplayer.get_unique_id())
	if !players.has(id):
		return
	var player = players[id] as Node
	player.queue_free()
	players.erase(id)

func _spawn_player(id: int):
	if !player_container:
		print("ERROR: No Player Spawn Node Assigned?")
		return
	var player = PLAYER_SCENE.instantiate()
	players[id] = player
	player.name = str(id)
	player.visible = false
	# The spawn pos logic here is fragile, need to address at some point. Also, is there a reason why I'm not
	# just using a MultiplayerSpawner for the players? Forestbrawl did it like this...but idk....
	var spawn_position: Marker2D = spawn_point_container.get_child(0) if player_container.get_child_count() % 2 == 0 else spawn_point_container.get_child(1)
	player.spawn_position = spawn_position.global_position
	player.global_position = spawn_position.global_position
	player_container.add_child(player)
	player.set_multiplayer_authority(1)
	print("[%d] Player(%d) Spawned at %s" % [multiplayer.get_unique_id(), id, player.global_position])
	var input = player.find_child("Input")
	if input:
		input.set_multiplayer_authority(id)
	return player

func _get_arg_value(args: Array, flag: String, default: String) -> String:
	for i in range(args.size()):
		if args[i] == flag and i + 1 < args.size():
			return args[i+1]
	return default
