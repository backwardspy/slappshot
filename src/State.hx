class State extends h2d.Scene {
	var states:StateManager;

	public function setStateManager(manager:StateManager) {
		states = manager;
	}

	public function shutdown() {}

	public function suspend() {}

	public function resume() {}

	public function update(dt:Float) {}
}
