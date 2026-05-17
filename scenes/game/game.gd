extends Node3D

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D     = $light1

var CLUSTERS: Array[Vector2] = [
	Vector2(-120,  20), Vector2(-100, -70), Vector2(-105,  95),
	Vector2( 205,  15), Vector2( 185, -65), Vector2( 195, 115),
	Vector2(  55,-130), Vector2( -15,-110), Vector2( 130,-120),
	Vector2(  45, 200), Vector2( -25, 165), Vector2( 140, 190),
]
const CLUSTER_RADIUS: float = 32.0
const PER_CLUSTER: int      = 4

# Lamp clusters for Midnight Circuit — kept off the road surface
# (road at start: x=0–450, z=-111 to -140)
var MIDNIGHT_LAMP_CLUSTERS: Array[Vector2] = [
	# Outside the outer barrier (z < -155)
	Vector2(  55, -165), Vector2( 130, -165), Vector2( 230, -165),
	Vector2( 330, -165), Vector2( 420, -155), Vector2( 500, -100),
	# Inside the inner barrier (circuit interior, z > -95 at start straight)
	Vector2(  55,  -85), Vector2( 130,  -85), Vector2( 230,  -85),
	Vector2(-150,   45), Vector2(-210,   -5), Vector2(-100,  110),
]

var rng := RandomNumberGenerator.new()

# ─────────────────────────── RACE TIMER STATE ────────────────────────────────

const _RACE_LIMIT := 120.0  # 2 minutes for 2 laps

var _race_time    := _RACE_LIMIT  # counts DOWN from 120
var _racing       := false        # true after countdown completes
var _finished     := false
var _finish_armed := false        # true once kart has left the start zone
var _lap_count    := 0            # laps completed (max 2)

var _cd_value   := 3
var _cd_elapsed := 0.0
const _CD_STEP  := 1.0  # seconds per countdown beat

var _hud_canvas:    CanvasLayer
var _timer_label:   Label
var _lap_label:     Label
var _cd_label:      Label
var _finish_label:  Label
var _kart:          CharacterBody3D


func _ready() -> void:
	var idx := GameState.selected_map
	rng.seed = idx * 13337 + 7

	_setup_sky(idx)
	_setup_lighting(GameState.MAPS[idx])
	_setup_scene_nodes(idx)

	match idx:
		0: _spawn_grand_prix()
		1: _spawn_desert()
		2: _spawn_midnight()

	_setup_hud()
	_setup_finish_area()
	_start_countdown()


# ─────────────────────────── SCENE NODE SETUP ───────────────────────────────

func _setup_scene_nodes(idx: int) -> void:
	# Hide daytime clouds on non-Grand-Prix maps
	if idx != 0:
		for i in range(1, 15):
			var cloud := get_node_or_null("cloud%d" % i)
			if cloud:
				cloud.visible = false

	if idx == 2:
		# Dark asphalt floor instead of beach
		var floor_mesh := get_node_or_null("floor/MeshInstance3D") as MeshInstance3D
		if floor_mesh:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.07, 0.07, 0.09)
			floor_mesh.material_override = mat

		# Swap banner to Midnight Circuit
		var tex: Texture2D = load("res://assets/textures/MidnightCircuit.png")
		for sprite_path in ["startingline/Sprite3D", "startingline/Sprite3D2"]:
			var sprite := get_node_or_null(sprite_path) as Sprite3D
			if sprite and tex:
				sprite.texture = tex


# ─────────────────────────── HUD ─────────────────────────────────────────────

