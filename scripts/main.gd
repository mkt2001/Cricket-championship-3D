extends Node2D

# Cricket Championship 3D - 2.5D playable prototype.

const TEAMS: Array[String] = ["CSK", "MI"]
const OVERS_PER_INNINGS: int = 2
const BALLS_PER_OVER: int = 6

var batting_team: String = "CSK"
var bowling_team: String = "MI"
var innings: int = 1
var runs: int = 0
var wickets: int = 0
var legal_balls: int = 0
var target: int = -1
var last_event: String = "TAP A SHOT TO START"

var event_history: Array[String] = []
var commentary_language: String = "Hindi"
var cinematic_mode: bool = false
var game_over: bool = false

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var ball_busy: bool = false
var animation_time: float = 0.0

var ball_pos: Vector2 = Vector2(640, 330)
var ball_start: Vector2 = Vector2(640, 330)
var ball_end: Vector2 = Vector2(640, 330)

var anim_kind: String = "idle"
var anim_duration: float = 0.0
var current_anim: float = 0.0

var toast: String = ""
var toast_timer: float = 0.0
var player_action: String = "ready"
var selected_shot: String = "Drive"
var selected_delivery: String = "Good length"

var sound_on: bool = true
var crowd_on: bool = true
var commentary_on: bool = true

var four_count: int = 0
var six_count: int = 0


func _ready() -> void:
    rng.randomize()
    _setup_background()
    queue_redraw()


func _setup_background() -> void:
    pass


func _process(delta: float) -> void:
    animation_time += delta

    if toast_timer > 0.0:
        toast_timer = maxf(0.0, toast_timer - delta)

    if ball_busy:
        current_anim += delta

        var t: float = clampf(
            current_anim / maxf(anim_duration, 0.01),
            0.0,
            1.0
        )

        if anim_kind == "six":
            ball_pos = _quadratic(
                ball_start,
                Vector2(640, 80),
                ball_end,
                t
            )
        elif anim_kind == "four":
            ball_pos = ball_start.lerp(ball_end, t)
        elif anim_kind == "wicket":
            ball_pos = ball_start.lerp(ball_end, t)
        else:
            ball_pos = _quadratic(
                ball_start,
                Vector2(640, 220),
                ball_end,
                t
            )

        if t >= 1.0:
            ball_busy = false
            _finish_delivery()

    queue_redraw()


func _quadratic(
    a: Vector2,
    control: Vector2,
    b: Vector2,
    t: float
) -> Vector2:
    return (
        a * pow(1.0 - t, 2.0)
        + control * 2.0 * (1.0 - t) * t
        + b * pow(t, 2.0)
    )


func _draw() -> void:
    var size: Vector2 = get_viewport_rect().size

    # Sky
    draw_rect(
        Rect2(Vector2.ZERO, size),
        Color("#071322")
    )

    draw_circle(
        Vector2(1080, 90),
        34,
        Color("#d6e8ff")
    )

    # Stadium lights
    for i in range(12):
        var light_x: float = 40.0 + float(i) * 108.0

        draw_rect(
            Rect2(light_x, 130, 66, 5),
            Color(0.7, 0.85, 1.0, 0.8)
        )

        draw_circle(
            Vector2(light_x + 33.0, 142),
            16,
            Color(0.75, 0.9, 1.0, 0.07)
        )

    # Stands
    draw_rect(
        Rect2(0, 170, size.x, 160),
        Color("#172b3b")
    )

    var palette: Array[Color] = [
        Color("#ffcb66"),
        Color("#42d9cb"),
        Color("#e66b83"),
        Color("#d5e4f0")
    ]

    for row in range(5):
        for col in range(64):
            var crowd_x: float = (
                float(col) * 21.0
                + float(row % 2) * 10.0
            )

            var crowd_y: float = 185.0 + float(row) * 25.0

            var palette_index: int = (
                (col + row) % palette.size()
            )

            draw_circle(
                Vector2(crowd_x, crowd_y),
                2.5,
                palette[palette_index]
            )

    # Outfield
    draw_rect(
        Rect2(0, 330, size.x, size.y - 330),
        Color("#176b49")
    )

    draw_circle(
        Vector2(640, 560),
        250,
        Color("#218257")
    )

    draw_circle(
        Vector2(640, 560),
        180,
        Color("#2b915f")
    )

    # Pitch
    draw_rect(
        Rect2(560, 355, 160, 300),
        Color("#bca078")
    )

    draw_rect(
        Rect2(570, 355, 140, 300),
        Color("#d1b58b")
    )

    # Creases
    draw_line(
        Vector2(575, 420),
        Vector2(705, 420),
        Color.WHITE,
        3.0
    )

    draw_line(
        Vector2(575, 620),
        Vector2(705, 620),
        Color.WHITE,
        3.0
    )

    # Stumps
    for stump_x in [625, 640, 655]:
        draw_line(
            Vector2(stump_x, 410),
            Vector2(stump_x, 430),
            Color("#f5f3e7"),
            4.0
        )

        draw_line(
            Vector2(stump_x, 610),
            Vector2(stump_x, 630),
            Color("#f5f3e7"),
            4.0
        )

    # Bowler and batter
    _draw_player(
        Vector2(640, 385),
        Color("#3b82f6"),
        "BOWLER"
    )

    var batter_color: Color = (
        Color("#f1c40f")
        if batting_team == "CSK"
        else Color("#2563eb")
    )

    _draw_player(
        Vector2(640, 585),
        batter_color,
        "BATTER"
    )

    # Umpire
    _draw_umpire(Vector2(760, 505))

    # Ball
    if ball_busy:
        draw_circle(
            ball_pos,
            10,
            Color("#ff6347")
        )

        draw_circle(
            ball_pos,
            4,
            Color.WHITE
        )

    # Scoreboard
    _draw_hud(size)


