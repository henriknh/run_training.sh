extends MarginContainer

@onready var label = $MarginContainer/Label
@onready var timer = $NextLetterTimer
@onready var sound_next_letter = $SoundNextLetter

const MAX_WIDTH = 256

var text = ""
var letter_index = 0

var letter_time = 0.1
var space_time = 0.15
var punctuation_time = 0.2

signal finished_displaying()

# Called when the node enters the scene tree for the first time.
func display_text(_text: String):
	text = _text
	label.text = _text
	
	await resized
	
	custom_minimum_size.x = min(size.x, MAX_WIDTH)
	
	if size.x > MAX_WIDTH:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		await resized # x
		await resized # y
		custom_minimum_size.y = size.y
	
	global_position.x -= size.x / 2
	global_position.y -= size.y + 24

	label.text = ""
	_display_letter()

func _display_letter():
	label.text += text[letter_index]
	sound_next_letter.play()
	
	letter_index += 1
	
	if letter_index >= text.length():
		finished_displaying.emit()
		return
	
	match text[letter_index]:
		"!", ".", ",", "?":
			timer.start(punctuation_time)
		" ":
			timer.start(space_time)
		_:
			timer.start(letter_time)

func _on_next_letter_timer_timeout() -> void:
	_display_letter()
