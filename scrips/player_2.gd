extends CharacterBody2D

# === Movement settings ===
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 600.0
const DASH_DURATION = 0.2

# === State and variables ===
var state = "idle"
var direction := 0
var last_direction := 1
var jumpend_timer := 0.0
var dash_timer := 0.0
var was_on_floor := true

var attack_range_offset_x := 0.0

func _ready():
	attack_range_offset_x = $AttackRange.position.x
	set_state("idle")

func _physics_process(delta):
	handle_input()
	update_state(delta)
	move_and_slide()

# -----------------------------
# 🎮 INPUT HANDLING
# -----------------------------
func handle_input():
	direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		last_direction = direction

# -----------------------------
# 🎞️ STATE MACHINE
# -----------------------------
func set_state(new_state: String):
	if state == new_state:
		return

	state = new_state

	# Disable attack detection by default
	$AttackRange.monitoring = false

	match state:
		"idle":
			$AnimatedSprite2D.play("idle")
		"walk":
			$AnimatedSprite2D.play("walk")
		"jump":
			$AnimatedSprite2D.play("jump")
		"fall":
			$AnimatedSprite2D.play("jump")  # or separate fall anim if you have one
		"land":
			$AnimatedSprite2D.play("idle")
		"attack":
			$AnimatedSprite2D.play("attack")
			$AttackRange.monitoring = true
			velocity.x = 0
		"attack2":
			$AnimatedSprite2D.play("attack2")
			$AttackRange.monitoring = true
			velocity.x = 0
		"dash":
			$AnimatedSprite2D.play("dash")
			velocity.y = 0
			dash_timer = DASH_DURATION

# -----------------------------
# 🔁 STATE UPDATE
# -----------------------------
func update_state(delta):
	var on_floor = is_on_floor()

	# Apply gravity
	if !on_floor:
		velocity += get_gravity() * delta

	# Sprite flip
	$AnimatedSprite2D.flip_h = last_direction < 0
	$AttackRange.position.x = attack_range_offset_x * last_direction

	# === Dash ===
	if state == "dash":
		velocity.x = DASH_SPEED * last_direction
		dash_timer -= delta
		if dash_timer <= 0:
			set_state("idle")
		return

	# === Attacks ===
	if state == "attack" or state == "attack2":
		return  # wait for animation finished

	# === Jump input ===
	if Input.is_action_just_pressed("ui_accept") and on_floor:
		velocity.y = JUMP_VELOCITY
		set_state("jump")
		return

	# === Attack inputs ===
	if Input.is_action_just_pressed("attack") and on_floor:
		set_state("attack")
		return
	elif Input.is_action_just_pressed("attack2") and on_floor:
		set_state("attack2")
		return

	# === Dash input ===
	if Input.is_action_just_pressed("dash"):
		set_state("dash")
		return

	# === Movement ===
	velocity.x = direction * SPEED

	# === State Transitions ===
	if on_floor:
		if direction == 0 and state != "idle":
			set_state("idle")
		elif direction != 0 and state != "walk":
			set_state("walk")
	else:
		if velocity.y < 0 and state != "jump":
			set_state("jump")
		elif velocity.y > 0 and state != "fall":
			set_state("fall")

	was_on_floor = on_floor

# -----------------------------
# 📦 Animation Finished Signal
# -----------------------------
func _on_animated_sprite_2d_animation_finished():
	var current = $AnimatedSprite2D.animation

	if current in ["attack", "attack2"]:
		set_state("idle")
	elif current == "land":
		if direction == 0:
			set_state("idle")
		else:
			set_state("walk")

# -----------------------------
# 💥 Attack Hit Detection
# -----------------------------
func _on_attackrange_body_entered(body: Node):
	if body.is_in_group("enemies"):
		if body.has_method("take_hit"):
			body.take_hit()
