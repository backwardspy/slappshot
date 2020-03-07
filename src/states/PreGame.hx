package states;

/**
 * The pre-game screen state.
 */
class PreGame extends State {
    var logWindow:GameLogWindow;

    var waitingTexts:Array<h2d.Text>;

    var gameCanStart:Bool;

    public function new() {
        trace("initialising pregame state...");
        super();

        gameCanStart = false;

        waitingTexts = [];
        for (i in 0...PlayerManager.MAX_PLAYERS) {
            var text = new h2d.Text(hxd.res.DefaultFont.get(), this);
            text.textAlign = Center;
            text.text = "waiting for a player to join...";
            text.x = width / 5 + (i % 2) * 3 * width / 5;
            waitingTexts.push(text);
            showWaitingText(i);
        }

        Input.addPlayerConnectedHook(onPlayerConnected);
        Input.addPlayerDisconnectedHook(onPlayerDisconnected);

        for (i in 0...PlayerManager.MAX_PLAYERS) {
            var ply = PlayerManager.getPlayer(i);
            if (ply.active) {
                onPlayerConnected(ply);
            }
        }

        logWindow = new GameLogWindow(this);

        trace("pregame state initialised");
    }

    function hideWaitingText(index:Int) {
        waitingTexts[index].y = -1000;
    }

    function showWaitingText(index:Int) {
        waitingTexts[index].y = (Std.int(index / 2) + 1) * height / 3;
    }

    function onPlayerConnected(ply:Player) {
        if (ply.gizmo == null) {
            var gizmo = new GamepadGizmo(width / 5 + (ply.padIndex % 2) * 3 * width / 5, (Std.int(ply.padIndex / 2) + 1) * height / 3, this);
            ply.gizmo = gizmo;
        }
        unreadyPlayer(ply);
        hideWaitingText(ply.padIndex);
    }

    function onPlayerDisconnected(ply:Player) {
        ply.gizmo.remove();
        ply.gizmo = null;
        showWaitingText(ply.padIndex);
    }

    function readyPlayer(ply:Player) {
        ply.ready = true;
        ply.gizmo.setTint(0x77FF77);
        if (ply.padIndex == 0) {
            ply.gizmo.setText("waiting for all players to ready up...");
        } else {
            ply.gizmo.setText("");
        }

        gameCanStart = true;
        for (i in 0...PlayerManager.MAX_PLAYERS) {
            var ply = PlayerManager.getPlayer(i);
            if (ply.active && !ply.ready) {
                gameCanStart = false;
                break;
            }
        }

        if (gameCanStart) {
            PlayerManager.getPlayer(0).gizmo.setText("all players are ready! push START to begin.");
        }
    }

    function unreadyPlayer(ply:Player) {
        ply.ready = false;
        ply.gizmo.setTint(0xFFFFFF);
        PlayerManager.getPlayer(0).gizmo.setText("waiting for all players to ready up...");
        ply.gizmo.setText("push A to ready up!");
    }

    override function update(dt:Float) {
        logWindow.update(dt);

        for (i in 0...PlayerManager.MAX_PLAYERS) {
            var ply = PlayerManager.getPlayer(i);
            if (!ply.active) {
                continue;
            }

            var gizmo = ply.gizmo;

            if (Input.getButtonPressed(slap, player(i))) {
                if (!ply.ready) {
                    readyPlayer(ply);
                } else {
                    unreadyPlayer(ply);
                }
            }

            gizmo.setOffset(Input.getAxis(moveX, player(i)) * 100, Input.getAxis(moveY, player(i)) * 100);

            var rotX = Input.getAxis(rotX, player(i));
            var rotY = Input.getAxis(rotY, player(i));

            if (Math.abs(rotX) + Math.abs(rotY) > 0.2) {
                gizmo.setAngle(Math.atan2(rotX, rotY));
            } else {
                gizmo.setAngle(0);
            }

            gizmo.update(dt);
        }

        if (gameCanStart && Input.getButtonPressed(start)) {
            states.push(new Game());
        }
    }
}
