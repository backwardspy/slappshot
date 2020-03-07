package states;

/**
 * The main in-game state.
 */
class Game extends State {
    static inline final SLAP_SOUNDS_COUNT:Int = 16;

    static inline final INITIAL_HITSTOP_TIME:Float = 0;
    static inline final MAXIMUM_HITSTOP_TIME:Float = 0.5;
    static inline final HITSTOP_TIME_SPEEDMOD_DIV:Int = 10;

    static inline final GRID_POINT_STRENGTH_SPEEDMOD_MUL:Float = 0.5;
    static inline final GRID_WAVE_STRENGTH_SPEEDMOD_MUL:Float = 0.5;

    static inline final MAX_ARM_DEFLECTION_X:Int = 50;
    static inline final ARM_DEFLECTION_Y_MUL:Float = 0.4;
    static inline final ARM_ROTATION_MUL:Float = 0.3;

    static inline final AI_SLAP_X_THRESHOLD_MUL:Float = 0.8;

    static inline final HIT_PARTICLE_SPEED_MUL:Float = 0.4;

    static inline final BALL_INITIAL_X_MUL:Float = 0.25;
    static inline final BALL_INITIAL_Y_MUL:Float = 0.5;

    static inline final SHAKE_MAGNITUDE:Float = 30;
    static inline final HURT_SHAKE:Float = 0.5;
    static inline final HIT_SHAKE_SPEEDMOD_MUL:Float = 0.05;

    var grid:WarpGrid;

    var slapSounds:Array<hxd.res.Sound>;

    var ball:Ball;

    var logWindow:GameLogWindow;

    var hitstop:Hitstop;
    var hitWasActive:Bool;

    var hitstopTime:Float;

    var grainShader:shaders.GrainShader;
    var inversionSphereEffect:InversionSphereEffect;
    var rotatingGlowEffect:RotatingGlowEffect;

    var hitParticles:HitParticles;

    var rand:hxd.Rand;

    var shake:Float;

    public function new() {
        trace("initialising game state...");
        super();

        slapSounds = [];
        for (i in 0...SLAP_SOUNDS_COUNT) {
            var path = 'audio/slap$i.ogg';
            slapSounds.push(hxd.Res.load(path).toSound());
        }

        grid = new WarpGrid(hxd.Res.graphics.backdrop_castle.toTile(), this);

        for (i in 0...PlayerManager.MAX_PLAYERS) {
            var ply = PlayerManager.getPlayer(i);
            if (!ply.active) {
                continue;
            }

            var arm = new Arm((i % 2) * width, height / 2, hxd.Res.graphics.arm_male_shoulder.toTile(), hxd.Res.graphics.arm_male_elbow.toTile(),
                hxd.Res.graphics.arm_male_wrist.toTile(), this, ply.side == right);
            ply.arm = arm;
        }

        rotatingGlowEffect = new RotatingGlowEffect(this);

        hitParticles = new HitParticles(this);

        ball = new Ball(width * BALL_INITIAL_X_MUL, height * BALL_INITIAL_Y_MUL, hxd.Res.graphics.ball_eye.toTile(), this);

        logWindow = new GameLogWindow(this);

        hitstop = new Hitstop();
        hitWasActive = false;

        hitstopTime = INITIAL_HITSTOP_TIME;

        grainShader = new shaders.GrainShader();
        inversionSphereEffect = new InversionSphereEffect(width / height);

        filter = new h2d.filter.Group([
            new h2d.filter.Shader(grainShader),
            new h2d.filter.Shader(new shaders.VignetteShader()),
            new h2d.filter.Shader(inversionSphereEffect.shader),
        ]);

        rand = new hxd.Rand(Std.int(Sys.time()));

        shake = 0;

        trace("game state initialised");
    }

