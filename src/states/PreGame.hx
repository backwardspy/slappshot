package states;

/**
 * The pre-game screen state.
 */
class PreGame extends State {
    var logWindow:GameLogWindow;

    public function new() {
        trace("initialising pregame state...");
        super();
        var text = new h2d.Text(hxd.res.DefaultFont.get(), this);
        text.text = "push START to begin";
        text.textAlign = Center;
        text.setPosition(width / 2, height / 2);

        logWindow = new GameLogWindow(this);

        trace("pregame state initialised");
    }

    override function update(dt:Float) {
        logWindow.update(dt);

        if (Input.getButtonPressed(start)) {
            states.push(new Game());
        }
    }
}
