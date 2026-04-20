extends Control

var _bg: ColorRect
var _bg_tween: Tween

const PREVIEW_H := 155.0


func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# ── BACKGROUND ──────────────────────────────────────────
	_bg = ColorRect.new()
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.color = GameState.MAPS[0]["bg_top"]
	add_child(_bg)

	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	overlay.anchor_bottom = 0.42
	overlay.color = Color(0, 0, 0, 0.32)
	add_child(overlay)

	# ── TITLE ────────────────────────────────────────────────
	var title := Label.new()
	title.text = "KART RACING"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left   = 0.0; title.anchor_right  = 1.0
	title.anchor_top    = 0.0; title.anchor_bottom = 0.0
	title.offset_top    = 48;  title.offset_bottom = 138
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 4)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "SELECT A TRACK"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.anchor_left   = 0.0; subtitle.anchor_right  = 1.0
	subtitle.anchor_top    = 0.0; subtitle.anchor_bottom = 0.0
	subtitle.offset_top    = 148; subtitle.offset_bottom = 192
	subtitle.add_theme_font_size_override("font_size", 26)
	subtitle.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	add_child(subtitle)

	# ── HINT ─────────────────────────────────────────────────
	var hint := Label.new()
	hint.text = "WASD / Arrows to drive  |  SPACE to drift  |  Hold drift + turn to charge a boost"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.anchor_left   = 0.0; hint.anchor_right  = 1.0
	hint.anchor_top    = 1.0; hint.anchor_bottom = 1.0
	hint.offset_top    = -48; hint.offset_bottom = -14
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.50))
	add_child(hint)

	# ── MAP CARDS ─────────────────────────────────────────────
	var card_area := CenterContainer.new()
	card_area.anchor_left   = 0.0; card_area.anchor_right  = 1.0
	card_area.anchor_top    = 0.20; card_area.anchor_bottom = 0.93
	add_child(card_area)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 40)
	card_area.add_child(hbox)

	for i in range(GameState.MAPS.size()):
		hbox.add_child(_make_card(i))