    override public function update(dt:Float) {
        var lastHit:SlapResult = null;
        var lastHitSide:Side = null;

        for (i in 0...PlayerManager.MAX_PLAYERS) {
            var ply = PlayerManager.getPlayer(i);
            if (!ply.active) {
                continue;
            }

            ply.arm.updateVisuals(dt);

            if (hitstop.active && hitstop.side == ply.side) {
                continue;
            }

            var hit = updatePlayer(ply, dt);
            if (hit.collided) {
                lastHit = hit;
                lastHitSide = ply.side;
            }
        }

        // we check lasthit to skip updating on the frame we hit the ball
        if (!hitstop.active && lastHit == null) {
            var result = ball.bounce(0, 0, width, height);

            if (result.hitSide) {
                shake = HURT_SHAKE;
                hurtSide(result.side);
            }
            ball.update(dt);
        }
        hitstopTime = Math.min(MAXIMUM_HITSTOP_TIME, INITIAL_HITSTOP_TIME + Math.pow(ball.speedMod / HITSTOP_TIME_SPEEDMOD_DIV, 2));
        hitWasActive = hitstop.active;
        hitstop.update(dt);
        if (lastHit != null) {
            hitstop.init(hitstopTime, lastHitSide, lastHit);
            // effects to run when a hitstop starts
            var effX = ball.x / width;
            var effY = ball.y / height;
            grid.startWave(effX, effY, ball.speedMod * GRID_WAVE_STRENGTH_SPEEDMOD_MUL);
            inversionSphereEffect.collapse(effX, effY, hitstopTime);
            rotatingGlowEffect.collapse(ball.x, ball.y, hitstopTime);
            hitParticles.emit(ball.x, ball.y, ball.calculateSpeed() * HIT_PARTICLE_SPEED_MUL, Math.atan2(hitstop.hit.normalY, hitstop.hit.normalX));
        }
        updateEffects(dt);
        updateShake(dt);
        logWindow.update(dt);
    }

    function updateShake(dt:Float) {
        var amount = shake * SHAKE_MAGNITUDE;
        setPosition(-amount + 2 * amount * rand.rand(), -amount + 2 * amount * rand.rand());

        if (shake > 0) {
            shake -= dt;
            if (shake < 0) {
                shake = 0;
            }
        }
    }

    function updateEffects(dt:Float) {
        grid.setPoint(ball.x / width, ball.y / height, ball.speedMod * GRID_POINT_STRENGTH_SPEEDMOD_MUL);
        grainShader.time = Sys.time();

        grid.update(dt);
        inversionSphereEffect.update(dt);
        rotatingGlowEffect.update(dt);
    }

    function updatePlayer(ply:Player, dt:Float):SlapResult {
        doMovement(ply);
        ply.arm.update(dt);
        var hit = ply.arm.collide(ball);
        if (hit.collided) {
            ball.hit(hit.normalX, hit.normalY, hit.power);
            playSlapSound();
            shake = ball.speedMod * HIT_SHAKE_SPEEDMOD_MUL;
        }
        return hit;
    }

    function hurtSide(side:Side) {
        /**
         * 1. reduce side's lives
         * 2. if lives > 0 return
         * 3. replace state with gameover
         */
    }

    function playSlapSound() {
        slapSounds[rand.random(slapSounds.length)].play();
    }

    function doMovement(ply:Player) {
        if (ply == PlayerManager.dai) {
            var targetOffset = ball.y - height / 2;
            ply.arm.setOffset(0, targetOffset * 0.8 + Math.sin(Sys.time() * 2) * height * 0.2);

            if (ball.x > width * AI_SLAP_X_THRESHOLD_MUL) {
                ply.arm.slap();
            }
        } else {
            var yAxis = Input.getAxis(moveY, player(ply.padIndex));
            ply.arm.setOffset(Input.getAxis(moveX, player(ply.padIndex)) * MAX_ARM_DEFLECTION_X, yAxis * height * ARM_DEFLECTION_Y_MUL);
            ply.arm.rotation = yAxis * ARM_ROTATION_MUL;

            if (Input.getButtonPressed(slap, player(ply.padIndex))) {
                ply.arm.slap();
            }
        }
    }
}
