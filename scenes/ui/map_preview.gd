class_name MapPreview
extends Control

var map_index: int = 0

func setup(idx: int) -> void:
	map_index = idx
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	match map_index:
		0: _draw_grand_prix(w, h)
		1: _draw_desert(w, h)
		2: _draw_midnight(w, h)


# ─────────────────────────── MAP 0: GRAND PRIX ──────────────────────────────

func _draw_grand_prix(w: float, h: float) -> void:
	var sky_h := h * 0.60

	# Sky gradient — 16 bands
	_gradient_rect(Vector2(0, 0), w, sky_h,
		Color(0.08, 0.33, 0.76), Color(0.50, 0.76, 1.00), 16)

	# Clouds
	_cloud(Vector2(w * 0.18, h * 0.12), 22.0)
	_cloud(Vector2(w * 0.58, h * 0.08), 18.0)
	_cloud(Vector2(w * 0.82, h * 0.18), 14.0)

	# Left grandstand silhouette
	var gsc := Color(0.28, 0.28, 0.32)
	# lower tier
	draw_rect(Rect2(0, sky_h * 0.52, w * 0.20, sky_h * 0.48), gsc)
	# upper tier (step back)
	draw_rect(Rect2(0, sky_h * 0.28, w * 0.14, sky_h * 0.26), gsc)
	# top trim
	draw_rect(Rect2(0, sky_h * 0.24, w * 0.14, sky_h * 0.06), Color(0.40, 0.40, 0.45))

	# Right grandstand silhouette
	draw_rect(Rect2(w * 0.80, sky_h * 0.52, w * 0.20, sky_h * 0.48), gsc)
	draw_rect(Rect2(w * 0.86, sky_h * 0.28, w * 0.14, sky_h * 0.26), gsc)
	draw_rect(Rect2(w * 0.86, sky_h * 0.24, w * 0.14, sky_h * 0.06), Color(0.40, 0.40, 0.45))

	# Crowd dots — left stand
	var rng := RandomNumberGenerator.new()
	rng.seed = 101
	for _i in range(55):
		var cx := rng.randf() * w * 0.13 + 1.0
		var cy := rng.randf() * sky_h * 0.30 + sky_h * 0.28
		draw_circle(Vector2(cx, cy),
			1.8, Color(rng.randf_range(0.6, 1.0), rng.randf_range(0.1, 0.9), rng.randf_range(0.1, 0.8)))

	# Crowd dots — right stand
	for _i in range(55):
		var cx := rng.randf() * w * 0.13 + w * 0.86
		var cy := rng.randf() * sky_h * 0.30 + sky_h * 0.28
		draw_circle(Vector2(cx, cy),
			1.8, Color(rng.randf_range(0.6, 1.0), rng.randf_range(0.1, 0.9), rng.randf_range(0.1, 0.8)))

	# Green infield
	draw_rect(Rect2(0, sky_h, w, h - sky_h), Color(0.34, 0.52, 0.28))

	# Track surface
	var track_y := sky_h + (h - sky_h) * 0.38
	var track_h := (h - sky_h) * 0.42
	draw_rect(Rect2(0, track_y, w, track_h), Color(0.26, 0.26, 0.28))

	# Centre line
	for i in range(7):
		var lx := w * (float(i) / 6.0) * 0.85 + w * 0.05
		draw_rect(Rect2(lx, track_y + track_h * 0.45, w * 0.07, 3), Color(1, 1, 0.3, 0.9))

	# Start/finish chequered hint
	var sq := 7.0
	for row in range(2):
		for col in range(4):
			var dark := (row + col) % 2 == 0
			draw_rect(Rect2(w * 0.44 + col * sq, track_y, sq, sq),
				Color.BLACK if dark else Color.WHITE)


func _cloud(center: Vector2, r: float) -> void:
	var c := Color(1, 1, 1, 0.92)
	draw_circle(center, r * 0.65, c)
	draw_circle(center + Vector2(-r * 0.52, r * 0.20), r * 0.48, c)
	draw_circle(center + Vector2(r * 0.52, r * 0.20), r * 0.48, c)
	draw_circle(center + Vector2(-r * 0.22, r * 0.32), r * 0.52, c)
	draw_circle(center + Vector2(r * 0.22, r * 0.32), r * 0.52, c)
	draw_rect(Rect2(center.x - r * 0.52, center.y + r * 0.20, r * 1.04, r * 0.32), c)


# ─────────────────────────── MAP 1: DESERT DUSK ─────────────────────────────