func _draw_player(
    center: Vector2,
    jersey: Color,
    label: String
) -> void:
    # Shadow
    draw_circle(
        center + Vector2(0, 18),
        25,
        Color(0, 0, 0, 0.22)
    )

    # Body
    draw_rect(
        Rect2(
            center.x - 18,
            center.y - 4,
            36,
            58
        ),
        jersey,
        true
    )

    # Head
    draw_circle(
        center + Vector2(0, -19),
        18,
        Color("#b9815a")
    )

    # Hair
    draw_arc(
        center + Vector2(0, -19),
        19,
        PI,
        TAU,
        24,
        Color("#151d2b"),
        6.0
    )

    # Arms
    draw_line(
        center + Vector2(-12, 15),
        center + Vector2(-28, 38),
        Color("#b9815a"),
        8.0
    )

    draw_line(
        center + Vector2(12, 15),
        center + Vector2(25, 33),
        Color("#b9815a"),
        8.0
    )

    # Legs
    draw_line(
        center + Vector2(-8, 54),
        center + Vector2(-12, 78),
        Color("#e9edf3"),
        9.0
    )

    draw_line(
        center + Vector2(8, 54),
        center + Vector2(12, 78),
        Color("#e9edf3"),
        9.0
    )


func _draw_umpire(center: Vector2) -> void:
    draw_circle(
        center + Vector2(0, -19),
        12,
        Color("#b9815a")
    )

    draw_rect(
        Rect2(
            center.x - 13,
            center.y - 7,
            26,
            42
        ),
        Color("#111827")
    )

    if last_event.begins_with("FOUR"):
        draw_line(
            center + Vector2(-10, 0),
            center + Vector2(-30, -22),
            Color("#b9815a"),
            7.0
        )

        draw_line(
            center + Vector2(10, 0),
            center + Vector2(30, -22),
            Color("#b9815a"),
            7.0
        )

    elif last_event.begins_with("SIX"):
        draw_line(
            center + Vector2(-10, 0),
            center + Vector2(-23, -35),
            Color("#b9815a"),
            7.0
        )

        draw_line(
            center + Vector2(10, 0),
            center + Vector2(23, -35),
            Color("#b9815a"),
            7.0
        )

    elif last_event.begins_with("WICKET"):
        draw_line(
            center + Vector2(10, 0),
            center + Vector2(29, -28),
            Color("#b9815a"),
            7.0
        )

    else:
        draw_line(
            center + Vector2(-10, 0),
            center + Vector2(-18, 25),
            Color("#b9815a"),
            7.0
        )

        draw_line(
            center + Vector2(10, 0),
            center + Vector2(18, 25),
            Color("#b9815a"),
            7.0
        )


