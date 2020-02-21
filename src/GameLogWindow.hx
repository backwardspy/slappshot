/**
 * Renders traced logs to a scene.
 */
class GameLogWindow extends h2d.Object {
	static inline final LINE_HEIGHT:Int = 16;
	static inline final PADDING:Int = 4;

	var texts:Array<h2d.Text>;

	public function new(scene:h2d.Scene) {
		super(scene);

		texts = [];

		var font = hxd.res.DefaultFont.get();
		for (i in 0...GameLog.LOG_LINES) {
			var text = new h2d.Text(font, this);
			text.setPosition(PADDING, scene.height - (i + 1) * LINE_HEIGHT - PADDING);
			texts.push(text);
		}
	}

	/**
	 * Updates the text content of the GameLogWindow.
	 * @param dt Delta time.
	 */
	public function update(dt:Float) {
		var idx = GameLog.lines.length;
		for (line in GameLog.lines) {
			texts[--idx].text = line;
		}
	}
}
