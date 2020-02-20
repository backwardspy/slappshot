class GameLogWindow extends h2d.Object {
	var texts = new Array<h2d.Text>();

	public function new(scene:h2d.Scene) {
		super(scene);

		var font = hxd.res.DefaultFont.get();
		for (i in 0...GameLog.LOG_LINES) {
			var text = new h2d.Text(font, this);
			text.setPosition(4, scene.height - (i + 1) * 16 - 4);
			texts.push(text);
		}
	}

	public function update(dt:Float) {
		var idx = GameLog.lines.length;
		for (line in GameLog.lines) {
			texts[--idx].text = line;
		}
	}
}
