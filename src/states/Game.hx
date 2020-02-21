package states;

/**
 * The main in-game state.
 */
class Game extends State {
    static inline final SLAP_SOUNDS_COUNT:Int = 16;

    static inline final INITIAL_HITSTOP_TIME:Float = 0.0;
    static inline final MAXIMUM_HITSTOP_TIME:Float = 0.05;
    static inline final HITSTOP_TIME_SPEEDMOD_DIV:Int = 10;

    static inline final GRID_POINT_STRENGTH_SPEEDMOD_MUL:Float = 0.3;
    static inline final GRID_WAVE_STRENGTH_SPEEDMOD_MUL:Float = 0.2;

    static inline final MAX_ARM_DEFLECTION_X:Int = 50;
    static inline final ARM_DEFLECTION_Y_MUL:Float = 0.4;
    static inline final ARM_ROTATION_MUL:Float = 0.3;

    static inline final AI_SLAP_X_THRESHOLD_MUL:Float = 0.8;

    static inline final HIT_MAX_PARTICLES:Int = 50;
    static inline final HIT_PARTICLE_SPEED_MUL:Float = 0.4;
    static inline final HIT_PARTICLE_EMIT_SYNC:Float = 0.9;
    static inline final HIT_PARTICLE_EMIT_ANGLE:Float = 0.1;
    static inline final HIT_PARTICLE_EMIT_DISTANCE:Int = 50;
    static inline final HIT_PARTICLE_LIFE:Float = 0.5;

    static inline final BALL_INITIAL_X_MUL:Float = 0.25;
    static inline final BALL_INITIAL_Y_MUL:Float = 0.5;

    var grid:WarpGrid;

    var leftArm:Arm;
    var rightArm:Arm;

    var slapSounds:Array<hxd.res.Sound>;

    var ball:Ball;

    var logWindow:GameLogWindow;

    var hitstop:Hitstop;
    var hitWasActive:Bool;

    var hitstopTime:Float;

    var grainShader:shaders.GrainShader;

    var rand:hxd.Rand;

    public function new() {
        trace("initialising game state...");
        super();

        slapSounds = [];
        for (i in 0...SLAP_SOUNDS_COUNT) {
            var path = 'audio/slap$i.ogg';
            slapSounds.push(hxd.Res.load(path).toSound());
        }

        grid = new WarpGrid(hxd.Res.graphics.backdrop_castle.toTile(), this);

        leftArm = new Arm(0, height / 2, hxd.Res.graphics.arm_male_shoulder.toTile(), hxd.Res.graphics.arm_male_elbow.toTile(),
            hxd.Res.graphics.arm_male_wrist.toTile(), this);
        rightArm = new Arm(width, height / 2, hxd.Res.graphics.arm_male_shoulder.toTile(), hxd.Res.graphics.arm_male_elbow.toTile(),
            hxd.Res.graphics.arm_male_wrist.toTile(), this, true);
        rightArm.setRotation(Math.PI);

        ball = new Ball(width * BALL_INITIAL_X_MUL, height * BALL_INITIAL_Y_MUL, hxd.Res.graphics.ball_eye.toTile(), this);

        logWindow = new GameLogWindow(this);

        hitstop = new Hitstop();
        hitWasActive = false;

        hitstopTime = INITIAL_HITSTOP_TIME;

        grainShader = new shaders.GrainShader();
        filter = new h2d.filter.Group([
            new h2d.filter.Shader(grainShader),
            new h2d.filter.Shader(new shaders.VignetteShader())
        ]);

        rand = new hxd.Rand(Std.int(Sys.time()));

        trace("game state initialised");
    }

