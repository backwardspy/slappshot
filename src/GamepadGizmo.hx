/**
 * Displays a gamepad graphic on screen to aid players in identifying which side they're on.
 */
class GamepadGizmo extends h2d.Object {
    var sprite:h2d.Bitmap;

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

    public function setAngle(a:Float) {
        angle = a;
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