func _draw_hud(size: Vector2) -> void:
    var font: Font = ThemeDB.fallback_font

    # Top scoreboard
    draw_rect(
        Rect2(18, 18, size.x - 36, 105),
        Color(0.02, 0.04, 0.08, 0.91),
        true,
        12.0
    )

    draw_string(
        font,
        Vector2(38, 48),
        "CRICKET CHAMPIONS 3D  -  DEMO",
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        18,
        Color("#70f0c5")
    )

    draw_string(
        font,
        Vector2(38, 84),
        "%s  %d/%d" % [batting_team, runs, wickets],
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        30,
        Color.WHITE
    )

    draw_string(
        font,
        Vector2(330, 82),
        "OVERS  %d.%d" % [
            int(legal_balls / BALLS_PER_OVER),
            legal_balls % BALLS_PER_OVER
        ],
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        20,
        Color("#d5e4f0")
    )

    var target_text: String = (
        str(target) if target > 0 else "-"
    )

    draw_string(
        font,
        Vector2(570, 82),
        "TARGET  %s" % target_text,
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        20,
        Color("#d5e4f0")
    )

    draw_string(
        font,
        Vector2(810, 82),
        "BATTING: %s" % batting_team,
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        18,
        Color("#ffce67")
    )

    # Bottom information panel
    draw_rect(
        Rect2(18, size.y - 116, size.x - 36, 96),
        Color(0.02, 0.04, 0.08, 0.92),
        true,
        12.0
    )

    draw_string(
        font,
        Vector2(38, size.y - 82),
        last_event,
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        22,
        Color("#ffce67")
    )

    var commentary: String = _commentary_for(last_event)

    draw_string(
        font,
        Vector2(38, size.y - 50),
        commentary,
        HORIZONTAL_ALIGNMENT_LEFT,
        size.x - 80,
        17,
        Color.WHITE
    )

    draw_string(
        font,
        Vector2(38, size.y - 26),
        "SHOT: %s  |  DELIVERY: %s  |  MODE: %s" % [
            selected_shot,
            selected_delivery,
            "CINEMATIC" if cinematic_mode else "PLAY"
        ],
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        14,
        Color("#9fb4c8")
    )


func _commentary_for(event: String) -> String:
    var hindi: Dictionary = {
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

    var english: Dictionary = {
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

    var key: String = event

    for k in hindi.keys():
        var event_key: String = str(k)

        if event.begins_with(event_key):
            key = event_key
            break

    if commentary_language == "English":
        return str(english.get(key, "Play continues."))

    return str(hindi.get(key, "खेल जारी है।"))


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_1:
                play_delivery("DOT")
            KEY_2:
                play_delivery("SINGLE")
            KEY_3:
                play_delivery("DOUBLE")
            KEY_4:
                play_delivery("FOUR")
            KEY_5:
                play_delivery("SIX")
            KEY_6:
                play_delivery("WICKET")
            KEY_H:
                commentary_language = "Hindi"
            KEY_E:
                commentary_language = "English"
            KEY_C:
                cinematic_mode = not cinematic_mode
            KEY_R:
                reset_match()

    if event is InputEventScreenTouch and event.pressed:
        # Explicit float types fix the previous Godot parse errors.
        var touch_event: InputEventScreenTouch = event
        var x: float = touch_event.position.x
        var y: float = touch_event.position.y
        var viewport_size: Vector2 = get_viewport_rect().size

        if y > viewport_size.y - 150.0:
            if x < 180.0:
                play_delivery("DOT")
            elif x < 360.0:
                play_delivery("SINGLE")
            elif x < 540.0:
                play_delivery("FOUR")
            elif x < 720.0:
                play_delivery("SIX")
            elif x < 900.0:
                play_delivery("WICKET")
            else:
                commentary_language = (
                    "English"
                    if commentary_language == "Hindi"
                    else "Hindi"
                )

        elif y < 130.0 and x > viewport_size.x * 0.7:
            cinematic_mode = not cinematic_mode

        queue_redraw()


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

    var shots: Array[String] = [
        "Drive",
        "Pull",
        "Cut",
        "Defence"
    ]

    selected_shot = shots[rng.randi_range(0, shots.size() - 1)]

    queue_redraw()

    await get_tree().create_timer(0.46).timeout

    if not is_inside_tree():
        return

    ball_busy = false
    _resolve_outcome(outcome)


func _finish_delivery() -> void:
    pass


func _resolve_outcome(outcome: String) -> void:
    if game_over:
        return

    var valid: Array[String] = [
        "DOT",
        "SINGLE",
        "DOUBLE",
        "FOUR",
        "SIX",
        "WICKET",
        "WIDE",
        "NO BALL"
    ]

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

    if (
        legal_balls >= OVERS_PER_INNINGS * BALLS_PER_OVER
        or wickets >= 10
    ):
        if innings == 1:
            target = runs + 1
            innings = 2

            batting_team = (
                "MI" if batting_team == "CSK" else "CSK"
            )

            bowling_team = (
                "MI" if bowling_team == "CSK" else "CSK"
            )

            runs = 0
            wickets = 0
            legal_balls = 0

            last_event = "INNINGS COMPLETE - TARGET %d" % target

        else:
            game_over = true

            if runs >= target:
                last_event = "MATCH WON - CHASE COMPLETE"
            else:
                last_event = "MATCH WON - %s WIN" % bowling_team

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
    ball_busy = false

    current_anim = 0.0
    anim_duration = 0.0

    four_count = 0
    six_count = 0

    queue_redraw()
