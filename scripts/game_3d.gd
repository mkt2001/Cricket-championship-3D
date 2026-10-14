extends Node3D

var broadcast_camera: Camera3D
var player_camera: Camera3D
var active_camera := false

var ball: MeshInstance3D
var status_label: Label
var camera_button: Button
var hit_button: Button

var score := 0
var wickets := 0
var balls := 0
var ball_moving := false
var ball_velocity := Vector3.ZERO

func _ready() -> void:
    print("Cricket 3D: Game starting")

    # Use a solid background so the scene remains visible
    # even if the procedural sky fails to render.
    var world := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#87b8e8")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color.WHITE
    environment.ambient_light_energy = 1.0
    world.environment = environment
    add_child(world)

    var sunlight := DirectionalLight3D.new()
    sunlight.rotation_degrees = Vector3(-50, -25, 0)
    sunlight.light_energy = 1.3
    add_child(sunlight)

    create_field()
    create_pitch()
    create_wickets()
    create_player("Batter", Vector3(0, 0, 6), Color("#f4c542"))
    create_player("Bowler", Vector3(0, 0, -6), Color("#2878e8"))
    create_player("Fielder", Vector3(8, 0, -2), Color("#2878e8"))
    create_ball()
    create_cameras()
    create_ui()

    print("Cricket 3D: Scene created successfully")


func make_box(
    object_name: String,
    box_size: Vector3,
    box_position: Vector3,
    box_color: Color
) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.name = object_name

    var mesh := BoxMesh.new()
    mesh.size = box_size
    instance.mesh = mesh
    instance.position = box_position

    var material := StandardMaterial3D.new()
    material.albedo_color = box_color
    material.roughness = 0.9
    instance.material_override = material

    add_child(instance)
    return instance


func create_field() -> void:
    make_box(
        "GreenGround",
        Vector3(80, 0.5, 100),
        Vector3(0, -0.3, 0),
        Color("#25854b")
    )

    # Visible boundary markers.
    for i in range(32):
        var angle: float = TAU * float(i) / 32.0
        var marker_position := Vector3(
            sin(angle) * 30.0,
            0.03,
            cos(angle) * 40.0
        )

        make_box(
            "BoundaryMarker",
            Vector3(0.7, 0.12, 0.7),
            marker_position,
            Color.WHITE
        )


func create_pitch() -> void:
    make_box(
        "Pitch",
        Vector3(3.5, 0.12, 20),
        Vector3(0, 0.03, 0),
        Color("#c8aa7c")
    )

    make_box(
        "NearCrease",
        Vector3(4, 0.03, 0.15),
        Vector3(0, 0.11, 7),
        Color.WHITE
    )

    make_box(
        "FarCrease",
        Vector3(4, 0.03, 0.15),
        Vector3(0, 0.11, -7),
        Color.WHITE
    )


func create_wickets() -> void:
    for end_z in [-8.0, 8.0]:
        for stump_x in [-0.3, 0.0, 0.3]:
            make_box(
                "Wicket",
                Vector3(0.09, 0.9, 0.09),
                Vector3(stump_x, 0.55, end_z),
                Color("#fff0ce")
            )


func create_player(
    player_name: String,
    player_position: Vector3,
    shirt_color: Color
) -> void:
    var player := Node3D.new()
    player.name = player_name
    player.position = player_position
    add_child(player)

    var body := MeshInstance3D.new()
    var body_mesh := CapsuleMesh.new()
    body_mesh.radius = 0.42
    body_mesh.height = 1.5
    body.mesh = body_mesh
    body.position.y = 1.15

    var shirt := StandardMaterial3D.new()
    shirt.albedo_color = shirt_color
    body.material_override = shirt
    player.add_child(body)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.28
    head_mesh.height = 0.56
    head.mesh = head_mesh
    head.position.y = 2.05

    var skin := StandardMaterial3D.new()
    skin.albedo_color = Color("#bd8967")
    head.material_override = skin
    player.add_child(head)

    # Simple bat for the batter.
    if player_name == "Batter":
        var bat := MeshInstance3D.new()
        var bat_mesh := BoxMesh.new()
        bat_mesh.size = Vector3(0.18, 1.2, 0.12)
        bat.mesh = bat_mesh
        bat.position = Vector3(0.55, 0.8, -0.1)

        var bat_material := StandardMaterial3D.new()
        bat_material.albedo_color = Color("#e6c18a")
        bat.material_override = bat_material
        player.add_child(bat)


