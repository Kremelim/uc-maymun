class_name ErrorCollector
extends Logger
## Collects engine errors, so a test or a simulation that errors out cannot pass
## silently (GDScript would otherwise just skip the rest of the failing function).
## Register with OS.add_logger(), read with take().

var _errors := PackedStringArray()
var _mutex := Mutex.new()


func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array) -> void:
	_mutex.lock()
	_errors.append("%s (%s:%d in %s)" % [rationale if rationale != "" else code, file, line, function])
	_mutex.unlock()


## Returns the errors collected so far and starts over.
func take() -> PackedStringArray:
	_mutex.lock()
	var taken := _errors
	_errors = PackedStringArray()
	_mutex.unlock()
	return taken
