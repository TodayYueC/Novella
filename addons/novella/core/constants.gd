extends RefCounted

const VERSION := "1.3.0"
const MIN_GODOT_MAJOR := 4
const MIN_GODOT_MINOR := 3
const PRIMARY_GODOT_MAJOR := 4
const PRIMARY_GODOT_MINOR := 6

enum VariableScope {
	GAME,
	GLOBAL,
	SETTINGS,
}

enum VariableType {
	INT,
	FLOAT,
	BOOL,
	STRING,
	FLAG_SET,
	LIST,
	DICTIONARY,
	ANY,
}

const EVENT_PLUGIN_READY := &"plugin_ready"
const EVENT_SCRIPT_STARTED := &"script_started"
const EVENT_SCRIPT_FINISHED := &"script_finished"
const EVENT_NODE_COMPLETED := &"node_completed"
const EVENT_VARIABLE_CHANGED := &"variable_changed"
const EVENT_COMMAND_EXECUTED := &"command_executed"
const EVENT_RUNTIME_ERROR := &"runtime_error"

const DEFAULT_TEXT_SPEED := 35.0
const DEFAULT_AUTO_DELAY := 1.5
const DEFAULT_ROLLBACK_LIMIT := 100
const DEFAULT_MAX_CALL_DEPTH := 256
const DEFAULT_MAX_LOOP_ITERATIONS := 10000