func _draw_desert(w: float, h: float) -> void:
	var sky_h := h * 0.62

	_gradient_rect(Vector2(0, 0), w, sky_h,
		Color(0.52, 0.10, 0.02), Color(1.00, 0.58, 0.14), 16)

	# Sun on horizon
	draw_circle(Vector2(w * 0.50, sky_h * 0.92), 20.0, Color(1.0, 0.90, 0.25))
	draw_circle(Vector2(w * 0.50, sky_h * 0.92), 14.0, Color(1.0, 0.97, 0.55))

	# Horizon glow
	_gradient_rect(Vector2(0, sky_h * 0.78), w, sky_h * 0.22,
		Color(1.0, 0.65, 0.10, 0.0), Color(1.0, 0.65, 0.10, 0.45), 8)

	# Sand ground
	_gradient_rect(Vector2(0, sky_h), w, h - sky_h,
		Color(0.80, 0.64, 0.38), Color(0.58, 0.44, 0.24), 8)

	# Cactus silhouettes
	_cactus(Vector2(w * 0.12, sky_h + (h - sky_h) * 0.05), (h - sky_h) * 0.70)
	_cactus(Vector2(w * 0.76, sky_h + (h - sky_h) * 0.02), (h - sky_h) * 0.75)
	_cactus(Vector2(w * 0.90, sky_h + (h - sky_h) * 0.10), (h - sky_h) * 0.55)

	# Distant road
	var road_y := sky_h + (h - sky_h) * 0.55
	draw_rect(Rect2(0, road_y, w, (h - sky_h) * 0.20), Color(0.30, 0.28, 0.26))
	draw_rect(Rect2(w * 0.45, road_y + (h - sky_h) * 0.07, w * 0.10, 2), Color(1, 1, 0.8, 0.8))


func _cactus(base: Vector2, height: float) -> void:
	var c := Color(0.14, 0.36, 0.12)
	var tw := height * 0.14
	# trunk
	draw_rect(Rect2(base.x - tw * 0.5, base.y - height, tw, height), c)
	# left arm
	draw_rect(Rect2(base.x - tw * 0.5 - height * 0.25, base.y - height * 0.62,
		height * 0.25, tw * 0.85), c)
	draw_rect(Rect2(base.x - tw * 0.5 - height * 0.25 - tw * 0.4,
		base.y - height * 0.62 - height * 0.22, tw * 0.85, height * 0.22), c)
	# right arm (shorter)
	draw_rect(Rect2(base.x + tw * 0.5, base.y - height * 0.50,
		height * 0.20, tw * 0.85), c)
	draw_rect(Rect2(base.x + tw * 0.5 + height * 0.20 - tw * 0.4,
		base.y - height * 0.50 - height * 0.18, tw * 0.85, height * 0.18), c)


# ─────────────────────────── MAP 2: MIDNIGHT ────────────────────────────────

func _draw_midnight(w: float, h: float) -> void:
	var sky_h := h * 0.68

	# Very dark sky
	draw_rect(Rect2(0, 0, w, sky_h), Color(0.01, 0.01, 0.04))

	# Stars
	var rng := RandomNumberGenerator.new()
	rng.seed = 7777
	for _i in range(80):
		var sx := rng.randf() * w
		var sy := rng.randf() * sky_h * 0.88
		var br := rng.randf_range(0.45, 1.0)
		draw_circle(Vector2(sx, sy), rng.randf_range(0.8, 2.0), Color(1, 1, 0.92, br))

	# Faint moon
	draw_circle(Vector2(w * 0.82, sky_h * 0.18), 13.0, Color(0.95, 0.95, 0.80, 0.9))

	# Dark road / ground
	draw_rect(Rect2(0, sky_h, w, h - sky_h), Color(0.04, 0.04, 0.08))
	draw_rect(Rect2(0, sky_h, w, (h - sky_h) * 0.22), Color(0.08, 0.08, 0.14))

	# Road with neon reflections
	var road_y := sky_h + (h - sky_h) * 0.28
	draw_rect(Rect2(0, road_y, w, (h - sky_h) * 0.45), Color(0.10, 0.10, 0.14))
	# Neon lane line
	draw_rect(Rect2(w * 0.45, road_y + (h - sky_h) * 0.18, w * 0.10, 2),
		Color(0.5, 0.65, 1.0, 0.9))

	# Lamp post silhouettes
	_lamp_post(Vector2(w * 0.18, sky_h), (h - sky_h) * 0.55)
	_lamp_post(Vector2(w * 0.78, sky_h), (h - sky_h) * 0.52)

	# Glow from lamps
	draw_circle(Vector2(w * 0.18, sky_h - (h - sky_h) * 0.55), 9.0,
		Color(0.5, 0.65, 1.0, 0.85))
	draw_circle(Vector2(w * 0.78, sky_h - (h - sky_h) * 0.52), 9.0,
		Color(0.5, 0.65, 1.0, 0.85))


func _lamp_post(base: Vector2, height: float) -> void:
	var c := Color(0.18, 0.18, 0.22)
	draw_rect(Rect2(base.x - 2.0, base.y - height, 4.0, height), c)
	draw_rect(Rect2(base.x - 2.0, base.y - height - 4, 14.0, 4.0), c)


# ─────────────────────────── HELPERS ────────────────────────────────────────

# Draw a vertical gradient using `bands` horizontal strips
func _gradient_rect(
	origin:  Vector2,
	w:       float,
	h:       float,
	top:     Color,
	bottom:  Color,
	bands:   int
) -> void:
	var band_h := h / bands
	for i in range(bands):
		var t := float(i) / (bands - 1)
		draw_rect(Rect2(origin.x, origin.y + i * band_h, w, band_h + 1.0), top.lerp(bottom, t))