func _setup_hud() -> void:
	_hud_canvas = CanvasLayer.new()
	add_child(_hud_canvas)

	# Race timer — top-centre (shows countdown)
	_timer_label = Label.new()
	_timer_label.text = "2:00.000"
	_timer_label.add_theme_font_size_override("font_size", 36)
	_timer_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_timer_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_timer_label.add_theme_constant_override("shadow_offset_x", 2)
	_timer_label.add_theme_constant_override("shadow_offset_y", 2)
	_timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_timer_label.position = Vector2(-80, 20)
	_timer_label.visible  = false
	_hud_canvas.add_child(_timer_label)

	# Lap counter — top-right
	_lap_label = Label.new()
	_lap_label.text = "Lap 1 / 2"
	_lap_label.add_theme_font_size_override("font_size", 32)
	_lap_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_lap_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_lap_label.add_theme_constant_override("shadow_offset_x", 2)
	_lap_label.add_theme_constant_override("shadow_offset_y", 2)
	_lap_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_lap_label.position = Vector2(-160, 20)
	_lap_label.visible  = false
	_hud_canvas.add_child(_lap_label)

	# Countdown — centre screen
	_cd_label = Label.new()
	_cd_label.text = "3"
	_cd_label.add_theme_font_size_override("font_size", 128)
	_cd_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.1))
	_cd_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_cd_label.add_theme_constant_override("shadow_offset_x", 3)
	_cd_label.add_theme_constant_override("shadow_offset_y", 3)
	_cd_label.set_anchors_preset(Control.PRESET_CENTER)
	_cd_label.position = Vector2(-48, -64)
	_hud_canvas.add_child(_cd_label)

	# Finish banner — centre screen, hidden until lap done
	_finish_label = Label.new()
	_finish_label.text = ""
	_finish_label.add_theme_font_size_override("font_size", 52)
	_finish_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	_finish_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_finish_label.add_theme_constant_override("shadow_offset_x", 3)
	_finish_label.add_theme_constant_override("shadow_offset_y", 3)
	_finish_label.set_anchors_preset(Control.PRESET_CENTER)
	_finish_label.position = Vector2(-200, 40)
	_finish_label.visible  = false
	_hud_canvas.add_child(_finish_label)


# ─────────────────────────── COUNTDOWN ───────────────────────────────────────

func _start_countdown() -> void:
	_kart = get_node_or_null("player")
	if _kart:
		_kart.set_physics_process(false)
	_cd_value   = 3
	_cd_elapsed = 0.0
	_cd_label.text    = "3"
	_cd_label.visible = true


func _process(delta: float) -> void:
	if _finished:
		return

	# ── COUNTDOWN phase ──
	if not _racing:
		_cd_elapsed += delta
		if _cd_elapsed >= _CD_STEP:
			_cd_elapsed -= _CD_STEP
			_cd_value   -= 1
			if _cd_value > 0:
				_cd_label.text = str(_cd_value)
			else:
				_cd_label.text    = "GO!"
				_racing           = true
				_timer_label.visible = true
				_lap_label.visible   = true
				if _kart:
					_kart.set_physics_process(true)
				# Hide GO! after half a second
				var t := get_tree().create_timer(0.6)
				t.timeout.connect(func(): _cd_label.visible = false)
				# Arm finish detection after enough time to clear the start zone
				var arm_timer := get_tree().create_timer(8.0)
				arm_timer.timeout.connect(func(): _finish_armed = true)
		return

	# ── RACING phase ──
	_race_time  -= delta
	if _race_time <= 0.0:
		_race_time = 0.0
		_timer_label.text = "0:00.000"
		_timer_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		_finished = true
		_finish_label.text    = "Time's Up!"
		_finish_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		_finish_label.visible = true
		return
	# Turn timer red in the last 10 seconds
	if _race_time <= 10.0:
		_timer_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	_timer_label.text = _format_time(_race_time)


func _setup_finish_area() -> void:
	# Thin box across the road at the start/finish line, perpendicular to travel
	var area  := Area3D.new()
	var col   := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	# Road is ~30 units wide (z: -111 to -140); span 36 to catch both lanes
	shape.size = Vector3(4.0, 5.0, 36.0)
	col.shape  = shape
	area.add_child(col)
	# Position at the starting line — slightly behind player start so they
	# cross it on the way back, not on the first frame
	area.position = Vector3(8.0, 1.0, -125.0)
	add_child(area)
	area.body_entered.connect(_on_finish_line_crossed)


