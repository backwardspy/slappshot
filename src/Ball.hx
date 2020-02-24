/**
 * The result of a ball bouncing off of one side of the scene.
 */
typedef BounceResult = {hitSide:Bool, side:Side};

/**
 * A ball that can be slapped around.
 */
class Ball extends h2d.Object {
    static inline final BASE_SPEED:Int = 500;

    static inline final MAX_TRAIL_PARTICLES:Int = 100;
    static inline final TRAIL_PARTICLE_EMIT_DISTANCE:Int = 10;
    static inline final TRAIL_PARTICLE_LIFE:Float = 0.2;
    static inline final TRAIL_PARTICLE_LIFE_RAND:Float = 0.5;
    static inline final TRAIL_PARTICLE_SIZE:Float = 3;
    static inline final TRAIL_PARTICLE_SIZE_RAND:Float = 0.5;

    static inline final HIT_SPEEDMOD_POWER_MUL:Float = 0.15;

    var radius:Float;

    var vx:Float;
    var vy:Float;

    /**
     * The modifier applied to the ball's speed. Starts at 1 and rises with each hit.
     */
    public var speedMod(default, null):Float;

    public function new(x:Float, y:Float, tile:h2d.Tile, scene:h2d.Scene) {
        super(scene);

        tile.dx = -tile.width / 2;
        tile.dy = -tile.height / 2;

        radius = (tile.width + tile.height) / 2;

        vx = 0;
        vy = 0;

        speedMod = 1;

        var p = new h2d.Particles(this);
        var pg = new h2d.Particles.ParticleGroup(p);
        pg.nparts = MAX_TRAIL_PARTICLES;
        pg.isRelative = false;
        pg.speed = 1;
        pg.emitDist = TRAIL_PARTICLE_EMIT_DISTANCE;
        pg.texture = hxd.Res.graphics.star_particle.toTexture();
        pg.life = TRAIL_PARTICLE_LIFE;
        pg.lifeRand = TRAIL_PARTICLE_LIFE_RAND;
        pg.size = TRAIL_PARTICLE_SIZE;
        pg.sizeRand = TRAIL_PARTICLE_SIZE_RAND;
        pg.rotInit = 1;
        p.addGroup(pg);

        new h2d.Bitmap(tile, this);

        setPosition(x, y);
    }

    /**
     * Hit the ball in a direction with the given power.
     * @param nx The normal vector X direction.
     * @param ny The normal vector Y direction.
     * @param power The power to hit with along the given normal vector.
     */
    public function hit(nx:Float, ny:Float, power:Float) {
        vx = nx * BASE_SPEED * power * speedMod;
        vy = ny * BASE_SPEED * power * speedMod;
        speedMod += power * HIT_SPEEDMOD_POWER_MUL;
    }

    /**
     * Bounce the ball off the scene boundary.
     * @param x0 Left side coordinate.
     * @param y0 Top side corrdinate.
     * @param x1 Right side coordinate.
     * @param y1 Bottom side coordinate.
     * @return BounceResult Tells whether the ball bounced off the left or right side of the scene.
     */
    public function bounce(x0:Float, y0:Float, x1:Float, y1:Float):BounceResult {
        var result:BounceResult = {hitSide: false, side: null};
        if (x < x0) {
            x = x0;
            if (vx < 0) {
                result.hitSide = true;
                result.side = left;
                vx = -vx;
            }
        }
        if (x >= x1) {
            x = x1;
            if (vx > 0) {
                vx = -vx;
                result.hitSide = true;
                result.side = right;
            }
        }
        if (y < y0) {
            y = y0;
            if (vy < 0) {
                vy = -vy;
            }
        }
        if (y >= y1) {
            y = y1;
            if (vy > 0) {
                vy = -vy;
            }
        }

        return result;
    }

    /**
     * Calculate the current scalar speed of the ball.
     * @return The speed of the ball in units/sec
     */
    public function calculateSpeed():Float {
        return Math.sqrt(vx * vx + vy * vy);
    }

    /**
     * Updates the ball.
     * @param dt Delta time.
     */
    public function update(dt:Float) {
        x += vx * dt;
        y += vy * dt;

        scaleX = 1 + (speedMod - 1) / 20;
        rotation = Math.atan2(vy, vx);
    }
}
