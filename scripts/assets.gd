class_name Assets
extends RefCounted
## Single source of truth for every asset path in the game.
## All art is CC0 (Kenney + 0x72 via the Dungeon-CampusMinden project).

const PACK := "res://assets/dungeon_pack/"
const KENNEY := "res://assets/kenney/"

# --- Biomes ---------------------------------------------------------------
const BIOMES: Array[String] = ["default", "dark", "fire", "ice", "forest", "temple", "rainbow"]

const BIOME_NAMES := {
	"default": "Stone Halls",
	"dark": "Umbral Depths",
	"fire": "Emberreach",
	"ice": "Frostvault",
	"forest": "Thornwild",
	"temple": "Sunken Temple",
	"rainbow": "Prismatic Rift",
}

const BIOME_ACCENT := {
	"default": Color("#9fb4d8"),
	"dark":    Color("#a884e8"),
	"fire":    Color("#ff8a4c"),
	"ice":     Color("#7fd8ff"),
	"forest":  Color("#7ede9a"),
	"temple":  Color("#ffd479"),
	"rainbow": Color("#ff9ee8"),
}

# --- Tile helpers ----------------------------------------------------------
static func floor_tile(biome: String, variant: int = 0) -> String:
	var names := ["floor/floor_1.png", "floor/floor_damaged.png", "floor/floor_1.png", "floor/floor_1.png"]
	return PACK + "dungeon/" + biome + "/" + names[variant % names.size()]


static func wall_tile(biome: String) -> String:
	# default lacks wall_top.png but has a fully-opaque wall_inner_top.png
	if biome == "default":
		return PACK + "dungeon/default/wall/wall_inner_top.png"
	return PACK + "dungeon/" + biome + "/wall/wall_top.png"


static func door_tile(biome: String) -> String:
	return PACK + "dungeon/" + biome + "/door/top.png"


static func ladder_tile(biome: String) -> String:
	return PACK + "dungeon/" + biome + "/floor/floor_ladder.png"


static func pit_tile(biome: String) -> String:
	return PACK + "dungeon/" + biome + "/floor/pit_open.png"


# --- Items -----------------------------------------------------------------
static func item(id: String) -> String:
	match id:
		"health_potion": return PACK + "items/potion/health_potion.png"
		"mana_potion": return PACK + "items/potion/mana_potion.png"
		"antidote": return PACK + "items/potion/antidote_potion.png"
		"gold_key": return PACK + "items/key/gold_key.png"
		"small_key": return PACK + "items/key/small_key.png"
		"big_key": return PACK + "items/key/big_key.png"
		"gold": return PACK + "items/resource/gold.png"
		"gem": return PACK + "items/resource/emerald.png"
		"heart": return PACK + "items/pickups/heart_pickup.png"
		"fairy": return PACK + "items/pickups/fairy_pickup.png"
		"sword": return PACK + "items/weapon/legendary_sword.png"
		"fire_sword": return PACK + "items/weapon/fire_sword.png"
		"ice_sword": return PACK + "items/weapon/ice_sword.png"
		"lightning_sword": return PACK + "items/weapon/lightning_sword.png"
		"rainbow_sword": return PACK + "items/weapon/rainbow_sword.png"
		"bow": return PACK + "items/weapon/wooden_bow.png"
		"scroll": return PACK + "items/book/magic_scroll.png"
		"spell_book": return PACK + "items/book/spell_book.png"
		"shield": return PACK + "items/shield/knight_shield.png"
		"necklace": return PACK + "items/necklace/magic_necklace.png"
		"ring": return PACK + "items/ring/heart_ring.png"
		"armor": return PACK + "items/armor/body/plate_armor.png"
		"helmet": return PACK + "items/armor/helmet/plate_helmet.png"
		"bone": return PACK + "items/resource/bone.png"
		"chest": return PACK + "objects/treasurechest/treasurechest.png"
		"torch": return PACK + "objects/torch/torch.png"
		"vase": return PACK + "objects/vase/vase.png"
		"cauldron": return PACK + "objects/cauldron/cauldron.png"
		"lever": return PACK + "objects/lever/lever.png"
		"stone": return PACK + "objects/stone/stone.png"
		"mushroom": return PACK + "objects/mushroom.png"
		"portal": return PACK + "dungeon/default/portal/portal_block.png"
		_: return PACK + "items/resource/bone.png"


static func skill_icon(id: String) -> String:
	match id:
		"fireball": return PACK + "skills/fireball/fireball.png"
		"melee": return PACK + "skills/melee/melee.png"
		_: return PACK + "hud/ui_heart_full.png"


static func emote(id: String) -> String:
	return PACK + "emotes/emote_" + id + ".png"


# --- HUD -------------------------------------------------------------------
const HEART_FULL := PACK + "hud/ui_heart_full.png"
const HEART_HALF := PACK + "hud/ui_heart_half.png"
const HEART_EMPTY := PACK + "hud/ui_heart_empty.png"
const UI_CHECK := PACK + "hud/check.png"
const UI_CROSS := PACK + "hud/cross.png"
const UI_SKULL := PACK + "hud/kenney/skull.png"
const UI_KING := PACK + "hud/kenney/chess_king.png"

# --- Kenney UI 9-slice chrome ---------------------------------------------
const UI_BLUE := KENNEY + "ui_blue/"
const UI_FANTASY := KENNEY + "ui_fantasy_borders/"
const UI_CURSORS := KENNEY + "ui_cursors/"

# --- Fonts -----------------------------------------------------------------
const FONT_TITLE := "res://assets/fonts/Cinzel.ttf"
const FONT_UI := "res://assets/fonts/Inter.ttf"
const FONT_PIXEL := "res://assets/fonts/PixelifySans.ttf"

# --- Sprite manifest (generated) ------------------------------------------
const MANIFEST_PATH := "res://assets/sprite_manifest.json"

static var _manifest: Dictionary = {}

static func manifest() -> Dictionary:
	if _manifest.is_empty():
		var f := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				_manifest = parsed
	return _manifest


static func char_sheet(key: String) -> String:
	return PACK + "character/" + key + ".png"


static func char_anim(key: String, anim: String) -> Dictionary:
	var m := manifest()
	if not m.has(key):
		return {}
	var a: Dictionary = m[key].get("anims", {})
	return a.get(anim, {})
