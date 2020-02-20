enum Action {
	MoveX;
	MoveY;
	Slap;
}

class Input {
	private static var input = new Input();

	private var pads = new Array<hxd.Pad>();

	private var axisMaps:Array<Map<Action, Void->Float>> = [for (_ in 0...MAX_PADS) null];
	private var buttonMaps:Array<Map<Action, Int>> = [for (_ in 0...MAX_PADS) null];

	static inline final MAX_PADS = 4;

	private function new() {
		for (i in 0...MAX_PADS) {
			var pad = hxd.Pad.createDummy();
			pads.push(pad);
			setupAxisMap(pad, i);
			setupButtonMap(pad, i);
		}
		hxd.Pad.wait(onPad);
	}

	function setupAxisMap(pad:hxd.Pad, padIndex:Int = -1) {
		if (pad.connected)
			padIndex = pad.index;
		axisMaps[padIndex] = [MoveX => () -> pad.xAxis, MoveY => () -> pad.yAxis];
	}

	function setupButtonMap(pad:hxd.Pad, padIndex:Int = -1) {
		if (pad.connected)
			padIndex = pad.index;
		buttonMaps[padIndex] = [Slap => pad.config.A];
	}

	private function onPad(pad:hxd.Pad) {
		pads[pad.index] = pad;
		setupAxisMap(pad);
		setupButtonMap(pad);
	}

	public static function getAxis(action:Action, padIndex:Int = 0):Float {
		return input.axisMaps[padIndex][action]();
	}

	public static function getButtonDown(action:Action, padIndex:Int = 0):Bool {
		var button = input.buttonMaps[padIndex][action];
		return input.pads[padIndex].isDown(button);
	}

	public static function getButtonPressed(action:Action, padIndex:Int = 0):Bool {
		var button = input.buttonMaps[padIndex][action];
		return input.pads[padIndex].isPressed(button);
	}

	public static function getButtonReleased(action:Action, padIndex:Int = 0):Bool {
		var button = input.buttonMaps[padIndex][action];
		return input.pads[padIndex].isReleased(button);
	}
}