func _make_card(idx: int) -> Panel:
	var map := GameState.MAPS[idx]

	var style := StyleBoxFlat.new()
	style.bg_color                       = map["card_color"]
	style.corner_radius_top_left         = 18
	style.corner_radius_top_right        = 18
	style.corner_radius_bottom_left      = 18
	style.corner_radius_bottom_right     = 18
	style.border_width_left              = 2
	style.border_width_right             = 2
	style.border_width_top               = 2
	style.border_width_bottom            = 2
	style.border_color                   = Color(1, 1, 1, 0.22)
	style.shadow_color                   = Color(0, 0, 0, 0.40)
	style.shadow_size                    = 14
	style.shadow_offset                  = Vector2(0, 7)

	var card := Panel.new()
	card.custom_minimum_size = Vector2(355, 420)
	card.add_theme_stylebox_override("panel", style)
	card.clip_children = CanvasItem.CLIP_CHILDREN_ONLY

	# ── PREVIEW IMAGE (top of card, clips to rounded corners) ──
	var preview_style := StyleBoxFlat.new()
	preview_style.bg_color = Color(0, 0, 0)
	preview_style.corner_radius_top_left    = 18
	preview_style.corner_radius_top_right   = 18
	preview_style.corner_radius_bottom_left = 0
	preview_style.corner_radius_bottom_right = 0

	var preview_bg := Panel.new()
	preview_bg.anchor_left   = 0.0; preview_bg.anchor_right = 1.0
	preview_bg.anchor_top    = 0.0; preview_bg.anchor_bottom = 0.0
	preview_bg.offset_bottom = PREVIEW_H
	preview_bg.add_theme_stylebox_override("panel", preview_style)
	card.add_child(preview_bg)

	var preview := MapPreview.new()
	preview.anchor_left   = 0.0; preview.anchor_right  = 1.0
	preview.anchor_top    = 0.0; preview.anchor_bottom = 0.0
	preview.offset_bottom = PREVIEW_H
	preview.setup(idx)
	card.add_child(preview)

	# ── CARD BODY (below preview) ───────────────────────────
	var vbox := VBoxContainer.new()
	vbox.anchor_left   = 0.0; vbox.anchor_right  = 1.0
	vbox.anchor_top    = 0.0; vbox.anchor_bottom = 0.0
	vbox.offset_left   =  22; vbox.offset_right  = -22
	vbox.offset_top    = PREVIEW_H + 14
	vbox.offset_bottom = 420 - 18
	vbox.alignment     = BoxContainer.ALIGNMENT_BEGIN
	card.add_child(vbox)

	var badge := Label.new()
	badge.text = "MAP  %d" % (idx + 1)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 14)
	badge.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	vbox.add_child(badge)

	_vspace(vbox, 6)

	var name_lbl := Label.new()
	name_lbl.text = map["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 30)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	name_lbl.add_theme_constant_override("shadow_offset_x", 2)
	name_lbl.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(name_lbl)

	_vspace(vbox, 10)

	var desc := Label.new()
	desc.text = map["description"]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 18)
	desc.add_theme_color_override("font_color", Color(1, 1, 1, 0.80))
	vbox.add_child(desc)

	_vspace(vbox, 20)

	# RACE button
	var btn_n := _btn_style(Color(1, 1, 1, 0.16), Color(1, 1, 1, 0.45))
	var btn_h := _btn_style(Color(1, 1, 1, 0.30), Color(1, 1, 1, 0.80))
	var btn_p := _btn_style(Color(1, 1, 1, 0.48), Color(1, 1, 1, 1.00))

	var btn := Button.new()
	btn.text = "RACE!"
	btn.custom_minimum_size = Vector2(180, 52)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color",         Color.WHITE)
	btn.add_theme_color_override("font_hover_color",   Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_stylebox_override("normal",  btn_n)
	btn.add_theme_stylebox_override("hover",   btn_h)
	btn.add_theme_stylebox_override("pressed", btn_p)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	btn.pressed.connect(_on_map_selected.bind(idx))

	var center := CenterContainer.new()
	center.add_child(btn)
	vbox.add_child(center)

	# Hover highlight on whole card
	card.mouse_entered.connect(_on_card_hover.bind(idx, style, map))
	card.mouse_exited.connect(_on_card_unhover.bind(style, map))

	return card


# ── EVENTS ──────────────────────────────────────────────────────────────────

func _on_card_hover(idx: int, style: StyleBoxFlat, map: Dictionary) -> void:
	style.bg_color     = map["card_hover"]
	style.border_color = Color(1, 1, 1, 0.60)
	_animate_bg(map["bg_bottom"])


func _on_card_unhover(style: StyleBoxFlat, map: Dictionary) -> void:
	style.bg_color     = map["card_color"]
	style.border_color = Color(1, 1, 1, 0.22)


func _on_map_selected(idx: int) -> void:
	GameState.selected_map = idx

	if _bg_tween: _bg_tween.kill()

	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0)
	add_child(overlay)

	_bg_tween = create_tween()
	_bg_tween.tween_property(overlay, "color", Color(0, 0, 0, 1), 0.40)
	_bg_tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/game/SampleGame.tscn"))


# ── HELPERS ─────────────────────────────────────────────────────────────────

func _animate_bg(target: Color) -> void:
	if _bg_tween: _bg_tween.kill()
	_bg_tween = create_tween()
	_bg_tween.tween_property(_bg, "color", target, 0.35)


func _btn_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color                   = bg
	s.corner_radius_top_left     = 10
	s.corner_radius_top_right    = 10
	s.corner_radius_bottom_left  = 10
	s.corner_radius_bottom_right = 10
	s.border_width_left          = 2
	s.border_width_right         = 2
	s.border_width_top           = 2
	s.border_width_bottom        = 2
	s.border_color               = border
	return s


func _vspace(parent: Control, px: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, px)
	parent.add_child(s)
