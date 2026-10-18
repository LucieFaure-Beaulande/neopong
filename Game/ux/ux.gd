extends CanvasLayer
class_name ScoreBoard
# Ajoute ce node (CanvasLayer + ce script) dans ta scène principale.
# Il se connecte tout seul à toutes les GoalZone et affiche les scores.

var scores := {
	GoalZone.Team.BLEUE: 0,
	GoalZone.Team.ROUGE: 0,
}
var labels := {}

@export var progress_bar_red: ProgressBar
@export var progress_bar_blue: ProgressBar

func _ready() -> void:
	_build_ui()
	_connect_zones.call_deferred()

func _build_ui() -> void:
	var box := HBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	box.add_theme_constant_override("separation", 40)
	add_child(box)

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
