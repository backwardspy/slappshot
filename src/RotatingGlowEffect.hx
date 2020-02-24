/**
 * Renders a rotating shrinking glow around a point.
 */
class RotatingGlowEffect extends h2d.Bitmap {
    var duration:Float;
    var elapsed:Float;

    public function new(?parent:h2d.Object) {
        var tile = hxd.Res.graphics.glow.toTile();
        tile.dx = -tile.width / 2;
        tile.dy = -tile.height / 2;

        super(tile, parent);

        blendMode = h2d.BlendMode.Add;

        setScale(0);
    }

    /**
     * Start a collapse effect on the glow.
     * @param x Collapse center X coordinate.
     * @param y Collapse center Y coordinate.
     * @param effectDuration Length of the collapse, in seconds.
     */
    public function collapse(x:Float, y:Float, effectDuration:Float) {
        setPosition(x, y);
        duration = effectDuration;
        elapsed = 0;
    }

    /**
     * Updates the effect.
     * @param dt Delta time.
     */
    public function update(dt:Float) {
        rotate(dt * 3);
        if (elapsed < duration) {
            elapsed += dt;
            if (elapsed > duration) {
                elapsed = duration;
            }
            setScale(elapsed * 5);
            alpha = 1 - Math.pow(elapsed / duration, 3);
        }
    }
}