func _on_finish_line_crossed(body: Node3D) -> void:
	if _finished or not _finish_armed or not _racing:
		return
	if body != _kart:
		return

	_lap_count += 1

	if _lap_count == 1:
		# First lap done — show lap 2 and re-arm
		_lap_label.text = "Lap 2 / 2"
		_finish_armed   = false
		var arm_timer := get_tree().create_timer(4.0)
		arm_timer.timeout.connect(func(): _finish_armed = true)
	elif _lap_count >= 2:
		# Both laps done — player wins
		_finished = true
		_timer_label.visible = false
		var time_left := _race_time
		_finish_label.text = "Finished!  " + _format_time(time_left) + " left"
		_finish_label.visible = true


func _format_time(t: float) -> String:
	t = maxf(t, 0.0)
	var minutes := int(t) / 60
	var seconds := int(t) % 60
	var ms      := int(fmod(t, 1.0) * 1000.0)
	return "%d:%02d.%03d" % [minutes, seconds, ms]


# ─────────────────────────── SKY ─────────────────────────────────────────────

func _setup_sky(idx: int) -> void:
	var m := ProceduralSkyMaterial.new()
	match idx:
		0:
			m.sky_top_color          = Color(0.08, 0.33, 0.76)
			m.sky_horizon_color      = Color(0.50, 0.76, 1.00)
			m.ground_horizon_color   = Color(0.58, 0.70, 0.50)
			m.ground_bottom_color    = Color(0.22, 0.28, 0.18)
			m.sky_energy_multiplier  = 1.2
		1:
			m.sky_top_color          = Color(0.52, 0.10, 0.02)
			m.sky_horizon_color      = Color(1.00, 0.60, 0.18)
			m.ground_horizon_color   = Color(0.85, 0.55, 0.28)
			m.ground_bottom_color    = Color(0.40, 0.22, 0.08)
			m.sky_energy_multiplier  = 1.6
		2:
			m.sky_top_color          = Color(0.04, 0.04, 0.12)
			m.sky_horizon_color      = Color(0.10, 0.10, 0.28)
			m.ground_horizon_color   = Color(0.08, 0.08, 0.18)
			m.ground_bottom_color    = Color(0.04, 0.04, 0.10)
			m.sky_energy_multiplier  = 0.40

	var sky := Sky.new()
	sky.sky_material = m
	world_env.environment.background_mode = Environment.BG_SKY
	world_env.environment.sky = sky


func _setup_lighting(map: Dictionary) -> void:
	sun.light_color  = map["sun_color"]
	sun.light_energy = map["sun_energy"]
	world_env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world_env.environment.ambient_light_color  = map["ambient_color"]
	world_env.environment.ambient_light_energy = map["ambient_energy"]


# ─────────────────────────── MAP 0: GRAND PRIX ───────────────────────────────

func _spawn_grand_prix() -> void:
	_spawn_clouds()
	_spawn_grandstand(Vector3(-138, 0, 55),  80.0, -1)  # left side
	_spawn_grandstand(Vector3( 208, 0, 55),  80.0,  1)  # right side

	# Regular trackside trees + rocks in clusters
	for c in CLUSTERS:
		for _i in range(PER_CLUSTER):
			var p := _scatter(c)
			if rng.randf() > 0.35:
				_make_tree(p)
			else:
				_make_rock(p, Color(0.54, 0.49, 0.43))


