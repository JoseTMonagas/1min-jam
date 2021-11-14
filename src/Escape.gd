extends Node

# "Horror, Violin Tremolo Cluster, B.wav" by InspectorJ (www.jshaw.co.uk) of Freesound.org

# Defines the states constant allowed, each defines a different operation of
# the game.
# NONE: The initial state, where the player must select a key using
# left and arrow key buttons, and enter, once selected moves to FITTING.
# FITTING: The player is checking if the selected key "fits" the lock
# use the up and down arrow key buttons to try and fit the key to the lock,
# if the key fits then moves on to ROTATING, otherwise goes back to NONE.
# ROTATING: The player is checking if the key rotates the cylinder using the
# left and right arrow key buttons, if it rotates moves on to UNLOCKING,
# otherwise goes back to NONE.
# UNLOCKING: The player is trying to unlock the door, they must press the
# left, up and right arrow key button, in order and in quick succession, to 
# unlock the door, once unlocked moves on to OPENING.
# OPENING: The door is stuck, so the player must repeatedly press the Enter
# key button to unstuck it and open it.
# 
# If the GameOverTimer reaches 0 before the user passes the OPENING state
# then a game over ensues, even if the player reached the OPENING state itself.
enum STATES {NONE, FITTING, ROTATING, UNLOCKING, OPENING}

const NONE_SFX = preload("res://assets/audio/563519__gdog1622__keys-metalretrieve-trimmed-01.wav")
const FITTING_ROTATING_SFX = preload("res://assets/audio/334993__paulocorona__keys-moving.wav")
const UNLOCKING_SFX = preload("res://assets/audio/131438__skydran__keys-on-door-and-open.wav")
const OPENING_SFX = preload("res://assets/audio/550427__danielthebanana4__banging-on-door.mp3")


# Defines how much should the keys be pressed before moving on to the next state
export var ACTION_LIMIT: int = 20

# How many keys were generated for the current game session (0 based)
var keys_amount: int = 4
# The index from 0 to keys_amount of the correct_key
var correct_key: int = -1
# The currently selected key, set during the NONE state
var selected_key: int = -1 setget _set_selected_key

# Stores the last key inputted by the user during certain states
var last_action_pressed: InputEventKey = null

# The current state of the game session
var state: int = STATES.NONE setget _set_state

# Functions like a gauge that must reach ACTION_LIMIT for the user to progress
# to the next state.
var action_counter: int = 0

onready var selecting_key: AnimatedSprite = $SelectingKeys
onready var top_text: Label = $HUD/VBoxContainer/TopText
onready var bottom_text: Label = $HUD/VBoxContainer/BottomText
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var audio_player: AudioStreamPlayer = $SFX

onready var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	correct_key = rng.randi_range(0, keys_amount)
	self.selected_key = 0
	var text: String = "There are %s keys, pick which one to try (%s):" % [keys_amount, correct_key]
	top_text.text = text
	self.state = STATES.NONE
	$EscalationSFX.play()


func _unhandled_key_input(event: InputEventKey) -> void:
	match(state):
		STATES.NONE:
			$SelectingKeys.visible = true
			_state_selecting_key(event)
		STATES.FITTING:
			_state_fitting_key(event)
		STATES.ROTATING:
			_state_rotating_key(event)
		STATES.UNLOCKING:
			_state_unlocking_door(event)
		STATES.OPENING:
			_state_opening_door(event)


func _set_selected_key(value: int) -> int:
	# Selected key setter used mostly to update the label despicting the
	# the currently selected key
	# TODO show using VFX which key is being selected instead of a label
	selected_key = value
	selecting_key.frame = selected_key
	var text: String = "Currently selected key %s" % selected_key
	bottom_text.text = text
	return selected_key

func _set_state(value: int) -> int:
	# State setter that resets the action counter for the next state and
	# plays the according animation.
	# TODO Add extra VFX and SFX to each state progress
	state = value
	action_counter = 0
	$WhimperSFX.play()
	match(state):
		STATES.NONE:
			animation_player.play("NONE")
			audio_player.stream = NONE_SFX
			audio_player.play()
		STATES.FITTING:
			animation_player.play("FITTING")
			audio_player.stream = FITTING_ROTATING_SFX
			audio_player.play()
		STATES.ROTATING:
			animation_player.play("ROTATING")
			audio_player.stream = FITTING_ROTATING_SFX
			audio_player.play()
		STATES.UNLOCKING:
			animation_player.play("UNLOCKING")
			audio_player.stream = UNLOCKING_SFX
			audio_player.play()
		STATES.OPENING:
			animation_player.play("OPENING")
			audio_player.stream = OPENING_SFX
			audio_player.play()
	return state


func _state_selecting_key(event: InputEventKey) -> void:
	# Defines how to react to key events during the NONE state
	if event.is_action_pressed("ui_left"):
		animation_player.play("RtLOUT")
		yield(animation_player, "animation_finished")
		self.selected_key = clamp(selected_key - 1, 0, selected_key)
		animation_player.play("RtLIN")
		yield(animation_player, "animation_finished")
		
	if event.is_action_pressed("ui_right"):
		animation_player.play("LtROUT")
		yield(animation_player, "animation_finished")
		self.selected_key = clamp(selected_key + 1, selected_key, keys_amount)
		animation_player.play("LtRIN")
		yield(animation_player, "animation_finished")
		
	if event.is_action_pressed("ui_accept"):  
		self.state = STATES.FITTING         


func _state_fitting_key(event: InputEventKey) -> void:
	# Defines how to react to key events during the FITTING state
	# The user must press up and down alternatively until `action_counter`
	# reaches `ACTION_LIMIT`
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
			var it_fits: bool = bool(rng.randf() < 1 - 0.5)
			if it_fits:
				bottom_text.text = "It fits!"
				self.state = STATES.ROTATING
			else:
				bottom_text.text = "It doesn't fit!"
				self.state = STATES.NONE


func _state_rotating_key(event: InputEventKey) -> void:
	# Defines how to react to key events during the ROTATING state
	# The user must press left and right alternatively until `action_counter`
	# reaches `ACTION_LIMIT`
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
	# Defines how to react to key events during the UNLOCKING state
	# The user must press left, up, and right in quick sequence for
	# `action_counter` to reach `ACTION_LIMIT`
	if event.is_action_pressed("ui_down"):
		action_counter += 1
	if event.is_action_pressed("ui_left"):
		action_counter += 1
	if event.is_action_pressed("ui_right"):
		action_counter += 1
	if event.is_action_pressed("ui_up"):
		action_counter += 1
	
	last_action_pressed = event
	
	if action_counter >= ACTION_LIMIT:
		bottom_text.text = "The door is stuck, push it!! Quick!!!"
		self.state = STATES.OPENING

func _state_opening_door(event: InputEventKey) -> void:
	# Defines how to react to key events during the OPENING state
	# The user must repeatedly press Enter until `action_counter`
	# reaches `ACTION_LIMIT`
	if event.is_action_pressed("ui_accept"):
		action_counter += 1
	
	last_action_pressed = event
	if action_counter >= ACTION_LIMIT:
		bottom_text.text = "You escaped!"


func _on_GameOverTimer_timeout():
	bottom_text.text = "Marico el que lo lea"
	queue_free()


func _on_EscalationSFX_finished():
	$DeathSFX.play()