    override public function update(dt:Float) {
        var lastHit:SlapResult = null;
        var lastHitSide:Side = null;

        var leftFrozen = hitstop.active && hitstop.side == left;
        var rightFrozen = hitstop.active && hitstop.side == right;

        if (!leftFrozen) {
            var hit = updateArm(leftArm, left, dt);
            if (hit.collided) {
                lastHit = hit;
                lastHitSide = left;
            }
        }

        if (!rightFrozen) {
            var hit = updateArm(rightArm, right, dt);
            if (hit.collided) {
                lastHit = hit;
                lastHitSide = right;
            }
        }

        // we check lasthit to skip updating on the frame we hit the ball
        if (!hitstop.active && lastHit == null) {
            var result = ball.bounce(0, 0, width, height);
            if (result.hitSide) {
                hurtArm(result.side);
            }
            ball.update(dt);
        }

        hitstopTime = Math.min(MAXIMUM_HITSTOP_TIME, Math.pow(ball.speedMod / HITSTOP_TIME_SPEEDMOD_DIV, 2));

        hitWasActive = hitstop.active;
        if (lastHit != null) {
            hitstop.init(hitstopTime, lastHitSide, lastHit);
        }
        hitstop.update(dt);

        // effects to run when a hitstop starts
        if (hitstop.active && !hitWasActive) {
            grid.startWave(ball.x / width, ball.y / height, ball.speedMod * GRID_WAVE_STRENGTH_SPEEDMOD_MUL);
        }

        // effects to run when a hitstop ends
        if (hitWasActive && !hitstop.active) {
            hitParticles(Math.atan2(hitstop.hit.normalY, hitstop.hit.normalX));
        }

        updateShaders(dt);

        logWindow.update(dt);
    }

    function updateShaders(dt:Float) {
        grid.setPoint(ball.x / width, ball.y / height, ball.speedMod * GRID_POINT_STRENGTH_SPEEDMOD_MUL);
        grid.update(dt);

        grainShader.time = Sys.time();
    }

    function updateArm(arm:Arm, side:Side, dt:Float):SlapResult {
        doMovement(side);
        arm.update(dt);
        var hit = arm.collide(ball);
        if (hit.collided) {
            ball.hit(hit.normalX, hit.normalY, hit.power);
            playSlapSound();
        }
        return hit;
    }

    function hurtArm(side:Side) {
        switch (side) {
            case left:
                var died = leftArm.hurt();
                trace('left arm reduced to ${leftArm.lives} lives');
                if (died) {
                    trace("left arm died!");
                    states.replace(new states.GameOver(right));
                }
            case right:
                var died = rightArm.hurt();
                trace('right arm reduced to ${rightArm.lives} lives');
                if (died) {
                    trace("right arm died!");
                    states.replace(new states.GameOver(left));
                }
        }
    }

    function playSlapSound() {
        slapSounds[rand.random(slapSounds.length)].play();
    }

    function doMovement(side:Side) {
        if (side == left) {
            var yAxis = Input.getAxis(moveY, 0);
            leftArm.setOffset(Input.getAxis(moveX, 0) * MAX_ARM_DEFLECTION_X, yAxis * height * ARM_DEFLECTION_Y_MUL);
            leftArm.rotation = yAxis * ARM_ROTATION_MUL;

            if (Input.getButtonPressed(slap, 0)) {
                leftArm.slap();
            }
        } else {
            rightArm.setOffset(0, Math.sin(Sys.time()) * height * ARM_DEFLECTION_Y_MUL);

            if (ball.x > width * AI_SLAP_X_THRESHOLD_MUL) {
                rightArm.slap();
            }
        }
    }

    function hitParticles(angle:Float) {
        var p = new h2d.Particles(this);
        p.setPosition(ball.x, ball.y);
        p.rotation = angle - Math.PI / 2;
        var pg = new h2d.Particles.ParticleGroup(p);
        pg.texture = hxd.Res.graphics.diamond_particle.toTexture();
        pg.emitLoop = false;
        pg.nparts = HIT_MAX_PARTICLES;
        pg.speed = ball.calculateSpeed() * HIT_PARTICLE_SPEED_MUL;
        pg.speedRand = 1;
        pg.emitSync = HIT_PARTICLE_EMIT_SYNC;
        pg.emitMode = h2d.Particles.PartEmitMode.Cone;
        pg.emitAngle = HIT_PARTICLE_EMIT_ANGLE;
        pg.emitDist = HIT_PARTICLE_EMIT_DISTANCE;
        pg.life = HIT_PARTICLE_LIFE;
        p.addGroup(pg);

        p.onEnd = function() {
            p.remove();
        }
    }
}
