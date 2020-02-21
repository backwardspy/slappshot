/**
 * Function call after changing State.
 */
typedef StateChangeHook = (state:State) -> Void;

/**
 * Represents a transition from one State to another.
 */
enum Transition {
    push(state:State);
    pop;
    replace(state:State);
}

/**
 * Manages a set of States, and provides methods for transitioning between them.
 */
class StateManager {
    var states:Array<State>;
    var hooks:Array<StateChangeHook>;

    var queuedTransitions:List<Transition>;

    public function new() {
        trace("initialising state manager");
        queuedTransitions = new List<Transition>();
        states = [];
        hooks = [];
    }

    /**
     * Register a new StateChangeHook.
     * @param hook The hook to call upon state change.
     */
    public function addHook(hook:StateChangeHook) {
        trace('adding state change hook: $hook');
        hooks.push(hook);
    }

    /**
     * Update the StateManager. This applies any pending transitions and then updates the top state.
     * @param dt Delta time.
     */
    public function update(dt:Float) {
        processQueuedTransitions();
        top().update(dt);
    }

    function processQueuedTransitions() {
        if (!queuedTransitions.isEmpty()) {
            for (transition in queuedTransitions) {
                doTransition(transition);
            }

            queuedTransitions.clear();
        }
    }

    function doTransition(transition:Transition) {
        switch (transition) {
            case Transition.push(state):
                doPush(state);
            case Transition.pop:
                doPop();
            case Transition.replace(state):
                doReplace(state);
        }
    }

    /**
     * Push a new State onto the stack.
     * @param state The state to push.
     */
    public function push(state:State) {
        trace('queuing push of $state');
        queuedTransitions.add(Transition.push(state));
    }

    function doPush(state:State) {
        trace('pushing $state');
        suspendTop();
        state.bind(this);
        states.push(state);
        triggerHooks(state);
    }

    /**
     * Pop the top state from the stack.
     */
    public function pop() {
        trace("queueing pop");
        queuedTransitions.add(Transition.pop);
    }

    function doPop() {
        trace('popping ${top()}');
        var state = states.pop();
        state.shutdown();
        state.dispose();
        resumeTop();
        triggerHooks(top());
    }

    /**
     * Replace the top State with another.
     * @param state The State to replace the top State with.
     */
    public function replace(state:State) {
        trace('queueing replace of ${top()} with $state');
        queuedTransitions.add(Transition.replace(state));
    }

    function doReplace(state:State) {
        trace('replacing ${top()} with $state');
        var prev = top();

        if (prev != null) {
            prev.shutdown();
            prev.dispose();
        }

        state.bind(this);
        states[states.length - 1] = state;
        triggerHooks(state);
    }

    /**
     * Get the State at the top of the stack.
     * @return State The top State.
     */
    public function top():State {
        if (states.length > 0) {
            return states[states.length - 1];
        }
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
        for (hook in hooks) {
            hook(state);
        }
    }
}
