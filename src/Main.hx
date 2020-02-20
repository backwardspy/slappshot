class Main extends hxd.App {
	var states = new StateManager();

	override function init() {
		// we do this early to capture as many traces as possible
		var originalTrace = haxe.Log.trace;
		haxe.Log.trace = function(v:Dynamic, ?infos:haxe.PosInfos) {
			originalTrace(v, infos);
			GameLog.add(haxe.Log.formatOutput(v, infos));
		}

		Input.init();

		s2d.scaleMode = h2d.Scene.ScaleMode.LetterBox(1280, 800);
		trace('scaleMode set to ${s2d.scaleMode}');

		hxd.Res.initEmbed();
		trace("intialised resource system");

		trace("pushing game state...");
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
