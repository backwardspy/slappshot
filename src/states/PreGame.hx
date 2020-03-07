package states;

/**
 * The pre-game screen state.
 */
class PreGame extends State {
    static inline final HIDDEN_Y:Float = -10000;

    static inline final READY_GIZMO_TINT:Int = 0x77FF77;
    static inline final UNREADY_GIZMO_TINT:Int = 0xFFFFFF;

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
            text.x = getPlayerX(i);
            waitingTexts.push(text);
            showWaitingText(i);
        }

        for (i in 0...PlayerManager.MAX_PLAYERS) {
            var ply = PlayerManager.getPlayer(i);
            if (ply.active) {
                onPlayerConnected(ply);
            }
        }

        Input.addPlayerConnectedHook(onPlayerConnected);
        Input.addPlayerDisconnectedHook(onPlayerDisconnected);

        logWindow = new GameLogWindow(this);

        trace("pregame state initialised");
    }

    function getPlayerX(index:Int):Float {
        return width / 5 + (index % 2) * 3 * width / 5;
    }

    function getPlayerY(index:Int):Float {
        return (Std.int(index / 2) + 1) * height / 3;
    }

    function isDaiRequired():Bool {
        var required = PlayerManager.getPlayer(0).active;
        if (!required) {
            return required;
        }
        for (i in 1...PlayerManager.MAX_PLAYERS) {
            var ply = PlayerManager.getPlayer(i);
            if (ply != PlayerManager.dai && ply.active) {
                required = false;
                break;
            }
        }
        return required;
    }

    function updateDai() {
        if (isDaiRequired()) {
            PlayerManager.addDai();
            onPlayerConnected(PlayerManager.dai);
        } else {
            PlayerManager.removeDai();
            onPlayerDisconnected(PlayerManager.dai);
        }
    }

    function showWaitingText(index:Int) {
        waitingTexts[index].y = (Std.int(index / 2) + 1) * height / 3;
    }

    function hideWaitingText(index:Int) {
        waitingTexts[index].y = HIDDEN_Y;
    }

    function onPlayerConnected(ply:Player) {
        if (ply.gizmo == null) {
            var x = getPlayerX(ply.padIndex);
            var y = getPlayerY(ply.padIndex);
            var gizmo = if (ply == PlayerManager.dai) {
                new DaiGamepadGizmo(x, y, this);
            } else {
                new GamepadGizmo(x, y, this);
            }
            ply.gizmo = gizmo;
        }

        hideWaitingText(ply.padIndex);

        if (ply == PlayerManager.dai) {
            readyPlayer(ply); // dai is always ready
        } else {
            unreadyPlayer(ply);
            updateDai();
        }
    }

    function onPlayerDisconnected(ply:Player) {
        ply.gizmo.remove();
        ply.gizmo = null;
        showWaitingText(ply.padIndex);

        if (ply != PlayerManager.dai) {
            updateDai();
        }
    }

    function readyPlayer(ply:Player) {
        ply.ready = true;
        ply.gizmo.setTint(READY_GIZMO_TINT);
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
        ply.gizmo.setTint(UNREADY_GIZMO_TINT);
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
