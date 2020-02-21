/**
 * The heaps app containing the game.
 */
class Main extends hxd.App {
	var states:StateManager;

	function setupTracing() {
		// we do this early to capture as many traces as possible
		var originalTrace = haxe.Log.trace;

		@SuppressWarnings("checkstyle:Dynamic")
		function newTrace(v:Dynamic, ?infos:haxe.PosInfos) {
			originalTrace(v, infos);
			GameLog.add(haxe.Log.formatOutput(v, infos));
		}

		haxe.Log.trace = newTrace;
	}

	override function init() {
		setupTracing();

		Input.init();

		s2d.scaleMode = h2d.Scene.ScaleMode.LetterBox(1280, 800);
		trace('scaleMode set to ${s2d.scaleMode}');

		hxd.Res.initEmbed();
		trace("intialised resource system");

		states = new StateManager();

		states.addHook(state -> if (state != null) setScene(state));
		states.push(new states.Game());
	}

	override function update(dt:Float) {
		states.update(dt);
	}

	static function main() {
		new Main();
	}
}