func create_ball() -> void:
    ball = MeshInstance3D.new()
    ball.name = "CricketBall"

    var sphere := SphereMesh.new()
    sphere.radius = 0.16
    sphere.height = 0.32
    ball.mesh = sphere

    var material := StandardMaterial3D.new()
    material.albedo_color = Color("#d52626")
    ball.material_override = material

    ball.position = Vector3(0, 0.35, -4)
    add_child(ball)


func create_cameras() -> void:
    broadcast_camera = Camera3D.new()
    broadcast_camera.name = "BroadcastCamera"
    broadcast_camera.position = Vector3(0, 24, 34)
    broadcast_camera.fov = 60
    add_child(broadcast_camera)
    broadcast_camera.look_at(Vector3(0, 0, 0), Vector3.UP)

    player_camera = Camera3D.new()
    player_camera.name = "PlayerCamera"
    player_camera.position = Vector3(0, 4, 13)
    player_camera.fov = 70
    add_child(player_camera)
    player_camera.look_at(Vector3(0, 1, -3), Vector3.UP)

    # Activate the broadcast camera first.
    broadcast_camera.current = true
    player_camera.current = false


func create_ui() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "GameUI"
    add_child(canvas)

    var panel := PanelContainer.new()
    panel.position = Vector2(16, 16)
    panel.custom_minimum_size = Vector2(350, 100)
    canvas.add_child(panel)

    var column := VBoxContainer.new()
    panel.add_child(column)

    status_label = Label.new()
    status_label.text = "CRICKET CHAMPIONSHIP 3D\nRUNS: 0 | WICKETS: 0 | BALLS: 0"
    status_label.add_theme_font_size_override("font_size", 18)
    column.add_child(status_label)

    camera_button = Button.new()
    camera_button.text = "SWITCH CAMERA"
    camera_button.custom_minimum_size = Vector2(180, 55)
    camera_button.anchor_left = 0.0
    camera_button.anchor_right = 0.0
    camera_button.anchor_top = 1.0
    camera_button.anchor_bottom = 1.0
    camera_button.offset_left = 20
    camera_button.offset_right = 200
    camera_button.offset_top = -80
    camera_button.offset_bottom = -20
    camera_button.pressed.connect(switch_camera)
    canvas.add_child(camera_button)

    hit_button = Button.new()
    hit_button.text = "HIT BALL"
    hit_button.custom_minimum_size = Vector2(180, 60)
    hit_button.anchor_left = 1.0
    hit_button.anchor_right = 1.0
    hit_button.anchor_top = 1.0
    hit_button.anchor_bottom = 1.0
    hit_button.offset_left = -200
    hit_button.offset_right = -20
    hit_button.offset_top = -85
    hit_button.offset_bottom = -20
    hit_button.pressed.connect(hit_ball)
    canvas.add_child(hit_button)


func switch_camera() -> void:
    active_camera = not active_camera

    broadcast_camera.current = not active_camera
    player_camera.current = active_camera


func hit_ball() -> void:
    if ball_moving:
        return

    ball_moving = true
    ball.position = Vector3(0, 1, -4)

    ball_velocity = Vector3(
        randf_range(-5.0, 5.0),
        7.0,
        18.0
    )

    score += 1
    balls += 1
    update_scoreboard()


func _process(delta: float) -> void:
    if not ball_moving:
        return

    ball_velocity.y -= 9.8 * delta
    ball.position += ball_velocity * delta

    if ball.position.y <= 0.2:
        ball.position.y = 0.2
        ball_velocity.y = absf(ball_velocity.y) * 0.45
        ball_velocity.x *= 0.8
        ball_velocity.z *= 0.8

    if absf(ball.position.x) > 38 or absf(ball.position.z) > 48:
        ball_moving = false


func update_scoreboard() -> void:
    if is_instance_valid(status_label):
        status_label.text = (
            "CRICKET CHAMPIONSHIP 3D\n"
            + "RUNS: %d | WICKETS: %d | BALLS: %d"
            % [score, wickets, balls]
        )
