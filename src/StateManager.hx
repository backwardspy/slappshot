typedef StateChangeHook = (state:State) -> Void;

class StateManager {
	var states:Array<State>;
	var hooks:Array<StateChangeHook>;

	public function new() {
		trace("initialising state manager");
		states = new Array<State>();
		hooks = new Array<StateChangeHook>();
	}

	public function addHook(hook:StateChangeHook) {
		trace('adding state change hook: $hook');
		hooks.push(hook);
	}

	public function push(state:State) {
		trace('pushing $state');
		suspendTop();
		state.setStateManager(this);
		states.push(state);
		triggerHooks(state);
	}

	public function pop():State {
		trace('popping ${top()}');
		var state = states.pop();
		state.shutdown();
		state.dispose(); // TODO: is this okay?
		resumeTop();
		triggerHooks(top());
		return state;
	}

	public function replace(state:State) {
		trace('replacing ${top()} with $state');
		var prev = top();

		if (prev != null) {
			prev.shutdown();
			prev.dispose(); // TODO: is this okay?
		}

		state.setStateManager(this);
		states[states.length - 1] = state;
		triggerHooks(state);
	}

	public function top():State {
		if (states.length > 0)
			return states[states.length - 1];
		return null;
	}

	function suspendTop() {
		var state = top();
		if (state != null) {
			trace('suspending $state');
			state.suspend();
		}
	}

	function resumeTop() {
		var state = top();
		if (state != null) {
			trace('resuming $state');
			state.resume();
		}
	}

	function triggerHooks(state:State) {
		trace('triggering hooks for state change: $state');
		for (hook in hooks)
			hook(state);
	}
}
