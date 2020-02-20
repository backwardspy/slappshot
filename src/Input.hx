enum Action {
	MoveX;
	MoveY;
	Slap;
}

class Input {
	static var instance:Input;

	var pads = new Array<hxd.Pad>();

	var axisMaps:Array<Map<Action, Void->Float>> = [for (_ in 0...MAX_PADS) null];
	var buttonMaps:Array<Map<Action, Int>> = [for (_ in 0...MAX_PADS) null];

	static inline final MAX_PADS = 4;

	public static function init() {
		if (instance == null)
			instance = new Input();
	}

	function new() {
		trace("initialising input system...");
		for (i in 0...MAX_PADS) {
			var pad = hxd.Pad.createDummy();
			pads.push(pad);
			setupAxisMap(pad, i);
			setupButtonMap(pad, i);
		}
		hxd.Pad.wait(onPad);
		trace("input system initialised");
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

	function onPad(pad:hxd.Pad) {
		trace('pad connected: ${pad}');
		pads[pad.index] = pad;
		setupAxisMap(pad);
		setupButtonMap(pad);
	}

	public static function getAxis(action:Action, padIndex:Int = 0):Float {
		return instance.axisMaps[padIndex][action]();
	}

	public static function getButtonDown(action:Action, padIndex:Int = 0):Bool {
		var button = instance.buttonMaps[padIndex][action];
		return instance.pads[padIndex].isDown(button);
	}

	public static function getButtonPressed(action:Action, padIndex:Int = 0):Bool {
		var button = instance.buttonMaps[padIndex][action];
		return instance.pads[padIndex].isPressed(button);
	}

	public static function getButtonReleased(action:Action, padIndex:Int = 0):Bool {
		var button = instance.buttonMaps[padIndex][action];
		return instance.pads[padIndex].isReleased(button);
	}
}
