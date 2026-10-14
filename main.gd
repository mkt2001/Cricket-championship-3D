extends Node2D

# Cricket Championship 3D — 2.5D playable prototype.
# This starter uses procedural visuals so it runs without third-party assets.
# Replace procedural players/stadium with licensed 3D assets in the full production phase.

const TEAMS := ["CSK", "MI"]
const OVERS_PER_INNINGS := 2 # Short demo match; expand in Match Settings later.
const BALLS_PER_OVER := 6

var batting_team := "CSK"
var bowling_team := "MI"
var innings := 1
var runs := 0
var wickets := 0
var legal_balls := 0
var target := -1
var last_event := "TAP A SHOT TO START"
var event_history: Array[String] = []
var commentary_language := "Hindi"
var cinematic_mode := false
var game_over := false
var rng := RandomNumberGenerator.new()
var ball_busy := false
var animation_time := 0.0
var ball_pos := Vector2(640, 330)
var ball_start := Vector2(640, 330)
var ball_end := Vector2(640, 330)
var anim_kind := "idle"
var anim_duration := 0.0
var current_anim := 0.0
var toast := ""
var toast_timer := 0.0
var player_action := "ready"
var selected_shot := "Drive"
var selected_delivery := "Good length"
var sound_on := true
var crowd_on := true
var commentary_on := true
var four_count := 0
var six_count := 0

func _ready() -> void:
    rng.randomize()
    _setup_background()
    queue_redraw()

func _setup_background() -> void:
    pass

func _process(delta: float) -> void:
    animation_time += delta
    if toast_timer > 0:
        toast_timer -= delta
    if ball_busy:
        current_anim += delta
        var t := clampf(current_anim / maxf(anim_duration, 0.01), 0.0, 1.0)
        if anim_kind == "six":
            ball_pos = _quadratic(ball_start, Vector2(640, 80), ball_end, t)
        elif anim_kind == "four":
            ball_pos = ball_start.lerp(ball_end, t)
        elif anim_kind == "wicket":
            ball_pos = ball_start.lerp(ball_end, t)
        else:
            ball_pos = _quadratic(ball_start, Vector2(640, 220), ball_end, t)
        if t >= 1.0:
            ball_busy = false
            _finish_delivery()
    queue_redraw()

func _quadratic(a: Vector2, control: Vector2, b: Vector2, t: float) -> Vector2:
    return a * pow(1.0 - t, 2.0) + control * 2.0 * (1.0 - t) * t + b * pow(t, 2.0)

func _draw() -> void:
    var size := get_viewport_rect().size
    # Sky and stadium
    draw_rect(Rect2(Vector2.ZERO, size), Color("#071322"))
    draw_circle(Vector2(1080, 90), 34, Color("#d6e8ff"))
    for i in range(12):
        var x := 40 + i * 108
        draw_rect(Rect2(x, 130, 66, 5), Color(0.7, 0.85, 1.0, 0.8))
        draw_circle(Vector2(x + 33, 142), 16, Color(0.75, 0.9, 1.0, 0.07))
    # Stands
    draw_rect(Rect2(0, 170, size.x, 160), Color("#172b3b"))
    for row in range(5):
        for col in range(64):
            var x := col * 21 + (row % 2) * 10
            var y := 185 + row * 25
            var palette := [Color("#ffcb66"), Color("#42d9cb"), Color("#e66b83"), Color("#d5e4f0")]
            draw_circle(Vector2(x, y), 2.5, palette[(col + row) % palette.size()])
    # Outfield and pitch
    draw_rect(Rect2(0, 330, size.x, size.y - 330), Color("#176b49"))
    draw_circle(Vector2(640, 560), 250, Color("#218257"))
    draw_circle(Vector2(640, 560), 180, Color("#2b915f"))
    draw_rect(Rect2(560, 355, 160, 300), Color("#bca078"))
    draw_rect(Rect2(570, 355, 140, 300), Color("#d1b58b"))
    # Creases and stumps
    draw_line(Vector2(575, 420), Vector2(705, 420), Color.WHITE, 3)
    draw_line(Vector2(575, 620), Vector2(705, 620), Color.WHITE, 3)
    for x in [625, 640, 655]:
        draw_line(Vector2(x, 410), Vector2(x, 430), Color("#f5f3e7"), 4)
        draw_line(Vector2(x, 610), Vector2(x, 630), Color("#f5f3e7"), 4)
    # Bowler and batter stylized procedural avatars
    _draw_player(Vector2(640, 385), Color("#3b82f6"), "BOWLER")
    _draw_player(Vector2(640, 585), Color("#f1c40f") if batting_team == "CSK" else Color("#2563eb"), "BATTER")
    # Umpire
    _draw_umpire(Vector2(760, 505))
    # Ball
    if ball_busy:
        draw_circle(ball_pos, 10, Color("#ff6347"))
        draw_circle(ball_pos, 4, Color("#ffffff"))
    # HUD
    _draw_hud(size)

