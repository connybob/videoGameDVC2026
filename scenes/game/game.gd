extends Node3D

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D     = $DirectionalLight3D

var CLUSTERS: Array[Vector2] = [
	Vector2(-120,  20), Vector2(-100, -70), Vector2(-105,  95),
	Vector2( 205,  15), Vector2( 185, -65), Vector2( 195, 115),
	Vector2(  55,-130), Vector2( -15,-110), Vector2( 130,-120),
	Vector2(  45, 200), Vector2( -25, 165), Vector2( 140, 190),
]
const CLUSTER_RADIUS: float = 32.0
const PER_CLUSTER: int      = 4

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	var idx := GameState.selected_map
	rng.seed = idx * 13337 + 7

	_setup_sky(idx)
	_setup_lighting(GameState.MAPS[idx])

	match idx:
		0: _spawn_grand_prix()
		1: _spawn_desert()
		2: _spawn_midnight()


# ─────────────────────────── SKY ────────────────────────────────────────────

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


# ─────────────────────────── MAP 0: GRAND PRIX ──────────────────────────────

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
			person_mesh.material = person_mat  # shared, but colour cycles per batch

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


# ─────────────────────────── MAP 1: DESERT ──────────────────────────────────

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


# ─────────────────────────── MAP 2: MIDNIGHT ────────────────────────────────

func _spawn_midnight() -> void:
	_spawn_stars()
	for c in CLUSTERS:
		for _i in range(2):
			_make_lamp_post(_scatter(c))


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


# ─────────────────────────── SHARED ─────────────────────────────────────────

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