func _spawn_clouds() -> void:
	var crng := RandomNumberGenerator.new()
	crng.seed = 555
	var cloud_mat := StandardMaterial3D.new()
	cloud_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.88)
	cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var positions: Array[Vector3] = [
		Vector3(  30, 90,  -80), Vector3( 120, 100,  -60), Vector3(-60,  95, -40),
		Vector3( 200, 85,  -90), Vector3(  80,  88, -110), Vector3(-20, 105, -70),
	]
	for base_pos: Vector3 in positions:
		var blobs := crng.randi_range(3, 5)
		for _b in range(blobs):
			var bx: float = base_pos.x + crng.randf_range(-20.0, 20.0)
			var by: float = base_pos.y + crng.randf_range( -6.0,  6.0)
			var bz: float = base_pos.z + crng.randf_range(-14.0, 14.0)
			var br := crng.randf_range(10.0, 18.0)
			var sphere := SphereMesh.new()
			sphere.radius = br
			sphere.height = br * 2.0
			sphere.material = cloud_mat
			var n := MeshInstance3D.new()
			n.mesh = sphere
			n.position = Vector3(bx, by, bz)
			add_child(n)


func _spawn_grandstand(center: Vector3, length: float, side: int) -> void:
	# side: -1 = faces right (track is to the right), +1 = faces left
	var concrete := StandardMaterial3D.new()
	concrete.albedo_color = Color(0.52, 0.52, 0.56)

	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.20, 0.20, 0.80)  # blue roof

	for tier in range(3):
		var rise    := float(tier) * 4.2
		var setback := float(side) * float(tier) * 3.8
		var tw      := length - float(tier) * 6.0

		# Tier platform
		var box := BoxMesh.new()
		box.size = Vector3(tw, 3.8, 5.5)
		box.material = concrete
		_mesh(box, center + Vector3(setback, rise + 1.9, 0))

		# Crowd row on this tier (MultiMesh for performance)
		_add_crowd_row(
			center + Vector3(setback + float(side) * 1.5, rise + 3.8 + 1.4, 0),
			tw, 3.0
		)

	# Roof over back tier
	var roof := BoxMesh.new()
	roof.size = Vector3(length - 12.0, 0.8, 6.5)
	roof.material = roof_mat
	_mesh(roof, center + Vector3(float(side) * 7.6, 14.5, 0))


func _add_crowd_row(center: Vector3, length: float, depth: float) -> void:
	var person_mesh := CylinderMesh.new()
	person_mesh.top_radius    = 0.45
	person_mesh.bottom_radius = 0.45
	person_mesh.height        = 2.0

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = person_mesh
	var count := int(length / 1.8) * int(depth / 1.8)
	count = maxi(count, 1)
	mm.instance_count = count

	var crng := RandomNumberGenerator.new()
	crng.seed = int(center.x * 7 + center.z * 3)

	var i := 0
	var cols := int(length / 1.8)
	var rows := int(depth / 1.8)
	for row in range(rows):
		for col in range(cols):
			if i >= count: break
			var px := center.x - length * 0.5 + col * 1.8 + 0.9
			var pz := center.z - depth  * 0.5 + row * 1.8 + 0.9
			var py := center.y

			var person_mat := StandardMaterial3D.new()
			person_mat.albedo_color = Color(
				crng.randf_range(0.4, 1.0),
				crng.randf_range(0.1, 0.9),
				crng.randf_range(0.1, 0.9)
			)
			person_mesh.material = person_mat

			var t := Transform3D(Basis(), Vector3(px, py, pz))
			mm.set_instance_transform(i, t)
			i += 1

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)


func _make_tree(p: Vector2) -> void:
	var h := rng.randf_range(5.0, 10.0)
	var tr := rng.randf_range(0.28, 0.52)
	var cr := rng.randf_range(2.4, 4.5)

	var tm := StandardMaterial3D.new()
	tm.albedo_color = Color(0.36, 0.24, 0.13)
	_cyl(Vector3(p.x, h * 0.5, p.y), tr * 0.7, tr, h, tm)

	var cm_mesh := SphereMesh.new()
	cm_mesh.radius = cr; cm_mesh.height = cr * 2.0
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(rng.randf_range(0.14, 0.26),
		rng.randf_range(0.40, 0.60), rng.randf_range(0.10, 0.20))
	cm_mesh.material = cm
	_mesh(cm_mesh, Vector3(p.x, h + cr * 0.55, p.y))


