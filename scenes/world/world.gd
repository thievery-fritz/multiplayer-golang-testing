extends Node2D

@onready var connect_button: Button = $CanvasLayer/ConnectButton
@onready var player_container: Node2D = $PlayerContainer
@onready var spawn_point_container: Node2D = $SpawnPointContainer
@onready var rock_attack_container: Node2D = $RockAttackContainer

func _ready() -> void:
	NetworkManager.player_container = player_container
	NetworkManager.spawn_point_container = spawn_point_container
	NetworkManager.rock_attack_container = rock_attack_container
	connect_button.pressed.connect(_on_connect_button_pressed)
	if "--headless" in OS.get_cmdline_args():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)

func _on_connect_button_pressed() -> void:
	connect_button.hide()
	if OS.has_feature("editor"):
		NetworkManager.start_client("127.0.0.1", 8080)
	else:
		_request_match()

# For later testing...
func _request_match():
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed)
	var err = http.request("http://127.0.0.1:8081/find-match")
	if err:
		print("HTTP Request Error: ", err)

func _on_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		NetworkManager.start_client(json.ip, json.port)
	else:
		print("Matchmaking failed! Code: ", response_code)
		connect_button.show()
