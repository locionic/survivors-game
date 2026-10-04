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

const SYMBOL_FONT_PATH: String = "res://assets/fonts/Symbola.ttf"
static var _symbol_font: Font = null

static func _get_symbol_font() -> Font:
	if _symbol_font == null and ResourceLoader.exists(SYMBOL_FONT_PATH):
		_symbol_font = load(SYMBOL_FONT_PATH)
	return _symbol_font

static func _load_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Font:
			var sym = _get_symbol_font()
			if sym != null and res is FontFile:
				res.fallbacks = [sym]
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

# --- Rarity (level-up cards) -------------------------------------------------

## Four tiers, weakest first. Indexed by every RARITY_* array below, so a tier is
## one int carried through the whole card rather than a colour copied per site.
const RARITY_COMMON: int = 0
const RARITY_RARE: int = 1
const RARITY_EPIC: int = 2
const RARITY_LEGENDARY: int = 3

## Shown on the card so the four colours are legible as a scale and not just four
## hues.
const RARITY_NAMES: Array[String] = ["BÌNH THƯỜNG", "HIẾM", "TUYỆT KỸ", "THẦN CÔNG"]

const RARITY_BORDER: Array[Color] = [
	Color("#AEB4BF"),  # Bình Thường — iron & silver
	Color("#3E8FE0"),  # Hiếm — azure, the bevelled tier
	Color("#8A46D6"),  # Tuyệt Kỹ — imperial purple, the pulsing tier
	Color("#F5C542"),  # Thần Công — gold lacquer, the ember tier
]

## Dark enough that body text keeps its contrast on all four. The borders are
## allowed to be bright because they are 2-4px of frame, not text.
const RARITY_BG: Array[Color] = [
	Color("#161922"), Color("#101A28"), Color("#1A1030"), Color("#1E1608"),
]

## The aura, kept dimmer than the border it sits behind: a glow at its border's
## full alpha reads as a second flat outline rather than as light.
const RARITY_GLOW: Array[Color] = [
	Color("#AEB4BF", 0.0), Color("#3E8FE0", 0.55), Color("#8A46D6", 0.65), Color("#F5C542", 0.80),
]

## Zero for common -- an unlit frame is what makes the lit tiers read as lit.
const RARITY_GLOW_SIZE: Array[int] = [0, 10, 14, 18]

## A card at `tier`. The glow is StyleBoxFlat's own shadow rather than a second
## drawn layer, because UpgradeManager pulses the epic aura by animating
## shadow_color.a; with a separate node behind the card there would be two things
## to animate and only one of them would be the card.
static func rarity_style(tier: int) -> StyleBoxFlat:
	var t := clampi(tier, RARITY_COMMON, RARITY_LEGENDARY)
	var sb := make_card_panel(RARITY_BG[t], RARITY_BORDER[t], 10, 3 if t >= RARITY_EPIC else 2)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.shadow_color = RARITY_GLOW[t]
	sb.shadow_size = RARITY_GLOW_SIZE[t]
	# A filigree hint, not drawn ornament: StyleBoxFlat has no corner-arc
	# primitive, so the two upper tiers get a two-pass corner (corner_detail) and a
	# heavier top/left edge than bottom/right, which reads as a bevelled lacquer
	# frame rather than a plain outline. Real corner art needs a NinePatchRect or a
	# hand-rolled _draw(), and neither earns its keep on a 232px card.
	if t >= RARITY_RARE:
		sb.corner_detail = 4
		sb.border_width_top = sb.border_width_left + 1
	return sb

## Body text colour for a tier. TEXT everywhere except the two fantasy tiers, whose
## dark lacquer grounds want the warm tint rather than the neutral one.
static func rarity_text(tier: int) -> Color:
	return TEXT if clampi(tier, RARITY_COMMON, RARITY_LEGENDARY) < RARITY_EPIC else Color("#F6E3A8")
