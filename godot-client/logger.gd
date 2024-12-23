extends Node

const FORMAT: String = "%s - %s - %s"
const DEBUG: String = "debug"
const INFO: String = "info"
const WARNING: String = "warning"
const ERROR: String = "error"

func debug(message):
	if (Config.get_log_level() == DEBUG):
		_log(DEBUG, message)

func info(message):
	if (Config.get_log_level() == INFO or
		Config.get_log_level() == DEBUG):
		_log(INFO, message)

func warning(message):
	if (Config.get_log_level() == WARNING or
		Config.get_log_level() == INFO or
		Config.get_log_level() == DEBUG):
		_log(WARNING, message)

func error(message):
	if (Config.get_log_level() == ERROR or
		Config.get_log_level() == WARNING or
		Config.get_log_level() == INFO or
		Config.get_log_level() == DEBUG):
		_log(ERROR, message)

func _format_time():
	var time = Time.get_time_dict_from_system()
	return '%02d:%02d:%02d' % [time.hour, time.minute, time.second]

func _log(level, message):
	var log_message = FORMAT % [_format_time(), level, message]
	print(log_message)
