extends Node

var epoch = 1
var candidate_id = randi_range(500000, 1000000)

var is_active = false

var dialogs_tutorial = [
	"Welcome candidate " + str(candidate_id) +"!",
	"Today's training is the obstacle course.",
	"Finish in the shortest possible time.",
	"Your performance will be recorded.",
	"Use [space] to navigate.",
	"Restart by long pressing the input key.",
	"Good luck."
]

var dialogs_end = [
	"Candidate " + str(candidate_id) + " made it.",
	"Time has been recorded.",
	"It is the best performance in epoch " + str(epoch) + ".",
	"Candidate " + str(candidate_id) + " will now be recycled and prepared for next epoch."
]
