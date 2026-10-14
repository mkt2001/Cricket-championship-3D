extends Node3D

const FIELD_LENGTH: float = 100.0
const FIELD_WIDTH: float = 70.0

var broadcast_camera: Camera3D
var player_camera: Camera3D
var active_camera: String = "broadcast"

var ball: RigidBody3D
var ball_in_play: bool = false

var status_label: Label
var camera_button: Button
var hit_button: Button

var score: int = 0
var wickets: int = 0
var balls: int = 0


func _ready() -> void:
    _create_environment()
    _create_field()
    _create_pitch()
    _create_wickets()
    _create_players()
    _create_ball()
    _create_cameras()
    _create_ui()
    _update_scoreboard()

    player_camera.current = false
    broadcast_camera.current = true


func _create_environment() -> void:
    var world := WorldEnvironment.new()
    var environment := Environment.new()

    environment.background_mode = Environment.BG_SKY
    environment.sky = Sky.new()
    environment.sky.sky_material = ProceduralSkyMaterial.new()
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.65, 0.72, 0.85)
    environment.ambient_light_energy = 0.8

    world.environment = environment
    add_child(world)

    var sunlight := DirectionalLight3D.new()
    sunlight.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
    sunlight.light_energy = 1.2
    sunlight.shadow_enabled = true
    add_child(sunlight)


func _make_box(
    box_name: String,
    box_size: Vector3,
    box_position: Vector3,
    box_color: Color
) -> MeshInstance3D:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = box_name

    var box_mesh := BoxMesh.new()
    box_mesh.size = box_size
    mesh_instance.mesh = box_mesh
    mesh_instance.position = box_position

    var material := StandardMaterial3D.new()
    material.albedo_color = box_color
    material.roughness = 0.85
    mesh_instance.material_override = material

    add_child(mesh_instance)
    return mesh_instance


func _create_field() -> void:
    _make_box(
        "CricketOutfield",
        Vector3(FIELD_WIDTH, 0.5, FIELD_LENGTH),
        Vector3(0.0, -0.35, 0.0),
        Color("#21834e")
    )

    # Simple boundary markers.
    for i in range(24):
        var angle: float = TAU * float(i) / 24.0

        var marker_position := Vector3(
            sin(angle) * 32.0,
            0.0,
            cos(angle) * 42.0
        )

        _make_box(
            "BoundaryMarker",
            Vector3(0.65, 0.15, 0.65),
            marker_position,
            Color("#eeeeee")
        )


func _create_pitch() -> void:
    _make_box(
        "Pitch",
        Vector3(3.2, 0.12, 20.0),
        Vector3(0.0, 0.02, 0.0),
        Color("#c7ad82")
    )

    _make_box(
        "PitchCreaseNear",
        Vector3(4.0, 0.025, 0.12),
        Vector3(0.0, 0.09, 7.0),
        Color.WHITE
    )

    _make_box(
        "PitchCreaseFar",
        Vector3(4.0, 0.025, 0.12),
        Vector3(0.0, 0.09, -7.0),
        Color.WHITE
    )


func _create_wickets() -> void:
    for end_z in [-8.0, 8.0]:
        for stump_x in [-0.35, 0.0, 0.35]:
            _make_box(
                "Stumps",
                Vector3(0.09, 0.9, 0.09),
                Vector3(stump_x, 0.55, end_z),
                Color("#f5e8bd")
            )


func _create_player(
    player_name: String,
    player_position: Vector3,
    shirt_color: Color
) -> void:
    var player := Node3D.new()
    player.name = player_name
    player.position = player_position
    add_child(player)

    var body_mesh := CapsuleMesh.new()
    body_mesh.radius = 0.42
    body_mesh.height = 1.5

    var body := MeshInstance3D.new()
    body.name = "Body"
    body.mesh = body_mesh
    body.position.y = 1.15

    var shirt := StandardMaterial3D.new()
    shirt.albedo_color = shirt_color
    body.material_override = shirt
    player.add_child(body)

    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.28
    head_mesh.height = 0.56

    var head := MeshInstance3D.new()
    head.name = "Head"
    head.mesh = head_mesh
    head.position.y = 2.05

    var skin := StandardMaterial3D.new()
    skin.albedo_color = Color("#bd8967")
    head.material_override = skin
    player.add_child(head)


