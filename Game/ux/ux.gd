extends CanvasLayer
class_name ScoreBoard
# Add this node (CanvasLayer + this script) to the main scene.
# It connects itself to every GoalZone and displays the scores, the timer and the end screen.

var scores := {
	GoalZone.Team.BLEUE: 0,
	GoalZone.Team.ROUGE: 0,
}

@export var progress_bar_red: ProgressBar
@export var progress_bar_blue: ProgressBar

@export var blue_score: Label
@export var red_score: Label

@export var blue_result: AnimatedSprite2D
@export var red_result: AnimatedSprite2D

func _ready() -> void:
	_connect_zones.call_deferred()

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
	if(team == 0):
		blue_score.change_text(scores[team])
	else:
		red_score.change_text(scores[team])

# Shows the end screen with the final score and the winner (or a draw)
func show_game_over() -> void:
	var blue: int = scores[GoalZone.Team.BLEUE]
	var red: int = scores[GoalZone.Team.ROUGE]
	if blue > red:
		blue_result.show_result(1)
		red_result.show_result(2)
	elif red > blue:
		blue_result.show_result(2)
		red_result.show_result(1)
	else:
		blue_result.show_result(3)
		red_result.show_result(3)
