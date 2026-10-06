extends Node

## Screenshot hook for headless visual checks. Reads `?shot=<state>` on web or
## `-- --shot=<state>` on desktop. Empty (and ignored) in normal play.
## States: menu, codex, potential, settings, gameplay, cards, gameover.

const ARG_PREFIX := "--shot="
const QUERY_KEY := "shot"

var mode := ""

func _ready() -> void:
	mode = _read_mode()

func is_battle_shot() -> bool:
	return mode == "gameplay" or mode == "cards" or mode == "gameover"

func _read_mode() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(ARG_PREFIX):
			return arg.substr(ARG_PREFIX.length())
	if not OS.has_feature("web") or not Engine.has_singleton("JavaScriptBridge"):
		return ""
	var search: Variant = JavaScriptBridge.eval("window.location.search", true)
	if search == null:
		return ""
	for pair in str(search).trim_prefix("?").split("&", false):
		var kv := pair.split("=")
		if kv.size() == 2 and kv[0] == QUERY_KEY:
			return kv[1]
	return ""