func _draw_player(center: Vector2, jersey: Color, label: String) -> void:
    draw_circle(center + Vector2(0, 18), 25, Color(0, 0, 0, 0.22))
    draw_rect(Rect2(center.x - 18, center.y - 4, 36, 58), jersey, true)
    draw_circle(center + Vector2(0, -19), 18, Color("#b9815a"))
    draw_arc(center + Vector2(0, -19), 19, PI, TAU, 24, Color("#151d2b"), 6)
    draw_line(center + Vector2(-12, 15), center + Vector2(-28, 38), Color("#b9815a"), 8)
    draw_line(center + Vector2(12, 15), center + Vector2(25, 33), Color("#b9815a"), 8)
    draw_line(center + Vector2(-8, 54), center + Vector2(-12, 78), Color("#e9edf3"), 9)
    draw_line(center + Vector2(8, 54), center + Vector2(12, 78), Color("#e9edf3"), 9)

func _draw_umpire(center: Vector2) -> void:
    draw_circle(center + Vector2(0, -19), 12, Color("#b9815a"))
    draw_rect(Rect2(center.x - 13, center.y - 7, 26, 42), Color("#111827"))
    if last_event.begins_with("FOUR"):
        draw_line(center + Vector2(-10, 0), center + Vector2(-30, -22), Color("#b9815a"), 7)
        draw_line(center + Vector2(10, 0), center + Vector2(30, -22), Color("#b9815a"), 7)
    elif last_event.begins_with("SIX"):
        draw_line(center + Vector2(-10, 0), center + Vector2(-23, -35), Color("#b9815a"), 7)
        draw_line(center + Vector2(10, 0), center + Vector2(23, -35), Color("#b9815a"), 7)
    elif last_event.begins_with("WICKET"):
        draw_line(center + Vector2(10, 0), center + Vector2(29, -28), Color("#b9815a"), 7)
    else:
        draw_line(center + Vector2(-10, 0), center + Vector2(-18, 25), Color("#b9815a"), 7)
        draw_line(center + Vector2(10, 0), center + Vector2(18, 25), Color("#b9815a"), 7)

