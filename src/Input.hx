/**
 * An action associated with one or more inputs.
 */
enum Action {
    moveX;
    moveY;
    slap;
    start;
}

/**
 * Which pad to get input from.
 */
enum PadIndex {
    anyone;
    player(index:Int);
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

    function setupAxisMap(pad:hxd.Pad, padIndex:Int) {
        axisMaps[padIndex] = [moveX => () -> pad.xAxis, moveY => () -> pad.yAxis];
    }

    function setupButtonMap(pad:hxd.Pad, padIndex:Int) {
        buttonMaps[padIndex] = [slap => pad.config.A, start => pad.config.start];
    }

    function getAvailablePadIndex():Int {
        for (i in 0...MAX_PADS) {
            if (!pads[i].connected) {
                return i;
            }
        }
        return -1;
    }

    function onPad(pad:hxd.Pad) {
        var padIndex = getAvailablePadIndex();
        if (padIndex < 0) {
            trace("pad connected but no available indices");
            return;
        }
        trace('pad connected and assigned to index $padIndex');
        pads[padIndex] = pad;
        setupAxisMap(pad, padIndex);
        setupButtonMap(pad, padIndex);
    }

    /**
     * Gets an axis' current value.
     * @param action The action assigned to the axis.
     * @param padIndex The index of the pad to get the axis state from.
     * @return Float The axis value from -1 to 1.
     */
    public static function getAxis(action:Action, padIndex:PadIndex):Float {
        switch (padIndex) {
            case anyone:
                trace("can't get axis without a specific pad index");
                return 0.0;
            case player(index):
                return instance.axisMaps[index][action]();
        }
    }

    static function getInputState(action:Action, padIndex:PadIndex, stateFunction:Int->Bool):Bool {
        var state = false;
        switch (padIndex) {
            case anyone:
                for (i in 0...MAX_PADS) {
                    if (stateFunction(i)) {
                        state = true;
                        break;
                    }
                }
            case player(index):
                state = stateFunction(index);
        }
        return state;
    }

    /**
     * Gets a button's current pressed state.
     * @param action The action assigned to the button.
     * @param padIndex The index of the pad to get the button state from.
     * @return Bool
     */
    public static function getButtonDown(action:Action, padIndex:PadIndex = anyone):Bool {
        function isDown(index:Int):Bool {
            var button = instance.buttonMaps[index][action];
            return instance.pads[index].isDown(button);
        }
        return getInputState(action, padIndex, isDown);
    }

    /**
     * Return whether a button was pressed this frame or not.
     * @param action The action assigned to the button.
     * @param padIndex The index of the pad to get the button state from.
     * @return Bool
     */
    public static function getButtonPressed(action:Action, padIndex:PadIndex = anyone):Bool {
        function isDown(index:Int):Bool {
            var button = instance.buttonMaps[index][action];
            return instance.pads[index].isPressed(button);
        }
        return getInputState(action, padIndex, isDown);
    }

    /**
     * Return whether a button was released this frame or not.
     * @param action The action assigned to the button.
     * @param padIndex The index of the pad to get the button state from.
     * @return Bool
     */
    public static function getButtonReleased(action:Action, padIndex:PadIndex = anyone):Bool {
        function isDown(index:Int):Bool {
            var button = instance.buttonMaps[index][action];
            return instance.pads[index].isReleased(button);
        }
        return getInputState(action, padIndex, isDown);
    }
}
