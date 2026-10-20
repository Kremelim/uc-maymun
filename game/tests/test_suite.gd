class_name TestSuite
extends RefCounted
## Base class for unit tests (see run_unit_tests.gd). Assertions record a
## failure and let the test continue, so one run reports every problem.

var failures := PackedStringArray()


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("%s: expected %s, got %s" % [message, var_to_str(expected), var_to_str(actual)])


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		failures.append(message if message != "" else "expected true")
