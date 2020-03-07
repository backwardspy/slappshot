/**
 * Displays a gamepad graphic on screen to aid players in identifying which side they're on.
 */
class GamepadGizmo extends h2d.Object {
    var sprite:h2d.Bitmap;
    var text:h2d.Text;

    var offsetX:Float;
    var offsetY:Float;
    var vx:Float;
    var vy:Float;
    var ax:Float;
    var ay:Float;

    var angle:Float;
    var vr:Float;
    var ar:Float;

    public function new(x:Float, y:Float, ?parent:h2d.Object) {
        super(parent);

        var tile = hxd.Res.graphics.gamepad.toTile();
        tile.dx = -tile.width / 2;
        tile.dy = -tile.height / 2;

        sprite = new h2d.Bitmap(tile, this);

        text = new h2d.Text(hxd.res.DefaultFont.get(), sprite);
        text.textAlign = Center;
        text.setPosition(0, -100);

        setPosition(x, y);
    }

    /**
     * Set the offset of this gizmo from its base position.
     * @param x Offset X coordinate.
     * @param y Offset Y coordinate.
     */
    public function setOffset(x:Float, y:Float) {
        offsetX = x;
        offsetY = y;
    }

    /**
     * Set the angle of this gizmo.
     * @param a The angle in radians.
     */
    public function setAngle(a:Float) {
        angle = a;
    }

    /**
     * Set the colour tint of this gizmo.
     * @param colour The colour to tint this gizmo.
     */
    public function setTint(colour:Int) {
        colour |= 0xFF000000; // force full alpha
        sprite.color.setColor(colour);
    }

    /**
     * Set the string displayed above the gizmo.
     * @param textString The text string to display.
     */
    public function setText(textString:String) {
        text.text = textString;
    }

    /**
     * Updates the GamepadGizmo.
     * @param dt Delta time.
     */
    public function update(dt:Float) {
        ax = (offsetX - sprite.x) * 150;
        ay = (offsetY - sprite.y) * 150;
        vx += ax * dt - vx * .1;
        vy += ay * dt - vy * .1;
        sprite.setPosition(sprite.x + vx * dt, sprite.y + vy * dt);

        var angDiff = hxd.Math.angle(angle - sprite.rotation);
        ar = angDiff * 500;
        vr += ar * dt - vr * .2;
        sprite.rotation += vr * dt;
    }
}