func _draw_hud(size: Vector2) -> void:
    draw_rect(Rect2(18, 18, size.x - 36, 105), Color(0.02, 0.04, 0.08, 0.91), true, 12)
    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(38, 48), "CRICKET CHAMPIONS 3D  •  DEMO", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#70f0c5"))
    draw_string(font, Vector2(38, 84), "%s  %d/%d" % [batting_team, runs, wickets], HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
    draw_string(font, Vector2(330, 82), "OVERS  %d.%d" % [int(legal_balls / 6), legal_balls % 6], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#d5e4f0"))
    draw_string(font, Vector2(570, 82), "TARGET  %s" % (str(target) if target > 0 else "—"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#d5e4f0"))
    draw_string(font, Vector2(810, 82), "BATTING: %s" % batting_team, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffce67"))
    draw_rect(Rect2(18, size.y - 116, size.x - 36, 96), Color(0.02, 0.04, 0.08, 0.92), true, 12)
    draw_string(font, Vector2(38, size.y - 82), last_event, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#ffce67"))
    var commentary := _commentary_for(last_event)
    draw_string(font, Vector2(38, size.y - 50), commentary, HORIZONTAL_ALIGNMENT_LEFT, size.x - 80, 17, Color.WHITE)
    draw_string(font, Vector2(38, size.y - 26), "SHOT: %s   |   DELIVERY: %s   |   MODE: %s" % [selected_shot, selected_delivery, "CINEMATIC" if cinematic_mode else "PLAY"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#9fb4c8"))

func _commentary_for(event: String) -> String:
    var hindi := {
        "FOUR": "शानदार शॉट! गेंद बाउंड्री के पार — चार रन!",
        "SIX": "क्या शानदार छक्का! गेंद दर्शकों के बीच!",
        "WICKET": "आउट! बल्लेबाज को वापस जाना होगा!",
        "DOT": "अच्छी गेंद, कोई रन नहीं।",
        "SINGLE": "एक रन लिया गया।",
        "DOUBLE": "दो रन पूरे!",
        "START": "अगली गेंद के लिए तैयार हो जाइए।",
        "OVER": "ओवर समाप्त। अगला ओवर शुरू होगा।",
        "WIDE": "वाइड गेंद, अतिरिक्त रन।",
        "NO BALL": "नो-बॉल! बल्लेबाजी टीम को अतिरिक्त रन।"
    }
    var english := {
        "FOUR": "What a shot! It races away for four!",
        "SIX": "That's massive! Six runs into the crowd!",
        "WICKET": "OUT! The batter has to walk back.",
        "DOT": "Good delivery, no run.",
        "SINGLE": "They take a quick single.",
        "DOUBLE": "Excellent running, two runs.",
        "START": "Get ready for the next delivery.",
        "OVER": "Over complete. Time for the next over.",
        "WIDE": "Wide ball, an extra run.",
        "NO BALL": "No-ball called. An extra run."
    }
    var key := event
    for k in hindi.keys():
        if event.begins_with(k):
            key = k
            break
    if commentary_language == "English":
        return english.get(key, "Play continues.")
    return hindi.get(key, "खेल जारी है।")

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_1: play_delivery("DOT")
            KEY_2: play_delivery("SINGLE")
            KEY_3: play_delivery("DOUBLE")
            KEY_4: play_delivery("FOUR")
            KEY_5: play_delivery("SIX")
            KEY_6: play_delivery("WICKET")
            KEY_H: commentary_language = "Hindi"
            KEY_E: commentary_language = "English"
            KEY_C: cinematic_mode = not cinematic_mode
            KEY_R: reset_match()
    if event is InputEventScreenTouch and event.pressed:
        var x := event.position.x
        var y := event.position.y
        if y > get_viewport_rect().size.y - 150:
            if x < 180: play_delivery("DOT")
            elif x < 360: play_delivery("SINGLE")
            elif x < 540: play_delivery("FOUR")
            elif x < 720: play_delivery("SIX")
            elif x < 900: play_delivery("WICKET")
            else: commentary_language = "English" if commentary_language == "Hindi" else "Hindi"
        elif y < 130 and x > get_viewport_rect().size.x * 0.7:
            cinematic_mode = not cinematic_mode

func play_delivery(outcome: String) -> void:
    if ball_busy or game_over:
        return
    last_event = "BALL STARTING"
    player_action = "delivery"
    ball_start = Vector2(640, 390)
    ball_end = Vector2(640, 565)
    current_anim = 0.0
    anim_duration = 0.45
    anim_kind = "delivery"
    ball_pos = ball_start
    ball_busy = true
    toast = outcome
    toast_timer = 2.0
    # Outcome is resolved after the ball animation. This prototype uses explicit outcomes for testing.
    selected_shot = ["Drive", "Pull", "Cut", "Defence"][rng.randi_range(0, 3)]
    await get_tree().create_timer(0.46).timeout
    if not is_inside_tree():
        return
    _resolve_outcome(outcome)

func _finish_delivery() -> void:
    pass

func _resolve_outcome(outcome: String) -> void:
    if game_over:
        return
    var valid := ["DOT", "SINGLE", "DOUBLE", "FOUR", "SIX", "WICKET", "WIDE", "NO BALL"]
    if not valid.has(outcome):
        outcome = "DOT"
    if outcome == "WIDE":
        runs += 1
        last_event = "WIDE"
    elif outcome == "NO BALL":
        runs += 1
        last_event = "NO BALL"
    else:
        legal_balls += 1
        match outcome:
            "DOT":
                last_event = "DOT"
            "SINGLE":
                runs += 1
                last_event = "SINGLE"
            "DOUBLE":
                runs += 2
                last_event = "DOUBLE"
            "FOUR":
                runs += 4
                four_count += 1
                last_event = "FOUR! +4 RUNS"
            "SIX":
                runs += 6
                six_count += 1
                last_event = "SIX! +6 RUNS"
            "WICKET":
                wickets += 1
                last_event = "WICKET! OUT"
    event_history.append(last_event)
    if legal_balls >= OVERS_PER_INNINGS * BALLS_PER_OVER or wickets >= 10:
        if innings == 1:
            target = runs + 1
            innings = 2
            batting_team = "MI" if batting_team == "CSK" else "CSK"
            bowling_team = "MI" if bowling_team == "CSK" else "CSK"
            runs = 0
            wickets = 0
            legal_balls = 0
            last_event = "INNINGS COMPLETE — TARGET %d" % target
        else:
            game_over = true
            last_event = "MATCH WON — %s" % ("CHASE COMPLETE" if runs >= target else bowling_team + " WIN")
    queue_redraw()

func reset_match() -> void:
    batting_team = "CSK"
    bowling_team = "MI"
    innings = 1
    runs = 0
    wickets = 0
    legal_balls = 0
    target = -1
    last_event = "TAP A SHOT TO START"
    event_history.clear()
    game_over = false
    four_count = 0
    six_count = 0
    queue_redraw()
