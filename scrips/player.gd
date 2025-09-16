extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var state = "idle"
var direction := 0
var last_direction := 1  # 1 = right (default), -1 = left
var jumpend_timer := 0.0
var was_on_floor := true  # Track previous frame's floor status

func _ready():
	set_state("idle")

func _physics_process(delta):
	handle_input()
	update_state(delta)
	move_and_slide()

# -----------------------------
# 🧠 INPUT HANDLING
# -----------------------------
func handle_input():
	@warning_ignore("narrowing_conversion")
	direction = Input.get_axis("ui_left", "ui_right")

	# Update last_direction only when moving left or right
	if direction != 0:
		last_direction = direction

# -----------------------------
# 🎮 STATE MACHINE
# -----------------------------
func set_state(new_state: String):
	if state == new_state:
		return

	state = new_state

	match state:
		"idle":
			$AnimatedSprite2D.play("idle")
		"walk":
			$AnimatedSprite2D.play("walk")
		"jump_start":
			$AnimatedSprite2D.play("jumpstart")
		"jump_end":
			$AnimatedSprite2D.play("jumpend")
			jumpend_timer = 0.3  # or use get_animation_length("jumpend")
		"attack":
			$AnimatedSprite2D.play("attack")
		"fall":
			$AnimatedSprite2D.play("fall")
		"land":
			$AnimatedSprite2D.play("land")

# -----------------------------
# 🔁 STATE UPDATE
# -----------------------------
func update_state(delta):
	var on_floor = is_on_floor()

	# Gravity
	if not on_floor:
		velocity += get_gravity() * delta

	# Detect landing event (was in air, now on floor)
	if not was_on_floor and on_floor and state != "land":
		set_state("land")

	# Attack input
	if Input.is_action_just_pressed("attack") and state != "attack" and on_floor:
		set_state("attack")
		return

	# Handle attack animation finish
	if state == "attack":
		return  # wait for animation finished

	# Jumping
	if Input.is_action_just_pressed("ui_accept") and on_floor:
		velocity.y = JUMP_VELOCITY
		set_state("jump_start")
		return

	# Movement
	velocity.x = direction * SPEED

	# Flip sprite based on last_direction instead of current direction
	$AnimatedSprite2D.flip_h = last_direction < 0

	if on_floor:
		if jumpend_timer > 0:
			jumpend_timer -= delta
			return  # let jumpend finish

		if direction == 0 and state != "idle" and state != "land":
			set_state("idle")
		elif direction != 0 and state != "walk":
			set_state("walk")
	else:
		if velocity.y < 0 and state != "jump_start":
			set_state("jump_start")
		elif velocity.y > 0 and state != "fall":
			set_state("fall")

	was_on_floor = on_floor  # Update for next frame

# -----------------------------
# 📦 Animation Finish Callback
# -----------------------------
func _on_animated_sprite_2d_animation_finished():
	var current = $AnimatedSprite2D.animation
	if current == "attack":
		set_state("idle")
	elif current == "land":
		# After landing animation, transition to idle or walk depending on input
		if direction == 0:
			set_state("idle")
		else:
			set_state("walk")

# Optional: Auto calculate animation length (for jumpend)
func get_animation_length(anim_name: String) -> float:
	if not $AnimatedSprite2D.frames:
		return 0.0
	var frame_count = $AnimatedSprite2D.frames.get_frame_count(anim_name)
	var fps = $AnimatedSprite2D.frames.get_animation_speed(anim_name)
	return frame_count / float(fps) if fps != 0 else 0.0
