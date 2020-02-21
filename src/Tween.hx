/**
 * Smoothly interpolates between two values over a given duration.
 */
class Tween {
    static inline final EASE_POWER:Int = 5;

    /**
     * Whether the tween is currently active or not.
     */
    public var active(default, null):Bool;

    /**
     * The value to tween from.
     */
    public var from(default, null):Float;

    /**
     * The value to tween to.
     */
    public var to(default, null):Float;

    /**
     * The current interpolated value.
     */
    public var value(get, null):Float;

    /**
     * The linear progress through the tween's duration.
     */
    public var progress(default, null):Float;

    /**
     * How long the tween should take, in seconds.
     */
    public var length(default, null):Float;

    public function new() {
        from = 0;
        to = 1;
        length = 1;
        progress = 1;
        active = false;
    }

    /**
     * Initialise the tween, setting it active.
     * @param tweenFrom The value to start from.
     * @param tweenTo The value to stop on.
     * @param tweenLength How long the tween should last, in seconds.
     */
    public function init(tweenFrom:Float, tweenTo:Float, tweenLength:Float) {
        this.from = tweenFrom;
        this.to = tweenTo;
        this.length = tweenLength;
        progress = 0;
        active = true;
    }

    /**
     * Updates the tween, setting it inactive if the duration has passed.
     * @param dt Delta time.
     */
    public function update(dt:Float) {
        if (!active) {
            return;
        }

        if (progress < length) {
            progress = Math.min(progress + dt, length);
        } else {
            progress = length;
            active = false;
        }
    }

    /**
     * Ease the given parameter using a power function.
     * @param k The value to ease.
     * @return The eased value.
     */
    public function ease(k:Float):Float {
        return 1 - Math.pow(1 - k, EASE_POWER);
    }

    function get_value():Float {
        if (!active) {
            return to;
        }

        var k = progress / length;
        return hxd.Math.lerp(from, to, ease(k));
    }
}
