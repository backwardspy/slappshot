/**
 * An action associated with one or more inputs.
 */
enum Action {
    moveX;
    moveY;
    rotX;
    rotY;
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
 * Function to call after a player connects or disconnects.
 */
typedef PlayerConnectedHook = (ply:Player) -> Void;

/**
 * A singleton class controlling game input.
 */
class Input {
    static var instance:Input;

    var pads:Array<hxd.Pad>;

    var axisMaps:Array<Map<Action, Void->Float>> = [for (_ in 0...PlayerManager.MAX_PLAYERS) null];
    var buttonMaps:Array<Map<Action, Int>> = [for (_ in 0...PlayerManager.MAX_PLAYERS) null];

    var playerConnectedHooks:Array<PlayerConnectedHook>;
    var playerDisconnectedHooks:Array<PlayerConnectedHook>;

    function new() {
        pads = [];
        playerConnectedHooks = [];
        playerDisconnectedHooks = [];
        trace("initialising input system...");
        for (i in 0...PlayerManager.MAX_PLAYERS) {
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
        axisMaps[padIndex] = [
            moveX => () -> pad.xAxis,
            moveY => () -> pad.yAxis,
            rotX => () -> pad.values[pad.config.ranalogX],
            rotY => () -> pad.values[pad.config.ranalogY]
        ];
    }

    function setupButtonMap(pad:hxd.Pad, padIndex:Int) {
        buttonMaps[padIndex] = [slap => pad.config.A, start => pad.config.start];
    }

    function getAvailablePadIndex():Int {
        for (i in 0...PlayerManager.MAX_PLAYERS) {
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

        var ply = PlayerManager.getPlayer(padIndex);
        if (ply.active) {
            throw 'the player at index $padIndex is already active! this should never happen...';
        }
        ply.active = true;

        for (hook in playerConnectedHooks) {
            hook(ply);
        }
    }

    /**
     * Return whether a pad is connected or not.
     * @param padIndex The index of the pad to check.
     * @return Bool The pad's connection state.
     */
    public static function isPadConnected(padIndex:PadIndex):Bool {
        var connected = false;
        switch (padIndex) {
            case anyone:
                for (i in 0...PlayerManager.MAX_PLAYERS) {
                    if (instance.pads[i].connected) {
                        connected = true;
                        break;
                    }
                }
            case player(i):
                connected = instance.pads[i].connected;
        }
        return connected;
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
                for (i in 0...PlayerManager.MAX_PLAYERS) {
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

    /**
     * Register a hook to trigger when a player connects.
     * @param hook The hook to register.
     */
    public static function addPlayerConnectedHook(hook:PlayerConnectedHook) {
        trace("Triggering player connection hooks.");
        instance.playerConnectedHooks.push(hook);
    }

    /**
     * Register a hook to trigger when a player disconnects.
     * @param hook The hook to register.
     */
    public static function addPlayerDisconnectedHook(hook:PlayerConnectedHook) {
        trace("Triggering player disconnection hooks.");
        instance.playerDisconnectedHooks.push(hook);
    }

    /**
     * Updates the input manager, looking for disconnected pads.
     * @param dt Delta time.
     */
    public static function update(dt:Float) {
        for (i in 0...PlayerManager.MAX_PLAYERS) {
            var ply = PlayerManager.getPlayer(i);
            if (ply.active && !instance.pads[i].connected) {
                trace('Player ${ply.padIndex} disconnected!');
                ply.active = false;
                for (hook in instance.playerDisconnectedHooks) {
                    hook(ply);
                }
            }
        }
    }
}
