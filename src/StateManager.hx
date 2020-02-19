typedef StateChangeHook = (state:State) -> Void;

class StateManager {
	var states:Array<State>;
	var hooks:Array<StateChangeHook>;

	public function new() {
		states = new Array<State>();
		hooks = new Array<StateChangeHook>();
	}

	public function addHook(hook:StateChangeHook) {
		hooks.push(hook);
	}

	public function push(state:State) {
		suspendTop();
		state.setStateManager(this);
		states.push(state);
		triggerHooks(state);
	}

	public function pop():State {
		var state = states.pop();
		state.shutdown();
		state.dispose(); // TODO: is this okay?
		resumeTop();
		triggerHooks(top());
		return state;
	}

	public function replace(state:State) {
		pop();
		push(state);
	}

	public function top():State {
		if (states.length > 0)
			return states[states.length - 1];
		return null;
	}

	function suspendTop() {
		var state = top();
		if (state != null)
			state.suspend();
	}

	function resumeTop() {
		var state = top();
		if (state != null)
			state.resume();
	}

	function triggerHooks(state:State) {
		for (hook in hooks)
			hook(state);
	}
}
