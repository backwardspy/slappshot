/**
 * An action associated with one or more inputs.
 */
enum Action {
    moveX;
    moveY;
    slap;
}

/**
 * A singleton class controlling game input.
 */
class Input {
    static var instance:Input;

    var pads:Array<hxd.Pad>;

    var axisMaps:Array<Map<Action, Void->Float>> = [for (_ in 0...MAX_PADS) null];
    var buttonMaps:Array<Map<Action, Int>> = [for (_ in 0...MAX_PADS) null];

    static inline final MAX_PADS:Int = 4;

    function new() {
        pads = [];
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

    /**
     * Initialise the singleton instance on the first call. Subsequent calls to this function do nothing.
     */
    public static function init() {
        if (instance == null) {
            instance = new Input();
        }
    }

    function setupAxisMap(pad:hxd.Pad, padIndex:Int = -1) {
        if (pad.connected) {
            padIndex = pad.index;
        }
        axisMaps[padIndex] = [moveX => () -> pad.xAxis, moveY => () -> pad.yAxis];
    }

    function setupButtonMap(pad:hxd.Pad, padIndex:Int = -1) {
        if (pad.connected) {
            padIndex = pad.index;
        }
        buttonMaps[padIndex] = [slap => pad.config.A];
    }

    function onPad(pad:hxd.Pad) {
        trace('pad #${pad.index} connected');
        pads[pad.index] = pad;
        setupAxisMap(pad);
        setupButtonMap(pad);
    }

    /**
     * Gets an axis' current value.
     * @param action The action assigned to the axis.
     * @param padIndex The index of the pad to get the axis state from.
     * @return Float The axis value from -1 to 1.
     */
    public static function getAxis(action:Action, padIndex:Int = 0):Float {
        return instance.axisMaps[padIndex][action]();
    }

    /**
     * Gets a button's current pressed state.
     * @param action The action assigned to the button.
     * @param padIndex The index of the pad to get the button state from.
     * @return Bool
     */
    public static function getButtonDown(action:Action, padIndex:Int = 0):Bool {
        var button = instance.buttonMaps[padIndex][action];
        return instance.pads[padIndex].isDown(button);
    }

    /**
     * Return whether a button was pressed this frame or not.
     * @param action The action assigned to the button.
     * @param padIndex The index of the pad to get the button state from.
     * @return Bool
     */
    public static function getButtonPressed(action:Action, padIndex:Int = 0):Bool {
        var button = instance.buttonMaps[padIndex][action];
        return instance.pads[padIndex].isPressed(button);
    }

    /**
     * Return whether a button was released this frame or not.
     * @param action The action assigned to the button.
     * @param padIndex The index of the pad to get the button state from.
     * @return Bool
     */
    public static function getButtonReleased(action:Action, padIndex:Int = 0):Bool {
        var button = instance.buttonMaps[padIndex][action];
        return instance.pads[padIndex].isReleased(button);
    }
}
