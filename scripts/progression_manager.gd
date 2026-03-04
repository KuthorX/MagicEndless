extends Node

const SAVE_PATH := "user://progression.cfg"
const SECTION_STATS := "stats"
const SECTION_UPGRADES := "upgrades"
const SECTION_SKILLS := "skills"

var score_bank := 0
var total_earned := 0
var best_run_score := 0

var hp_level := 0
var atk_level := 0
var speed_level := 0
var magic_level := 0
var melee_branch_level := 0
var ranged_branch_level := 0
var spell_branch_level := 0

var unlock_arcane_bolt := false
var unlock_frost_nova := false

func _ready() -> void:
	_load()

func add_run_score(score: int) -> void:
	var gained: int = maxi(0, score)
	score_bank += gained
	total_earned += gained
	best_run_score = maxi(best_run_score, gained)
	_save()

func get_player_meta() -> Dictionary:
	return {
		"hp_bonus": 14.0 * float(hp_level),
		"atk_bonus": 3 * atk_level,
		"speed_mul": 1.0 + 0.03 * float(speed_level),
		"magic_mul": 1.0 + 0.12 * float(magic_level),
		"melee_damage_add": 5 * melee_branch_level,
		"melee_radius_add": 4.0 * float(melee_branch_level),
		"ranged_damage_add": 4 * ranged_branch_level,
		"ranged_speed_add": 18.0 * float(ranged_branch_level),
		"ranged_cd_mul": maxf(0.72, 1.0 - 0.025 * float(ranged_branch_level)),
		"spell_power_mul": 1.0 + 0.14 * float(spell_branch_level),
		"spell_haste_mul": 1.0 + 0.08 * float(spell_branch_level),
		"arcane_bolt": unlock_arcane_bolt,
		"frost_nova": unlock_frost_nova
	}

func hp_cost() -> int:
	return 80 + hp_level * 45

func atk_cost() -> int:
	return 90 + atk_level * 50

func speed_cost() -> int:
	return 110 + speed_level * 55

func magic_cost() -> int:
	return 140 + magic_level * 70

func melee_branch_cost() -> int:
	return 180 + melee_branch_level * 120

func ranged_branch_cost() -> int:
	return 180 + ranged_branch_level * 120

func spell_branch_cost() -> int:
	return 220 + spell_branch_level * 150

func arcane_bolt_cost() -> int:
	return 520

func frost_nova_cost() -> int:
	return 980

func buy_hp() -> bool:
	var c := hp_cost()
	if score_bank < c:
		return false
	score_bank -= c
	hp_level += 1
	_save()
	return true

func buy_atk() -> bool:
	var c := atk_cost()
	if score_bank < c:
		return false
	score_bank -= c
	atk_level += 1
	_save()
	return true

func buy_speed() -> bool:
	var c := speed_cost()
	if score_bank < c:
		return false
	score_bank -= c
	speed_level += 1
	_save()
	return true

func buy_magic() -> bool:
	var c := magic_cost()
	if score_bank < c:
		return false
	score_bank -= c
	magic_level += 1
	_save()
	return true

func buy_melee_branch() -> bool:
	var c := melee_branch_cost()
	if score_bank < c:
		return false
	score_bank -= c
	melee_branch_level += 1
	_save()
	return true

func buy_ranged_branch() -> bool:
	var c := ranged_branch_cost()
	if score_bank < c:
		return false
	score_bank -= c
	ranged_branch_level += 1
	_save()
	return true

func buy_spell_branch() -> bool:
	var c := spell_branch_cost()
	if score_bank < c:
		return false
	score_bank -= c
	spell_branch_level += 1
	_save()
	return true

func buy_arcane_bolt() -> bool:
	if unlock_arcane_bolt:
		return false
	var c := arcane_bolt_cost()
	if score_bank < c:
		return false
	score_bank -= c
	unlock_arcane_bolt = true
	_save()
	return true

func buy_frost_nova() -> bool:
	if unlock_frost_nova:
		return false
	var c := frost_nova_cost()
	if score_bank < c:
		return false
	score_bank -= c
	unlock_frost_nova = true
	_save()
	return true

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION_STATS, "score_bank", score_bank)
	cfg.set_value(SECTION_STATS, "total_earned", total_earned)
	cfg.set_value(SECTION_STATS, "best_run_score", best_run_score)
	cfg.set_value(SECTION_UPGRADES, "hp_level", hp_level)
	cfg.set_value(SECTION_UPGRADES, "atk_level", atk_level)
	cfg.set_value(SECTION_UPGRADES, "speed_level", speed_level)
	cfg.set_value(SECTION_UPGRADES, "magic_level", magic_level)
	cfg.set_value(SECTION_UPGRADES, "melee_branch_level", melee_branch_level)
	cfg.set_value(SECTION_UPGRADES, "ranged_branch_level", ranged_branch_level)
	cfg.set_value(SECTION_UPGRADES, "spell_branch_level", spell_branch_level)
	cfg.set_value(SECTION_SKILLS, "unlock_arcane_bolt", unlock_arcane_bolt)
	cfg.set_value(SECTION_SKILLS, "unlock_frost_nova", unlock_frost_nova)
	cfg.save(SAVE_PATH)

func _load() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return
	score_bank = int(cfg.get_value(SECTION_STATS, "score_bank", 0))
	total_earned = int(cfg.get_value(SECTION_STATS, "total_earned", 0))
	best_run_score = int(cfg.get_value(SECTION_STATS, "best_run_score", 0))
	hp_level = int(cfg.get_value(SECTION_UPGRADES, "hp_level", 0))
	atk_level = int(cfg.get_value(SECTION_UPGRADES, "atk_level", 0))
	speed_level = int(cfg.get_value(SECTION_UPGRADES, "speed_level", 0))
	magic_level = int(cfg.get_value(SECTION_UPGRADES, "magic_level", 0))
	melee_branch_level = int(cfg.get_value(SECTION_UPGRADES, "melee_branch_level", 0))
	ranged_branch_level = int(cfg.get_value(SECTION_UPGRADES, "ranged_branch_level", 0))
	spell_branch_level = int(cfg.get_value(SECTION_UPGRADES, "spell_branch_level", 0))
	unlock_arcane_bolt = bool(cfg.get_value(SECTION_SKILLS, "unlock_arcane_bolt", false))
	unlock_frost_nova = bool(cfg.get_value(SECTION_SKILLS, "unlock_frost_nova", false))
