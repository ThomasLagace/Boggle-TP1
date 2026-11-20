class_name ConnectClientUI
extends Control

@onready var info_panel: PanelContainer = $InfoPanel
@onready var name_edit: LineEdit = $InfoPanel/ConnectionInformation/NameEdit
@onready var address_edit: LineEdit = $InfoPanel/ConnectionInformation/AddressEdit
@onready var port_edit: LineEdit = $InfoPanel/ConnectionInformation/PortEdit
@onready var connect_button: Button = $InfoPanel/ConnectionInformation/ConnectButton

var _connecting := false
var _pulse: Tween


func _ready() -> void:
	connect_button.pressed.connect(on_connect_button_press)
	for edit in [name_edit, address_edit, port_edit]:
		edit.text_submitted.connect(func(_t): on_connect_button_press())

	GlobalClientConnect.on_client_connect.connect(func():
		GlobalClientConnect.client.SubmitNameToServer(name_edit.text)
	)
	# Bound method (not a lambda) so it is dropped when this scene is freed.
	GlobalClientConnect.on_client_connect_failed.connect(_on_connect_failed, CONNECT_DEFERRED)

	_style()
	_entrance()
	name_edit.grab_focus.call_deferred()

func _style() -> void:
	var panel := Metro.shadowed(Metro.box(Metro.INK, 22, 0, Metro.INK, 34, 30), 30, Vector2(0, 14), Color(Metro.INK, 0.3))
	info_panel.add_theme_stylebox_override("panel", panel)
	var pairs := [[$InfoPanel/ConnectionInformation/NameLabel, name_edit],
		[$InfoPanel/ConnectionInformation/AddressLabel, address_edit],
		[$InfoPanel/ConnectionInformation/PortLabel, port_edit]]
	for pair in pairs:
		var label: Label = pair[0]
		var edit: LineEdit = pair[1]
		label.add_theme_color_override("font_color", Metro.ON_INK_SOFT)
		label.add_theme_font_size_override("font_size", 15)
		edit.focus_entered.connect(func(): _light(label, true))
		edit.focus_exited.connect(func(): _light(label, false))
	# Breathing room between field groups, not between a label and its field.
	for l in [$InfoPanel/ConnectionInformation/AddressLabel, $InfoPanel/ConnectionInformation/PortLabel]:
		var spacer := Control.new()
		spacer.custom_minimum_size.y = 10
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.get_parent().add_child(spacer)
		l.get_parent().move_child(spacer, l.get_index())

func _light(label: Label, on: bool) -> void:
	var tw := label.create_tween()
	var target := Metro.SAFFRON if on else Metro.ON_INK_SOFT
	tw.tween_method(func(c: Color): label.add_theme_color_override("font_color", c),
		label.get_theme_color("font_color"), target, 0.18)

func _entrance() -> void:
	info_panel.modulate.a = 0.0
	var base_y := info_panel.position.y
	info_panel.position.y = base_y + 36.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(info_panel, "modulate:a", 1.0, 0.5).set_delay(0.9)
	tw.tween_property(info_panel, "position:y", base_y, 0.7).set_delay(0.9).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

func on_connect_button_press() -> void:
	if _connecting:
		return
	if name_edit.text.strip_edges() == "":
		_flag(name_edit)
		return
	var ip = address_edit.text
	var port = port_edit.text
	GlobalClientConnect.client_name = name_edit.text
	if GlobalClientConnect.create_client(ip, port):
		_set_connecting(true)
		GlobalClientConnect.connect_client()
	else:
		_flag(address_edit)
		_flag(port_edit)

func _set_connecting(on: bool) -> void:
	_connecting = on
	connect_button.disabled = on
	if _pulse:
		_pulse.kill()
	connect_button.modulate = Color.WHITE
	if on:
		_pulse = create_tween().set_loops()
		_pulse.tween_property(connect_button, "modulate", Color(1, 1, 1, 0.55), 0.45).set_trans(Tween.TRANS_SINE)
		_pulse.tween_property(connect_button, "modulate", Color.WHITE, 0.45).set_trans(Tween.TRANS_SINE)

func _on_connect_failed() -> void:
	_set_connecting(false)
	Metro.chime_reject()
	Metro.shake(connect_button, 12.0)

## Point at a field that needs fixing: shake it and ring it in vermillion.
func _flag(edit: LineEdit) -> void:
	Metro.chime_reject()
	edit.grab_focus()
	var ring := Metro.box(Metro.WHITE, 12, 3, Metro.VERMILLION_HOT, 16, 10)
	edit.add_theme_stylebox_override("normal", ring)
	Metro.shake(edit, 10.0)
	get_tree().create_timer(1.4).timeout.connect(func():
		if is_instance_valid(edit):
			edit.remove_theme_stylebox_override("normal")
	)
