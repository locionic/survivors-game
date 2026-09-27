class_name UITheme
extends RefCounted

## Milestone 4: the game's design tokens, in one place.
##
## Colors, fonts and stylebox factories live here so the HUD, the title screen and
## every modal restyle themselves from the same source. Styling is applied at
## runtime from the owning script rather than baked into the .tscn, so a token
## change needs exactly one edit.

# --- Palette -------------------------------------------------------------
const INK: Color = Color("#0D0F14")          # Deep background
const LACQUER: Color = Color("#161922")       # Card & modal background
const GOLD: Color = Color("#F5C542")          # Primary accent, CTA, gold indicators
const JADE: Color = Color("#2EC4B6")          # Positive stat deltas, XP bar
const VERMILION: Color = Color("#E63946")     # Negative stat deltas, HP bar, danger
const MUTED: Color = Color("#8A8F9A")         # Secondary descriptions
const BORDER: Color = Color("#2F3747")        # Subtle card border

# Derived tints, so nobody hand-mixes a slightly-wrong hex.
const INK_DIM: Color = Color("#0A0C10")
const GOLD_DIM: Color = Color("#8A6E1F")
const TEXT: Color = Color("#EDEFF3")
const TEXT_ON_GOLD: Color = Color("#1A1405")  # Ink, for legible text on gold

# --- Font paths ----------------------------------------------------------
const DISPLAY_FONT_PATH: String = "res://assets/fonts/Cinzel-Bold.ttf"
const BODY_FONT_PATH: String = "res://assets/fonts/BeVietnamPro-Regular.ttf"
const BODY_BOLD_FONT_PATH: String = "res://assets/fonts/BeVietnamPro-Bold.ttf"

# Cached because load() re-enters the resource cache on every miss otherwise, and
# these are requested by every styled node during _ready().
static var _display_font: Font = null
static var _body_font: Font = null
static var _body_bold_font: Font = null

## Display face: Cinzel Bold. Titles, damage numbers, anything with gravitas.
static func get_display_font() -> Font:
	if _display_font == null:
		_display_font = _load_font(DISPLAY_FONT_PATH)
	return _display_font

## Body face: Be Vietnam Pro Regular. Stats, descriptions, diacritics.
static func get_body_font() -> Font:
	if _body_font == null:
		_body_font = _load_font(BODY_FONT_PATH)
	return _body_font

## Bold body face: Be Vietnam Pro Bold. Headers, buttons, badges.
static func get_body_bold_font() -> Font:
	if _body_bold_font == null:
		_body_bold_font = _load_font(BODY_BOLD_FONT_PATH)
	return _body_bold_font

static func _load_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Font:
			return res
	push_warning("UITheme: font missing at %s" % path)
	return null

# --- Stylebox factories --------------------------------------------------

## Card / modal surface. The workhorse background for anything with a border.
static func make_card_panel(
		bg: Color = LACQUER,
		border: Color = BORDER,
		radius: int = 8,
		border_w: int = 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

## Secondary button: lacquer fill, subtle border, same radius as a card.
static func make_button_style(
		bg: Color = LACQUER,
		border: Color = BORDER,
		radius: int = 8) -> StyleBoxFlat:
	var sb := make_card_panel(bg, border, radius, 1)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 9
	sb.content_margin_bottom = 9
	return sb

## Primary call-to-action: warm gold fill with a darker gold edge.
static func make_cta_button_style() -> StyleBoxFlat:
	return make_button_style(GOLD, GOLD_DIM, 8)
