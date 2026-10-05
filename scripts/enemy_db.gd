class_name EnemyDB
extends RefCounted
## Every monster: sprite key, stats, and how it fights.
## Speeds are deliberately LOW — monsters lumber, the player dances.

const TYPES := {
	"goblin": {
		"key": "monster/goblin/goblin",
		"name": "Goblin",
		"hp": 22, "speed": 34.0, "damage": 7, "xp": 5, "gold": 4,
		"size_px": 19, "radius": 4.5,
		"tint": Color(1, 1, 1),
		"behaviour": "chase", "attack_range": 22.0, "attack_cd": 1.15,
		"min_depth": 1, "weight": 10.0, "elite": false,
	},
	"imp": {
		"key": "monster/imp/imp",
		"name": "Imp",
		"hp": 16, "speed": 30.0, "damage": 6, "xp": 5, "gold": 5,
		"size_px": 19, "radius": 4.5,
		"tint": Color(1, 0.85, 0.9),
		"behaviour": "chase", "attack_range": 20.0, "attack_cd": 1.0,
		"min_depth": 1, "weight": 8.0, "elite": false,
	},
	"chort": {
		"key": "monster/chort/chort",
		"name": "Chort",
		"hp": 30, "speed": 32.0, "damage": 9, "xp": 7, "gold": 6,
		"size_px": 21, "radius": 5.0,
		"tint": Color(1, 1, 1),
		"behaviour": "chase", "attack_range": 24.0, "attack_cd": 1.3,
		"min_depth": 2, "weight": 9.0, "elite": false,
	},
	"elemental_goo": {
		"key": "monster/elemental_goo/elemental_goo",
		"name": "Elemental Goo",
		"hp": 40, "speed": 22.0, "damage": 8, "xp": 8, "gold": 7,
		"size_px": 20, "radius": 5.0,
		"tint": Color(0.6, 1.0, 0.7),
		"behaviour": "wander", "attack_range": 22.0, "attack_cd": 1.6,
		"min_depth": 2, "weight": 7.0, "elite": false,
	},
	"orc_warrior": {
		"key": "monster/orc_warrior/orc_warrior",
		"name": "Orc Warrior",
		"hp": 46, "speed": 30.0, "damage": 12, "xp": 11, "gold": 9,
		"size_px": 22, "radius": 5.0,
		"tint": Color(1, 1, 1),
		"behaviour": "chase", "attack_range": 26.0, "attack_cd": 1.35,
		"min_depth": 3, "weight": 9.0, "elite": false,
	},
	"zombie": {
		"key": "monster/zombie/zombie",
		"name": "Zombie",
		"hp": 52, "speed": 18.0, "damage": 11, "xp": 9, "gold": 6,
		"size_px": 22, "radius": 5.0,
		"tint": Color(0.85, 1.0, 0.85),
		"behaviour": "chase", "attack_range": 24.0, "attack_cd": 1.7,
		"min_depth": 3, "weight": 8.0, "elite": false,
	},
	"orc_shaman": {
		"key": "monster/orc_shaman/orc_shaman",
		"name": "Orc Shaman",
		"hp": 34, "speed": 26.0, "damage": 10, "xp": 12, "gold": 11,
		"size_px": 22, "radius": 5.0,
		"tint": Color(0.85, 0.9, 1.0),
		"behaviour": "caster", "attack_range": 170.0, "attack_cd": 2.1,
		"min_depth": 4, "weight": 6.0, "elite": false,
	},
	"pumpkin_dude": {
		"key": "monster/pumpkin_dude/pumpkin_dude",
		"name": "Pumpkin Fiend",
		"hp": 58, "speed": 27.0, "damage": 13, "xp": 14, "gold": 12,
		"size_px": 22, "radius": 5.0,
		"tint": Color(1, 0.95, 0.85),
		"behaviour": "chase", "attack_range": 26.0, "attack_cd": 1.25,
		"min_depth": 4, "weight": 6.0, "elite": false,
	},
	"necromancer": {
		"key": "monster/necromancer/necromancer",
		"name": "Necromancer",
		"hp": 44, "speed": 24.0, "damage": 12, "xp": 16, "gold": 15,
		"size_px": 22, "radius": 5.0,
		"tint": Color(0.9, 0.8, 1.0),
		"behaviour": "caster", "attack_range": 200.0, "attack_cd": 1.9,
		"min_depth": 5, "weight": 5.5, "elite": false,
	},
	"ice_zombie": {
		"key": "monster/ice_zombie/ice_zombie",
		"name": "Ice Zombie",
		"hp": 66, "speed": 20.0, "damage": 15, "xp": 15, "gold": 12,
		"size_px": 22, "radius": 5.0,
		"tint": Color(0.75, 0.95, 1.0),
		"behaviour": "chase", "attack_range": 24.0, "attack_cd": 1.6,
		"min_depth": 5, "weight": 6.0, "elite": false,
	},
	"ogre": {
		"key": "monster/ogre/ogre",
		"name": "Ogre",
		"hp": 96, "speed": 21.0, "damage": 19, "xp": 24, "gold": 22,
		"size_px": 28, "radius": 6.5,
		"tint": Color(1, 1, 1),
		"behaviour": "chase", "attack_range": 30.0, "attack_cd": 1.7,
		"min_depth": 6, "weight": 5.0, "elite": true,
	},
	"big_zombie": {
		"key": "monster/big_zombie/big_zombie",
		"name": "Abomination",
		"hp": 112, "speed": 19.0, "damage": 21, "xp": 27, "gold": 24,
		"size_px": 28, "radius": 6.5,
		"tint": Color(0.85, 1.0, 0.85),
		"behaviour": "chase", "attack_range": 30.0, "attack_cd": 1.8,
		"min_depth": 7, "weight": 4.5, "elite": true,
	},
	"big_daemon": {
		"key": "monster/big_daemon/big_daemon",
		"name": "Daemon",
		"hp": 128, "speed": 24.0, "damage": 23, "xp": 32, "gold": 30,
		"size_px": 28, "radius": 6.5,
		"tint": Color(1, 0.8, 0.75),
		"behaviour": "chase", "attack_range": 30.0, "attack_cd": 1.5,
		"min_depth": 8, "weight": 4.0, "elite": true,
	},
	"doc": {
		"key": "monster/doc/doc",
		"name": "The Doctor",
		"hp": 78, "speed": 26.0, "damage": 16, "xp": 20, "gold": 18,
		"size_px": 22, "radius": 5.0,
		"tint": Color(1, 1, 1),
		"behaviour": "caster", "attack_range": 190.0, "attack_cd": 1.6,
		"min_depth": 6, "weight": 4.0, "elite": false,
	},
}

