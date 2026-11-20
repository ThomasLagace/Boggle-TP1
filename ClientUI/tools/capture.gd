extends Node
## Dev-only: renders each screen in key states to PNG for design review.

const OUT := "res://../.impeccable/review/"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _wait(0.3)
	await _shot(load("res://scenes/online_scenes/connect_client_ui.tscn").instantiate(), "connect", 2.8)
	await _shot(load("res://scenes/online_scenes/waiting_other_player_ui.tscn").instantiate(), "waiting", 2.0)

	var game = _make_game(272)
	await _shot(game, "game_idle", 1.6)
	var board: BoggleBoardUI = game.boggle_board_ui
	var letters = board._letters
	# trace a path: (0,0)->(1,1)->(2,1)->(3,2)
	for idx in [0, 5, 6, 11]:
		board.add_guess(letters[idx])
		await _wait(0.15)
	_move(letters[15].get_global_rect().get_center())
	await _wait(0.6)
	await _save("game_trace")
	# over cancel zone
	board.debug_mouse_override = Vector2(120, 370)
	await _wait(0.5)
	assert(board._over_cancel)
	await _save("game_cancel_hot")
	board.debug_mouse_override = null
	_move(letters[11].get_global_rect().get_center())
	await _wait(0.1)
	var word = board.get_current_word()
	game.current_guess_label.text = word
	board.submit_guess()
	game._pending.append({"word": "TRAIN", "at": Time.get_ticks_msec() / 1000.0})
	await _wait(0.2)
	await _save("game_depart")
	board._last_submitted.assign([letters[0], letters[5], letters[6], letters[11]])
	game.update_score(3, 0)
	await _wait(0.2)
	await _save("game_accept")
	game.update_score(3, 2)
	for w in [["MARE", 5], ["LIEN", 7], ["NOTE", 9]]:
		game._pending.append({"word": w[0], "at": Time.get_ticks_msec() / 1000.0})
		game.update_score(w[1], 2 + w[1] / 3)
		await _wait(0.1)
	await _wait(1.2)
	await _save("game_routes")

	var hot = _make_game(8)
	await _shot(hot, "game_urgent", 1.2)

	var end = load("res://scenes/online_scenes/end_game_ui.tscn").instantiate()
	GlobalClientConnect.client_name = "Vincent"
	GlobalClientConnect.opponent_name = "Alex"
	end.initialize(23, 17, "Vincent")
	await _shot(end, "end", 3.2)
	await _shot(load("res://scenes/online_scenes/lost_connection_ui.tscn").instantiate(), "lost", 1.6)
	await _shot(load("res://scenes/online_scenes/opponent_disconnected_ui.tscn").instantiate(), "opponent_left", 1.6)

	# transition mid-wipe
	Metro.go_to_packed(load("res://scenes/online_scenes/connect_client_ui.tscn"))
	await _wait(0.3)
	await _save("wipe")
	get_tree().quit()

func _move(p: Vector2) -> void:
	Input.warp_mouse(p * _win_scale())
	var e := InputEventMouseMotion.new()
	e.position = p
	e.global_position = p
	get_viewport().push_input(e)

func _win_scale() -> Vector2:
	return Vector2(get_window().size) / Vector2(1152, 648)

func _make_game(secs_left: int) -> Node:
	GlobalClientConnect.client_name = "Vincent"
	var abs_path = ProjectSettings.globalize_path("res://dict.txt")
	var g = BoggleGameResource.CreateInstance(abs_path)
	var game = load("res://scenes/online_scenes/boggle_online_game_ui.tscn").instantiate()
	game.initialize(g.Board(), "Alex", int(Time.get_unix_time_from_system()) + secs_left)
	game._total_secs = 300.0
	return game

func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _shot(node: Node, name: String, settle: float) -> void:
	var cur := get_tree().current_scene
	if cur and cur != self:
		cur.queue_free()
	get_tree().root.add_child(node)
	get_tree().current_scene = node
	await _wait(settle)
	await _save(name)

func _save(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("saved ", name)
