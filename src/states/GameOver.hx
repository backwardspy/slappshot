package states;

/**
 * The "game over" screen state.
 */
class GameOver extends State {
	var logWindow:GameLogWindow;

	public function new(winningSide:Side) {
		trace("initialising gameover state...");
		super();
		var text = new h2d.Text(hxd.res.DefaultFont.get(), this);
		text.text = '$winningSide wins!';
		text.textAlign = Center;
		text.setPosition(width / 2, height / 2);

		logWindow = new GameLogWindow(this);

		trace("gameover state initialised");
	}

	override function update(dt:Float) {
		logWindow.update(dt);
	}
}
