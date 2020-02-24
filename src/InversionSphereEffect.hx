/**
 * Contains & controls an InversionSphereShader.
 */
class InversionSphereEffect {
    static inline final RADIUS_MUL:Float = 1;

    /**
     * The InversionSphereShader controlled by this effect.
     */
    public var shader(default, null):shaders.InversionSphereShader;

    var elapsed:Float;
    var duration:Float;

    public function new(aspect:Float) {
        shader = new shaders.InversionSphereShader();
        shader.aspect = aspect;
    }

    /**
     * Start a collapse effect on the inversion shader.
     * @param pointX Collapse center X coordinate.
     * @param pointY Collapse center Y coordinate.
     * @param collapseDuration Length of the collapse, in seconds.
     */
    public function collapse(pointX:Float, pointY:Float, collapseDuration:Float) {
        shader.point.x = pointX;
        shader.point.y = pointY;
        shader.radius = duration;
        duration = collapseDuration;
        elapsed = 0;
    }

    /**
     * Updates the effect.
     * @param dt Delta time.
     */
    public function update(dt:Float) {
        if (elapsed < duration) {
            elapsed += dt;
            if (elapsed > duration) {
                elapsed = duration;
            }
            shader.radius = (duration - elapsed) * RADIUS_MUL;
        }
    }
}
