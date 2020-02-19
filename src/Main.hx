class Main extends hxd.App {
	var states = new StateManager();

	override function init() {
		s2d.scaleMode = h2d.Scene.ScaleMode.LetterBox(1280, 800);

		hxd.Res.initEmbed();

		states.addHook((state:State) -> if (state != null) setScene(state));
		states.push(new states.Game());
	}

	override function update(dt:Float) {
		states.top().update(dt);
	}

	static function main() {
		new Main();
	}
}
