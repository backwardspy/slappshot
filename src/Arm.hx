/**
 * A player's arm. Used to slap the ball.
 */
class Arm extends h2d.Object {
    static inline final MAX_LIVES:Int = 3;

    static inline final HITZONE_ACTIVE_TIME:Float = 0.15;
    static inline final SLAP_COOLDOWN:Float = 0.3;

    static inline final SLAP_RADIUS:Float = 350.0;

    static inline final GFX_SCALE:Int = 2;

    /**
     * The number of lives left on this arm. Depleted by one on each missed ball.
     */
    public var lives(default, null):Int;

    var flipped:Bool;

    var shoulder:h2d.Bitmap;
    var elbow:h2d.Bitmap;
    var wrist:h2d.Bitmap;

    var baseX:Float;
    var baseY:Float;

    var slapDirection:SlapDirection;

    var slapTween:Tween;

    var canHit:Bool; // set true when a slap is started, set false again when contacting the ball
    var hitZoneTimer:Float;

    public function new(x:Float, y:Float, shoulder:h2d.Tile, elbow:h2d.Tile, wrist:h2d.Tile, scene:h2d.Scene, ?flipped:Bool = false) {
        super(scene);

        shoulder.dx = -33;
        shoulder.dy = -32;

        elbow.dx = -27;
        elbow.dy = -15;

        wrist.dx = -36;
        wrist.dy = -16;

        this.shoulder = new h2d.Bitmap(shoulder, this);
        this.elbow = new h2d.Bitmap(elbow, this.shoulder);
        this.wrist = new h2d.Bitmap(wrist, this.elbow);

        this.shoulder.setPosition(0, 0);
        this.elbow.setPosition(99 + shoulder.dx, 31 + shoulder.dy);
        this.wrist.setPosition(105 + elbow.dx, 14 + elbow.dy);

        this.flipped = flipped;

        baseX = x;
        baseY = y;
        setPosition(x, y);
        scaleX = GFX_SCALE;
        scaleY = switch (flipped) {
            case true: -GFX_SCALE;
            case false: GFX_SCALE;
        }

        slapTween = new Tween();
        slapDirection = up;
        setBend(1);

        lives = MAX_LIVES;
    }

    /**
     * Update the slap animation of the arm. This is not affected by hitstops.
     * @param dt Delta time.
     */
    public function updateVisuals(dt:Float) {
        slapTween.update(dt);
        setBend(slapTween.value * 0.8);
    }

    /**
     * Updates the arm.
     * @param dt Delta time.
     */
    public function update(dt:Float) {
        if (hitZoneTimer > 0.0) {
            hitZoneTimer -= dt;

            if (canHit && hitZoneTimer <= HITZONE_ACTIVE_TIME) {
                canHit = false;
            }

            if (hitZoneTimer < 0.0) {
                hitZoneTimer = 0.0;
            }
        }
    }

    /**
     * Sets the base rotation of the arm (at the shoulder.)
     * @param radians The angle to use.
     */
    public function setRotation(radians:Float) {
        rotation = radians;
    }

    /**
     * Sets the joint rotation of the arm (at all joints.)
     * @param radians The angle to use.
     */
    public function setBend(radians:Float) {
        shoulder.rotation = radians;
        elbow.rotation = radians;
        wrist.rotation = radians;
    }

    /**
     * Sets the offset of the arm from its root position.
     * @param x The amount to offset the X coordinate by.
     * @param y The amount to offset the Y coordinate by.
     */
    public function setOffset(x:Float, y:Float) {
        setPosition(baseX + x, baseY + y);
    }

    /**
     * Swing the arm.
     */
    public function slap() {
        if (hitZoneTimer > 0) {
            return;
        }

        canHit = true;
        hitZoneTimer = SLAP_COOLDOWN;

        switch (this.slapDirection) {
            case up:
                this.slapDirection = down;
                slapTween.init(1, -1, SLAP_COOLDOWN);
            case down:
                this.slapDirection = up;
                slapTween.init(-1, 1, SLAP_COOLDOWN);
        }
    }

    /**
     * Reduce the arm's lives by one.
     * @return Bool Whether the arm died or not.
     */
    public function hurt():Bool {
        return --lives <= 0;
    }

    /**
     * Check for a collision between the arm's hitzone and the ball.
     * @param ball The ball to check against.
     * @return SlapResult A SlapResult containing the collision information.
     */
    public function collide(ball:Ball):SlapResult {
        var result:SlapResult = {
            collided: false,
            power: 0,
            normalX: 0,
            normalY: 0,
        };

        if (canHit && hitZoneTimer > 0) {
            var distSq = getSquareDistance(ball.x, ball.y, x, y);

            if (distSq <= SLAP_RADIUS * SLAP_RADIUS) {
                var dist = Math.sqrt(distSq);

                result.collided = true;
                result.power = 1;
                result.normalX = ball.x - x;
                result.normalY = ball.y - y;

                result.normalX /= dist;
                result.normalY /= dist;

                canHit = false; // can't hit again until the next slap
            }
        }

        return result;
    }

    function getSquareDistance(x0:Float, y0:Float, x1:Float, y1:Float):Float {
        var dx = x1 - x0;
        var dy = y1 - y0;
        return dx * dx + dy * dy;
    }
}