# ─────────────────────────── MAP 1: DESERT ───────────────────────────────────

func _spawn_desert() -> void:
	for c in CLUSTERS:
		for _i in range(PER_CLUSTER):
			var p := _scatter(c)
			if rng.randf() > 0.32:
				_make_cactus(p)
			else:
				_make_rock(p, Color(0.55, 0.48, 0.39))


func _make_cactus(p: Vector2) -> void:
	var h := rng.randf_range(4.0, 8.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.20, 0.46, 0.18)
	_cyl(Vector3(p.x, h * 0.5, p.y), 0.32, 0.42, h, mat)
	var la_w := rng.randf_range(1.2, 2.2)
	var la_y := h * rng.randf_range(0.38, 0.60)
	var la_h := rng.randf_range(1.4, 2.6)
	_cyl(Vector3(p.x - la_w * 0.5, la_y, p.y), 0.20, 0.20, la_w, mat, Vector3(0, 0, PI * 0.5))
	_cyl(Vector3(p.x - la_w, la_y + la_h * 0.5, p.y), 0.18, 0.20, la_h, mat)
	if rng.randf() > 0.40:
		var ra_w := rng.randf_range(1.0, 1.8)
		var ra_y := h * rng.randf_range(0.50, 0.72)
		var ra_h := rng.randf_range(1.2, 2.2)
		_cyl(Vector3(p.x + ra_w * 0.5, ra_y, p.y), 0.20, 0.20, ra_w, mat, Vector3(0, 0, PI * 0.5))
		_cyl(Vector3(p.x + ra_w, ra_y + ra_h * 0.5, p.y), 0.18, 0.20, ra_h, mat)


# ─────────────────────────── MAP 2: MIDNIGHT ─────────────────────────────────

func _spawn_midnight() -> void:
	_spawn_stars()
	_spawn_city_buildings()
	# Use road-safe lamp clusters instead of shared CLUSTERS
	var lamp_rng := RandomNumberGenerator.new()
	lamp_rng.seed = 99991
	for c in MIDNIGHT_LAMP_CLUSTERS:
		for _i in range(2):
			var angle := lamp_rng.randf() * TAU
			var dist  := lamp_rng.randf() * 22.0
			var p := c + Vector2(cos(angle), sin(angle)) * dist
			_make_lamp_post(p)


func _spawn_city_buildings() -> void:
	var brng := RandomNumberGenerator.new()
	brng.seed = 77777

	var building_mat := StandardMaterial3D.new()
	building_mat.albedo_color = Color(0.06, 0.06, 0.12)

	var window_mat := StandardMaterial3D.new()
	window_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	window_mat.emission_enabled = true
	window_mat.emission = Color(0.92, 0.82, 0.48)
	window_mat.emission_energy_multiplier = 2.5

	var window_mat2 := StandardMaterial3D.new()
	window_mat2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	window_mat2.emission_enabled = true
	window_mat2.emission = Color(0.50, 0.75, 1.00)
	window_mat2.emission_energy_multiplier = 2.5

	# Building positions — placed outside track barriers or in circuit interior.
	# Road at far-left section (x≈-158) runs z=-69 to z=-139; old position
	# (-158,-105) was in the road. Moved to (-158,-160) outside the outer wall.
	var building_positions: Array[Vector2] = [
		Vector2(-162,  55), Vector2(-168, -25), Vector2(-158, -160),
		Vector2( 238,  55), Vector2( 232, -25), Vector2( 228, -105),
		Vector2(  65,-168), Vector2(   0,-162), Vector2( 135, -165),
		Vector2(  65, 230), Vector2(  -5, 222), Vector2( 135,  226),
	]

	for base in building_positions:
		var w := brng.randf_range(14.0, 24.0)
		var h := brng.randf_range(22.0, 52.0)
		var d := brng.randf_range(12.0, 20.0)

		var box := BoxMesh.new()
		box.size = Vector3(w, h, d)
		box.material = building_mat
		_mesh(box, Vector3(base.x, h * 0.5, base.y))

		# Lit windows on the track-facing side
		var win_cols := maxi(int(w / 4.0), 1)
		var win_rows := maxi(int(h / 6.0), 1)
		for row in range(win_rows):
			for col in range(win_cols):
				if brng.randf() < 0.55:
					var wx := base.x - w * 0.5 + (col + 0.5) * (w / win_cols)
					var wy := 3.0 + (row + 0.5) * (h / win_rows)
					var wbox := BoxMesh.new()
					wbox.size = Vector3(1.1, 1.4, 0.3)
					wbox.material = window_mat if brng.randf() > 0.3 else window_mat2
					_mesh(wbox, Vector3(wx, wy, base.y - d * 0.5 - 0.12))


