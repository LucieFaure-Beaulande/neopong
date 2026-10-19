extends CanvasLayer
class_name ScoreBoard
# Add this node (CanvasLayer + this script) to the main scene.
# It connects itself to every GoalZone and displays the scores, the timer and the end screen.

var scores := {
	GoalZone.Team.BLEUE: 0,
	GoalZone.Team.ROUGE: 0,
}
var labels := {}
var timer_label: Label
var game_over_overlay: Control
var result_label: Label

@export var progress_bar_red: ProgressBar
@export var progress_bar_blue: ProgressBar

func _ready() -> void:
	_build_ui()
	_build_game_over_ui()
	_connect_zones.call_deferred()

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	root.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var box := HBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 40)
	root.add_child(box)

	var defs := [
		[GoalZone.Team.BLEUE, "Équipe bleue", Color(0.35, 0.55, 1.0)],
		[GoalZone.Team.ROUGE, "Équipe rouge", Color(1.0, 0.35, 0.35)],
	]
	for def in defs:
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 32)
		label.add_theme_color_override("font_color", def[2])
		label.set_meta("title", def[1])
		box.add_child(label)
		labels[def[0]] = label
		_refresh(def[0])

	timer_label = Label.new()
	timer_label.add_theme_font_size_override("font_size", 40)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(timer_label)

func _build_game_over_ui() -> void:
	game_over_overlay = Control.new()
	game_over_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_over_overlay.visible = false
	add_child(game_over_overlay)

	# Dark background behind the text
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_over_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_over_overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "Temps écoulé !"
	title.add_theme_font_size_override("font_size", 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	result_label = Label.new()
	result_label.add_theme_font_size_override("font_size", 40)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(result_label)

func _connect_zones() -> void:
	for zone in get_tree().get_nodes_in_group("goal_zone"):
		if not zone.goal_scored.is_connected(_on_goal_scored):
			zone.goal_scored.connect(_on_goal_scored)

func _on_goal_scored(team: int) -> void:
	scores[team] += 1
	if(team == 0):
		progress_bar_red.value += 300
	else:
		progress_bar_blue.value += 300
	_refresh(team)

func _refresh(team: int) -> void:
	var label: Label = labels[team]
	label.text = "%s : %d" % [label.get_meta("title"), scores[team]]

# Displays the remaining time as MM:SS
@warning_ignore("integer_division")
func update_timer(seconds_left: float) -> void:
	var total_seconds := int(ceil(maxf(seconds_left, 0.0)))
	timer_label.text = "%02d:%02d" % [total_seconds / 60, total_seconds % 60]

# Shows the end screen with the final score and the winner (or a draw)
func show_game_over() -> void:
	var blue: int = scores[GoalZone.Team.BLEUE]
	var red: int = scores[GoalZone.Team.ROUGE]
	if blue > red:
		result_label.text = "Victoire de l'équipe bleue (%d - %d)" % [blue, red]
		result_label.add_theme_color_override("font_color", Color(0.35, 0.55, 1.0))
	elif red > blue:
		result_label.text = "Victoire de l'équipe rouge (%d - %d)" % [red, blue]
		result_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	else:
		result_label.text = "Égalité (%d - %d)" % [blue, red]
		result_label.remove_theme_color_override("font_color")
	game_over_overlay.visible = true
