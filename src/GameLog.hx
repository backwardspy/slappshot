class GameLog {
	public static inline final LOG_LINES = 20;

	public static var lines(default, null) = new List<String>();

	function new() {}

	public static function add(line:String) {
		lines.add(line);
		if (lines.length > LOG_LINES)
			lines.pop();
	}
}
