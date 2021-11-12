extends Node

enum STATES {NONE, FITTING, ROTATING, UNLOCKING, OPENING}

export var ACTION_LIMIT: int = 20
export var MIN_KEY_AMOUNT: int = 5
export var MAX_KEY_AMOUNT: int = 16

var keys_amount: int = -1
var correct_key: int = -1
var selected_key: int = -1 setget _set_selected_key
var last_action_pressed: InputEventKey = null
var state: int = STATES.NONE setget _set_state
var action_counter: int = 0

onready var top_text: Label = $HUD/VBoxContainer/TopText
onready var bottom_text: Label = $HUD/VBoxContainer/BottomText
onready var up_icon: TextureRect = $HUD/VBoxContainer/Up
onready var down_icon: TextureRect = $HUD/VBoxContainer/Down
onready var left_icon: TextureRect = $HUD/VBoxContainer/HBoxContainer/Left
onready var right_icon: TextureRect = $HUD/VBoxContainer/HBoxContainer/Right

func _ready() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	keys_amount = rng.randi_range(MIN_KEY_AMOUNT, MAX_KEY_AMOUNT)
	correct_key = rng.randi_range(0, keys_amount)
	self.selected_key = 0
	var text: String = "There are %s keys, pick which one to try (%s):" % [keys_amount, correct_key]
	top_text.text = text


func _unhandled_key_input(event: InputEventKey) -> void:
	if state == STATES.NONE:
		_state_selecting_key(event)
	if state == STATES.FITTING:
		_state_fitting_key(event)
	if state == STATES.ROTATING:
		_state_rotating_key(event)
	if state == STATES.UNLOCKING:
		_state_unlocking_door(event)
	if state == STATES.OPENING:
		_state_opening_door(event)


func _physics_process(delta: float) -> void:
	var key = last_action_pressed.as_text() if last_action_pressed != null else ""
	var text: String = ("Current State: {state}\nAction Counter: {counter}\nLast Pressed Key: {key}".format({ "state": state, "counter": action_counter, "key": key}))
	$HUD/VBoxContainer/DebugText.text = text


func _set_selected_key(value: int) -> int:
	selected_key = value
	var text: String = "Currently selected key %s" % selected_key
	bottom_text.text = text
	return selected_key

func _set_state(value: int) -> int:
	state = value
	action_counter = 0
	return state


func _state_selecting_key(event: InputEventKey) -> void:
	if event.is_action_pressed("ui_left"):
		self.selected_key = clamp(selected_key - 1, 0, selected_key)
	if event.is_action_pressed("ui_right"):
		self.selected_key = clamp(selected_key + 1, selected_key, keys_amount)
	if event.is_action_pressed("ui_accept"):
		self.state = STATES.FITTING


func _state_fitting_key(event: InputEventKey) -> void:
	if event.is_action_pressed("ui_up"):
		if last_action_pressed.is_action_pressed("ui_down"):
			action_counter += 1
	if event.is_action_pressed("ui_down"):
		if last_action_pressed.is_action_pressed("ui_up"):
			action_counter += 1
	
	last_action_pressed = event
	if action_counter >= ACTION_LIMIT:
		if selected_key == correct_key:
			bottom_text.text = "It fits!"
			self.state = STATES.ROTATING
		else:
			bottom_text.text = "It doesn't fit!"
			self.state = STATES.NONE


func _state_rotating_key(event: InputEventKey) -> void:
	if event.is_action_pressed("ui_left"):
		if last_action_pressed.is_action_pressed("ui_right"):
			action_counter += 1
	if event.is_action_pressed("ui_right"):
		if last_action_pressed.is_action_pressed("ui_left"):
			action_counter += 1
	
	last_action_pressed = event
	if action_counter >= ACTION_LIMIT:
		if selected_key == correct_key:
			bottom_text.text = "This is the key!"
			self.state = STATES.UNLOCKING
		else:
			bottom_text.text = "It doesn't unlock!"
			self.state = STATES.NONE

func _state_unlocking_door(event: InputEventKey) -> void:
	if event.is_action_pressed("ui_up"):
		if last_action_pressed.is_action_pressed("ui_left"):
			action_counter += 10
		else:
			action_counter = 0
	
	if event.is_action_pressed("ui_right"):
		if last_action_pressed.is_action_pressed("ui_up"):
			action_counter += 10
		else:
			action_counter = 0
	
	last_action_pressed = event
	if action_counter >= ACTION_LIMIT:
		bottom_text.text = "The door is stuck, push it!! Quick!!!"
		self.state = STATES.OPENING

func _state_opening_door(event: InputEventKey) -> void:
	if event.is_action_pressed("ui_accept"):
		action_counter += 1
	
	last_action_pressed = event
	if action_counter >= ACTION_LIMIT:
		bottom_text.text = "You escaped!"


func _on_GameOverTimer_timeout():
	bottom_text.text = "Marico el que lo lea"
	queue_free()
