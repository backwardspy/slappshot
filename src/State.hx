/**
 * Custom scene type representing one state (roughly, a screen) of the game.
 */
class State extends h2d.Scene {
    var states:StateManager;

    /**
     * Bind this state to the given StateManager.
     * @param manager The StateManager to bind to.
     */
    public function bind(manager:StateManager) {
        states = manager;
    }

    /**
     * Perform operations prior to disposing of a State.
     */
    public function shutdown() {}

    /**
     * Perform operations prior to temporary suspension of a State.
     */
    public function suspend() {}

    /**
     * Perform operations prior to resumption of a suspended State.
     */
    public function resume() {}

    /**
     * Update a State.
     * @param dt Delta time.
     */
    public function update(dt:Float) {}
}
