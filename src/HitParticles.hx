/**
 * Particles to emit when hitting something.
 */
class HitParticles extends h2d.Object {
    static inline final MAX_PARTICLES:Int = 50;
    static inline final EMIT_SYNC:Float = 0.9;
    static inline final EMIT_ANGLE:Float = 0.1;
    static inline final EMIT_DISTANCE:Int = 50;
    static inline final LIFE:Float = 0.5;
    static inline final SIZE:Float = 1.5;

    var particlesPool:Pool<h2d.Particles>;

    public function new(?parent:h2d.Object) {
        super(parent);

        particlesPool = new Pool<h2d.Particles>();
    }

    /**
     * Create a burst of particles from the given position in a given angle.
     * @param x The X coordinate to emit from.
     * @param y The Y coordinate to emit from.
     * @param speed The speed to emit with.
     * @param angle The angle to emit in.
     */
    public function emit(x:Float, y:Float, speed:Float, angle:Float) {
        var p = particlesPool.get(() -> new h2d.Particles(this));
        p.setPosition(x, y);
        p.rotation = angle - Math.PI / 2;
        var pg = new h2d.Particles.ParticleGroup(p);
        pg.texture = hxd.Res.graphics.diamond_particle.toTexture();
        pg.emitLoop = false;
        pg.nparts = MAX_PARTICLES;
        pg.speed = speed;
        pg.speedRand = 1;
        pg.emitSync = EMIT_SYNC;
        pg.emitMode = h2d.Particles.PartEmitMode.Cone;
        pg.emitAngle = EMIT_ANGLE;
        pg.emitDist = EMIT_DISTANCE;
        pg.life = LIFE;
        pg.size = SIZE;
        pg.sizeRand = 1;
        p.addGroup(pg);

        p.onEnd = function() {
            particlesPool.release(p);
        }
    }
}