func _spawn_stars() -> void:
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 1.0; star_mesh.height = 2.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(1.0, 1.0, 0.92)
	mat.emission_energy_multiplier = 4.0
	star_mesh.material = mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = star_mesh
	mm.instance_count = 400

	var srng := RandomNumberGenerator.new(); srng.seed = 88888
	for i in range(400):
		var theta := srng.randf() * TAU
		var phi   := srng.randf() * PI * 0.44
		var r     := srng.randf_range(380.0, 460.0)
		var s     := srng.randf_range(0.5, 2.2)
		var t     := Transform3D(Basis().scaled(Vector3.ONE * s),
			Vector3(r * sin(phi) * cos(theta), r * cos(phi), r * sin(phi) * sin(theta)))
		mm.set_instance_transform(i, t)

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)


func _make_lamp_post(p: Vector2) -> void:
	var h := rng.randf_range(7.0, 10.0)
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.18, 0.18, 0.22)
	_cyl(Vector3(p.x, h * 0.5, p.y), 0.13, 0.16, h, pm)

	var lm := SphereMesh.new(); lm.radius = 0.55; lm.height = 1.1
	var lmat := StandardMaterial3D.new()
	lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lmat.emission_enabled = true
	lmat.emission = Color(0.55, 0.68, 1.0)
	lmat.emission_energy_multiplier = 6.0
	lm.material = lmat
	_mesh(lm, Vector3(p.x, h + 0.55, p.y))

	var light := OmniLight3D.new()
	light.position    = Vector3(p.x, h + 0.6, p.y)
	light.light_color  = Color(0.5, 0.65, 1.0)
	light.light_energy = 2.8
	light.omni_range   = 20.0
	add_child(light)


# ─────────────────────────── SHARED ──────────────────────────────────────────

func _make_rock(p: Vector2, color: Color) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0; sphere.height = 2.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	sphere.material = mat
	var node := _mesh(sphere, Vector3(p.x, 0.0, p.y))
	node.scale = Vector3(rng.randf_range(0.8, 2.4), rng.randf_range(0.4, 1.1), rng.randf_range(0.8, 2.2))


func _cyl(pos: Vector3, tr: float, br: float, h: float,
		  mat: StandardMaterial3D, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = tr; mesh.bottom_radius = br; mesh.height = h; mesh.material = mat
	var node := MeshInstance3D.new()
	node.mesh = mesh; node.position = pos; node.rotation = rot
	add_child(node)
	return node


func _mesh(mesh: Mesh, pos: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh; node.position = pos
	add_child(node)
	return node


func _scatter(center: Vector2) -> Vector2:
	var angle := rng.randf() * TAU
	var dist  := rng.randf() * CLUSTER_RADIUS
	return center + Vector2(cos(angle), sin(angle)) * dist
