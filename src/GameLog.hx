/**
 * Captures text from calls to trace(), up to a set maximum.
 */
class GameLog {
	/**
	 * How many log lines to store.
	 */
	public static inline final LOG_LINES:Int = 20;

	/**
	 * The list of stored log lines.
	 */
	public static var lines(default, null) = new List<String>();

	/**
	 * Add a line of text to the stored log lines. Discards old lines if the buffer is full.
	 * @param line The line to add.
	 */
	public static function add(line:String) {
		lines.add(line);
		if (lines.length > LOG_LINES) {
			lines.pop();
		}
	}
}
