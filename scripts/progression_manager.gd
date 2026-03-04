extends Node

const BASE_SAVE_FILE := "progression.cfg"
const WEB_STORAGE_KEY := "jx_progression_cfg"
const SECTION_STATS := "stats"
const SECTION_UPGRADES := "upgrades"
const SECTION_SKILLS := "skills"
const SECTION_RELICS := "relics"

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
var unlock_relic_entropy_dial := false
var unlock_relic_oath_anchor := false
var unlock_relic_hazard_compact := false
var _save_path := "user://progression.cfg"

func _ready() -> void:
	_save_path = _resolve_save_path()
	_ensure_save_dir()
	_load()

func add_run_score(score: int) -> void:
	var gained: int = maxi(0, score)
	score_bank += gained
	total_earned += gained
	best_run_score = maxi(best_run_score, gained)
	_save()

func add_cheat_score_from_current(multiplier: int = 10000) -> int:
	var mul := maxi(0, multiplier)
	var gained := maxi(0, score_bank) * mul
	if gained <= 0:
		return 0
	score_bank += gained
	total_earned += gained
	_save()
	return gained

func add_cheat_potential_levels(level_add: int = 1000) -> int:
	var n := maxi(0, level_add)
	if n <= 0:
		return 0
	hp_level += n
	atk_level += n
	speed_level += n
	magic_level += n
	melee_branch_level += n
	ranged_branch_level += n
	spell_branch_level += n
	unlock_arcane_bolt = true
	unlock_frost_nova = true
	_save()
	return n

func export_snapshot() -> Dictionary:
	return {
		"score_bank": score_bank,
		"total_earned": total_earned,
		"best_run_score": best_run_score,
		"hp_level": hp_level,
		"atk_level": atk_level,
		"speed_level": speed_level,
		"magic_level": magic_level,
		"melee_branch_level": melee_branch_level,
		"ranged_branch_level": ranged_branch_level,
		"spell_branch_level": spell_branch_level,
		"unlock_arcane_bolt": unlock_arcane_bolt,
		"unlock_frost_nova": unlock_frost_nova,
		"unlock_relic_entropy_dial": unlock_relic_entropy_dial,
		"unlock_relic_oath_anchor": unlock_relic_oath_anchor,
		"unlock_relic_hazard_compact": unlock_relic_hazard_compact
	}