## Depth-scaled boss roster.
const BOSSES := {
	3:  {"id": "ogre",       "title": "GRUKK, THE BONE-BREAKER", "hp_mult": 3.4, "dmg_mult": 1.25, "scale": 3.2},
	6:  {"id": "big_zombie", "title": "THE STITCHED ABOMINATION", "hp_mult": 3.8, "dmg_mult": 1.3,  "scale": 3.4},
	9:  {"id": "necromancer", "title": "MALVOTH THE SOULBINDER",  "hp_mult": 4.2, "dmg_mult": 1.4,  "scale": 3.0},
	12: {"id": "big_daemon", "title": "VHAROS, DAEMON PRINCE",   "hp_mult": 5.0, "dmg_mult": 1.5,  "scale": 3.4},
	15: {"id": "doc",        "title": "THE ARCHITECT OF RUIN",   "hp_mult": 5.6, "dmg_mult": 1.6,  "scale": 3.0},
}


static func for_depth(depth: int, rng: RandomNumberGenerator) -> String:
	var pool: Array = []
	for id in TYPES:
		var t: Dictionary = TYPES[id]
		if depth >= int(t["min_depth"]):
			# weight decays slightly with depth for trash mobs, so the roster rotates
			var w := float(t["weight"]) * (1.0 + 0.05 * maxi(0, depth - int(t["min_depth"])))
			for _i in int(round(w)):
				pool.append(id)
	if pool.is_empty():
		return "goblin"
	return pool[rng.randi_range(0, pool.size() - 1)]


static func boss_for_depth(depth: int) -> Dictionary:
	for d in BOSSES:
		if depth == d:
			return BOSSES[d]
	return {}


static func stats(id: String, depth: int, hp_mult: float = 1.0, dmg_mult: float = 1.0) -> Dictionary:
	var t: Dictionary = TYPES.get(id, TYPES["goblin"]).duplicate(true)
	var growth := 1.0 + 0.16 * float(depth - 1)
	t["hp"] = int(round(float(t["hp"]) * growth * hp_mult))
	t["damage"] = int(round(float(t["damage"]) * (1.0 + 0.10 * float(depth - 1)) * dmg_mult))
	t["xp"] = int(round(float(t["xp"]) * (1.0 + 0.10 * float(depth - 1))))
	t["gold"] = int(round(float(t["gold"]) * (1.0 + 0.12 * float(depth - 1))))
	t["id"] = id
	return t


## Short flavour line for the bestiary panel.
static func lore(id: String) -> String:
	match id:
		"goblin": return "Small, greedy, and everywhere. Weak alone, a problem in sixes."
		"imp": return "Barely a threat. It knows this, which is why it brings friends."
		"chort": return "Hooved and bad-tempered. Charges in a straight line."
		"elemental_goo": return "Slow, acidic, and patient. It will find you eventually."
		"orc_warrior": return "Disciplined. Heavy swings, long recovery — punish the recovery."
		"zombie": return "Shambles toward you. Almost no speed, almost no mercy."
		"orc_shaman": return "Keeps its distance and throws fire. Close the gap."
		"pumpkin_dude": return "Something went wrong in the harvest. It still smiles."
		"necromancer": return "Raises the dead. Kill it first."
		"ice_zombie": return "Frozen solid mid-scream. Still walking."
		"ogre": return "Elite. Enormous reach. Do not trade hits."
		"big_zombie": return "Elite. Several bodies, one purpose."
		"big_daemon": return "Elite. Born of the rift, allergic to nothing."
		"doc": return "Elite. Experiments on things that were once adventurers."
		_: return "Unknown."
