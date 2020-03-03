package states;

/**
 * The pre-game screen state.
 */
class PreGame extends State {
    var logWindow:GameLogWindow;

    var gizmos:haxe.ds.Vector<GamepadGizmo>;

    public function new() {
        trace("initialising pregame state...");
        super();
        var text = new h2d.Text(hxd.res.DefaultFont.get(), this);
        text.text = "push START to begin";
        text.textAlign = Center;
        text.setPosition(width / 2, height / 2);

        // gizmo = new GamepadGizmo(width / 5, height / 3, this);
        gizmos = new haxe.ds.Vector<GamepadGizmo>(Input.MAX_PADS);
        for (i in 0...gizmos.length) {
            gizmos[i] = new GamepadGizmo(width / 5 + (i % 2) * 3 * width / 5, (Std.int(i / 2) + 1) * height / 3, this);
        }

        logWindow = new GameLogWindow(this);

        trace("pregame state initialised");
    }

    override function update(dt:Float) {
        logWindow.update(dt);

        for (i in 0...gizmos.length) {
            gizmos[i].setOffset(Input.getAxis(moveX, player(i)) * 100, Input.getAxis(moveY, player(i)) * 100);

            var rotX = Input.getAxis(rotX, player(i));
            var rotY = Input.getAxis(rotY, player(i));

            if (Math.abs(rotX) + Math.abs(rotY) > 0.2) {
                gizmos[i].setAngle(Math.atan2(rotX, rotY));
            } else {
                gizmos[i].setAngle(0);
            }

            gizmos[i].update(dt);

            gizmos[i].alpha = if (Input.isPadConnected(player(i))) 1.0 else 0.2;
        }

        if (Input.getButtonPressed(start)) {
            states.push(new Game());
        }
    }
}
