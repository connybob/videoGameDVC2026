extends Node

# Which map the player chose on the main menu (0, 1, or 2)
var selected_map: int = 0

# Map definitions used by both the menu and the game scene
var MAPS: Array[Dictionary] = [
	{
		"name":           "Grand Prix Circuit",
		"description":    "Roaring engines and\nstadium crowds",
		"card_color":     Color(0.22, 0.50, 0.92),
		"card_hover":     Color(0.32, 0.62, 1.00),
		"bg_top":         Color(0.14, 0.38, 0.78),
		"bg_bottom":      Color(0.42, 0.70, 0.95),
		"sun_color":      Color(1.00, 0.96, 0.84, 1),
		"sun_energy":     1.2,
		"ambient_color":  Color(0.55, 0.62, 0.72, 1),
		"ambient_energy": 0.45,
	},
	{
		"name":           "Desert Dusk",
		"description":    "Race into the sunset",
		"card_color":     Color(0.78, 0.35, 0.08),
		"card_hover":     Color(0.90, 0.46, 0.14),
		"bg_top":         Color(0.65, 0.22, 0.04),
		"bg_bottom":      Color(0.94, 0.58, 0.18),
		"sun_color":      Color(1.00, 0.70, 0.30, 1),
		"sun_energy":     1.6,
		"ambient_color":  Color(0.80, 0.58, 0.32, 1),
		"ambient_energy": 0.70,
	},
	{
		"name":           "Midnight Circuit",
		"description":    "Under a star lit sky",
		"card_color":     Color(0.07, 0.07, 0.24),
		"card_hover":     Color(0.12, 0.12, 0.38),
		"bg_top":         Color(0.02, 0.02, 0.08),
		"bg_bottom":      Color(0.07, 0.05, 0.20),
		"sun_color":      Color(0.55, 0.55, 1.00, 1),
		"sun_energy":     1.0,
		"ambient_color":  Color(0.22, 0.22, 0.50, 1),
		"ambient_energy": 0.55,
	},
]
