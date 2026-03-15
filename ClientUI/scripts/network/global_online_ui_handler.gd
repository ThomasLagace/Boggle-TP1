extends Node

const BOGGLE_ONLINE_GAME_UI    = preload("uid://b7276br67b2wa")
const CONNECT_CLIENT_UI        = preload("uid://doidx1hat37mv")
const END_GAME_UI              = preload("uid://b7gobrut8p2cj")
const LOST_CONNECTION_UI       = preload("uid://r1oyu4eg1oj6")
const OPPONENT_DISCONNECTED_UI = preload("uid://dscgslbxm0bc5")
const WAITING_OTHER_PLAYER_UI  = preload("uid://dglgcfqtkw2x1")

func _ready() -> void:
	GlobalClientConnect.on_client_initialized.connect(on_client_initialized)

func on_client_initialized(client: BoggleClientNode) -> void:
	GlobalClientConnect.on_client_connect.connect(on_client_connect)
	client.OnGameStart.connect(on_game_start)
	client.OnLostConnection.connect(on_lost_connection)

func on_client_connect() -> void:
	var waiting_scene = WAITING_OTHER_PLAYER_UI.instantiate()
	get_tree().change_scene_to_node(waiting_scene)

func on_game_start(unix_endtime: int, opponent_name: String) -> void:
	GlobalClientConnect.opponent_name = opponent_name
	var client = GlobalClientConnect.client
	client.OnOpponentDisconnected.connect(on_opponent_disconnected)
	client.OnGameEnd.connect(on_game_end)

	var game_scene: BoggleOnlineGameUI = BOGGLE_ONLINE_GAME_UI.instantiate()
	game_scene.initialize(client.GetBoggleBoard(), opponent_name, unix_endtime)

	client.OnScoreUpdate.connect(func(client_score, opponent_score):
		game_scene.update_score(client_score, opponent_score)
	)

	game_scene.on_submit_guess.connect(GlobalClientConnect.client.SubmitGuessToServer)

	get_tree().change_scene_to_node(game_scene)

func on_lost_connection() -> void:
	GlobalClientConnect.dispose()
	var lost_connection_scene = LOST_CONNECTION_UI.instantiate()
	get_tree().change_scene_to_node(lost_connection_scene)

func on_opponent_disconnected() -> void:
	GlobalClientConnect.dispose()
	var end_game_scene = OPPONENT_DISCONNECTED_UI.instantiate()
	get_tree().change_scene_to_node(end_game_scene)

func on_game_end(client_score: int, opponent_score: int) -> void:
	var winner_name: String
	if client_score > opponent_score:
		winner_name = GlobalClientConnect.client_name
	elif client_score < opponent_score:
		winner_name = GlobalClientConnect.opponent_name
	else:
		winner_name = "Nulle!"
	var end_game_scene = END_GAME_UI.instantiate()
	end_game_scene.initialize(client_score, opponent_score, winner_name)

	GlobalClientConnect.dispose()

	get_tree().change_scene_to_node(end_game_scene)