func _create_players() -> void:
    _create_player(
        "Batter",
        Vector3(0.0, 0.0, 6.0),
        Color("#f4c542")
    )

    _create_player(
        "Bowler",
        Vector3(0.0, 0.0, -6.0),
        Color("#2563eb")
    )

    _create_player(
        "Fielder",
        Vector3(8.0, 0.0, -2.0),
        Color("#2563eb")
    )


func _create_ball() -> void:
    ball = RigidBody3D.new()
    ball.name = "CricketBall"
    ball.position = Vector3(0.0, 0.4, -4.0)
    ball.mass = 0.16
    ball.gravity_scale = 1.0
    ball.freeze = true
    add_child(ball)

    var sphere := SphereMesh.new()
    sphere.radius = 0.12
    sphere.height = 0.24

    var ball_mesh := MeshInstance3D.new()
    ball_mesh.mesh = sphere

    var ball_material := StandardMaterial3D.new()
    ball_material.albedo_color = Color("#c83232")
    ball_material.roughness = 0.4
    ball_mesh.material_override = ball_material
    ball.add_child(ball_mesh)

    var collision := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = 0.12
    collision.shape = shape
    ball.add_child(collision)


func _create_cameras() -> void:
    broadcast_camera = Camera3D.new()
    broadcast_camera.name = "BroadcastCamera"
    broadcast_camera.position = Vector3(0.0, 25.0, 35.0)
    broadcast_camera.fov = 55.0
    add_child(broadcast_camera)
    broadcast_camera.look_at(Vector3.ZERO, Vector3.UP)

    player_camera = Camera3D.new()
    player_camera.name = "PlayerCamera"
    player_camera.position = Vector3(0.0, 4.0, 12.0)
    player_camera.fov = 70.0
    add_child(player_camera)
    player_camera.look_at(Vector3(0.0, 1.0, -4.0), Vector3.UP)


func _create_ui() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "GameUI"
    add_child(canvas)

    var panel := PanelContainer.new()
    panel.position = Vector2(16.0, 16.0)
    panel.size = Vector2(350.0, 90.0)
    canvas.add_child(panel)

    var column := VBoxContainer.new()
    panel.add_child(column)

    status_label = Label.new()
    status_label.text = "CRICKET CHAMPIONSHIP 3D"
    status_label.add_theme_font_size_override("font_size", 20)
    column.add_child(status_label)

    camera_button = Button.new()
    camera_button.text = "Switch Camera"
    camera_button.custom_minimum_size = Vector2(160.0, 55.0)
    camera_button.pressed.connect(_switch_camera)
    canvas.add_child(camera_button)

    hit_button = Button.new()
    hit_button.text = "HIT BALL"
    hit_button.custom_minimum_size = Vector2(160.0, 65.0)
    hit_button.pressed.connect(_hit_ball)
    canvas.add_child(hit_button)

    camera_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    camera_button.position = Vector2(20.0, -85.0)

    hit_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    hit_button.position = Vector2(-180.0, -95.0)


func _switch_camera() -> void:
    if active_camera == "broadcast":
        active_camera = "player"
        broadcast_camera.current = false
        player_camera.current = true
    else:
        active_camera = "broadcast"
        player_camera.current = false
        broadcast_camera.current = true


func _hit_ball() -> void:
    if ball_in_play:
        return

    ball_in_play = true
    ball.freeze = false
    ball.sleeping = false
    ball.global_position = Vector3(0.0, 1.0, -4.0)
    ball.linear_velocity = Vector3(
        randf_range(-3.0, 3.0),
        5.0,
        16.0
    )

    score += 1
    balls += 1

    _update_scoreboard()


func _update_scoreboard() -> void:
    if is_instance_valid(status_label):
        status_label.text = (
            "CRICKET CHAMPIONSHIP 3D\n"
            + "RUNS: %d   WICKETS: %d   BALLS: %d"
            % [score, wickets, balls]
        )
