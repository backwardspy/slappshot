/**
 * Controls stopping the ball and one player's movement for a duration.
 */
class Hitstop {
    /**
     * Which side is stopped.
     */
    public var side(default, null):Side;

    /**
     * The Arm.SlapResult that caused this hitstop.
     */
    public var hit(default, null):SlapResult;

    /**
     * Whether the hitstop is currently active or not.
     */
    public var active(default, null):Bool;

    var time:Float;

    public function new() {
        active = false;
    }

    /**
     * Initialise the hitstop and set it active.
     * @param duration How long the hitstop should last for.
     * @param stoppedSide Which side should be stopped.
     * @param slapResult The Arm.SlapResult that caused the hitstop.
     */
    public function init(duration:Float, stoppedSide:Side, slapResult:SlapResult) {
        if (this.active) {
            trace("warning: attempt to init active hitstop!");
            return;
        }
        this.time = duration;
        this.side = stoppedSide;
        this.hit = slapResult;
        this.active = true;
    }

    /**
     * Updates the hitstop, setting it inactive if the duration has passed.
     * @param dt Delta time.
     */
    public function update(dt:Float) {
        if (!this.active) {
            return;
        }

        this.time -= dt;
        if (this.time <= 0) {
            this.time = 0;
            this.active = false;
        }
    }
}
