class_name CmdArgs
extends RefCounted
## Reads our own command-line flags (e.g. --auto-host, --win=2).
## Godot hands user arguments over after "--"; we also accept them before it.


static func has_flag(flag: String) -> bool:
	return flag in _all()


static func value(key: String, default: String = "") -> String:
	var prefix := key + "="
	for arg in _all():
		if arg.begins_with(prefix):
			return arg.substr(prefix.length())
	return default


static func _all() -> PackedStringArray:
	return OS.get_cmdline_args() + OS.get_cmdline_user_args()