func import_snapshot(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	score_bank = maxi(0, int(data.get("score_bank", score_bank)))
	total_earned = maxi(0, int(data.get("total_earned", total_earned)))
	best_run_score = maxi(0, int(data.get("best_run_score", best_run_score)))
	hp_level = maxi(0, int(data.get("hp_level", hp_level)))
	atk_level = maxi(0, int(data.get("atk_level", atk_level)))
	speed_level = maxi(0, int(data.get("speed_level", speed_level)))
	magic_level = maxi(0, int(data.get("magic_level", magic_level)))
	melee_branch_level = maxi(0, int(data.get("melee_branch_level", melee_branch_level)))
	ranged_branch_level = maxi(0, int(data.get("ranged_branch_level", ranged_branch_level)))
	spell_branch_level = maxi(0, int(data.get("spell_branch_level", spell_branch_level)))
	unlock_arcane_bolt = bool(data.get("unlock_arcane_bolt", unlock_arcane_bolt))
	unlock_frost_nova = bool(data.get("unlock_frost_nova", unlock_frost_nova))
	unlock_relic_entropy_dial = bool(data.get("unlock_relic_entropy_dial", unlock_relic_entropy_dial))
	unlock_relic_oath_anchor = bool(data.get("unlock_relic_oath_anchor", unlock_relic_oath_anchor))
	unlock_relic_hazard_compact = bool(data.get("unlock_relic_hazard_compact", unlock_relic_hazard_compact))
	_save()
	return true

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

func get_unlocked_relics() -> Array[String]:
	var out: Array[String] = []
	if unlock_relic_entropy_dial:
		out.append("entropy_dial")
	if unlock_relic_oath_anchor:
		out.append("oath_anchor")
	if unlock_relic_hazard_compact:
		out.append("hazard_compact")
	return out

func get_relic_rule_pack(relic_id: String) -> Dictionary:
	match relic_id:
		"entropy_dial":
			return {
				"id": relic_id,
				"title": "relic_entropy_dial_t",
				"desc": "relic_entropy_dial_d",
				"mutation_time_mul": 0.82,
				"directive_interval_mul": 0.88
			}
		"oath_anchor":
			return {
				"id": relic_id,
				"title": "relic_oath_anchor_t",
				"desc": "relic_oath_anchor_d",
				"force_anchor_early": true,
				"anchor_buff_mul": 1.18,
				"objective_trigger_mul": 0.74
			}
		"hazard_compact":
			return {
				"id": relic_id,
				"title": "relic_hazard_compact_t",
				"desc": "relic_hazard_compact_d",
				"extra_hazard_add": 1,
				"force_flux_directive": true,
				"hazard_extra_wave": 1
			}
		_:
			return {}

func register_run_report(report: Dictionary) -> Array[String]:
	var newly_unlocked: Array[String] = []
	var wave_reached := int(report.get("wave_reached", 0))
	var director_peak := float(report.get("director_peak", 0.0))
	var objective_success := int(report.get("objective_success", 0))
	var anchor_breaks := int(report.get("anchor_breaks", 0))
	var hazard_kills := int(report.get("hazard_kills", 0))
	var affliction_waves := int(report.get("affliction_waves", 0))
	if (not unlock_relic_entropy_dial) and wave_reached >= 12 and director_peak >= 0.82 and objective_success >= 4:
		unlock_relic_entropy_dial = true
		newly_unlocked.append("entropy_dial")
	if (not unlock_relic_oath_anchor) and wave_reached >= 10 and anchor_breaks >= 6:
		unlock_relic_oath_anchor = true
		newly_unlocked.append("oath_anchor")
	if (not unlock_relic_hazard_compact) and wave_reached >= 10 and hazard_kills >= 28 and affliction_waves >= 2:
		unlock_relic_hazard_compact = true
		newly_unlocked.append("hazard_compact")
	if not newly_unlocked.is_empty():
		_save()
	return newly_unlocked

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
	cfg.set_value(SECTION_RELICS, "unlock_relic_entropy_dial", unlock_relic_entropy_dial)
	cfg.set_value(SECTION_RELICS, "unlock_relic_oath_anchor", unlock_relic_oath_anchor)
	cfg.set_value(SECTION_RELICS, "unlock_relic_hazard_compact", unlock_relic_hazard_compact)
	cfg.save(_save_path)
	_write_web_backup(cfg)

func _load() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(_save_path)
	if err != OK and OS.has_feature("web"):
		var text := _read_web_backup()
		if text != "":
			err = cfg.parse(text)
	if err != OK:
		return
	_apply_loaded(cfg)

func _apply_loaded(cfg: ConfigFile) -> void:
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
	unlock_relic_entropy_dial = bool(cfg.get_value(SECTION_RELICS, "unlock_relic_entropy_dial", false))
	unlock_relic_oath_anchor = bool(cfg.get_value(SECTION_RELICS, "unlock_relic_oath_anchor", false))
	unlock_relic_hazard_compact = bool(cfg.get_value(SECTION_RELICS, "unlock_relic_hazard_compact", false))

func _resolve_save_path() -> String:
	if OS.has_feature("web"):
		return "user://web/" + BASE_SAVE_FILE
	if OS.has_feature("mobile"):
		return "user://mobile/" + BASE_SAVE_FILE
	return "user://" + BASE_SAVE_FILE

func _ensure_save_dir() -> void:
	var sep := _save_path.rfind("/")
	if sep <= 0:
		return
	var dir_path := _save_path.substr(0, sep)
	DirAccess.make_dir_recursive_absolute(dir_path)

func _write_web_backup(cfg: ConfigFile) -> void:
	if not OS.has_feature("web"):
		return
	if not Engine.has_singleton("JavaScriptBridge"):
		return
	var storage = JavaScriptBridge.get_interface("localStorage")
	if storage == null:
		return
	storage.setItem(WEB_STORAGE_KEY, cfg.encode_to_text())

func _read_web_backup() -> String:
	if not OS.has_feature("web"):
		return ""
	if not Engine.has_singleton("JavaScriptBridge"):
		return ""
	var storage = JavaScriptBridge.get_interface("localStorage")
	if storage == null:
		return ""
	var value: Variant = storage.getItem(WEB_STORAGE_KEY)
	if value == null:
		return ""
	return str(value)
