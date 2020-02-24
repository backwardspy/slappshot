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

    static inline final MAX_PLAYERS:Int = 4;

    var grid:WarpGrid;

    var players:haxe.ds.Vector<Player>;

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

    public function new() {
        trace("initialising game state...");
        super();

        slapSounds = [];
        for (i in 0...SLAP_SOUNDS_COUNT) {
            var path = 'audio/slap$i.ogg';
            slapSounds.push(hxd.Res.load(path).toSound());
        }

        grid = new WarpGrid(hxd.Res.graphics.backdrop_castle.toTile(), this);

        var leftArm = new Arm(0, height / 2, hxd.Res.graphics.arm_male_shoulder.toTile(), hxd.Res.graphics.arm_male_elbow.toTile(),
            hxd.Res.graphics.arm_male_wrist.toTile(), this);

        var rightArm = new Arm(width, height / 2, hxd.Res.graphics.arm_male_shoulder.toTile(), hxd.Res.graphics.arm_male_elbow.toTile(),
            hxd.Res.graphics.arm_male_wrist.toTile(), this, true);
        rightArm.setRotation(Math.PI);

        // the last two players are left empty for now...
        players = new haxe.ds.Vector(MAX_PLAYERS);
        players[0] = {side: Side.left, arm: leftArm, padIndex: 0};
        players[1] = {side: Side.right, arm: rightArm, padIndex: 1};

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

        trace("game state initialised");
    }

    override public function update(dt:Float) {
        var lastHit:SlapResult = null;
        var lastHitSide:Side = null;

        for (ply in players) {
            if (ply != null) {
                ply.arm.updateVisuals(dt);
            }

            if (ply == null || (hitstop.active && hitstop.side == ply.side)) {
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
                switch (result.side) {
                    case left:
                        hurtPlayer(players[0]);
                    case right:
                        hurtPlayer(players[1]);
                }
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
        logWindow.update(dt);
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
        }
        return hit;
    }

    function hurtPlayer(ply:Player) {
        var died = ply.arm.hurt();
        trace('${ply.side} reduced to ${ply.arm.lives} lives');
        if (died) {
            trace('${ply.side} died!');
            var otherSide:Side = switch (ply.side) {
                case left: right;
                case right: left;
            }
            states.replace(new GameOver(otherSide));
        }
    }

    function playSlapSound() {
        slapSounds[rand.random(slapSounds.length)].play();
    }

    function doMovement(ply:Player) {
        // temporary split here to give me an "ai" to play against.
        if (ply.side == left) {
            var yAxis = Input.getAxis(moveY, player(ply.padIndex));
            ply.arm.setOffset(Input.getAxis(moveX, player(ply.padIndex)) * MAX_ARM_DEFLECTION_X, yAxis * height * ARM_DEFLECTION_Y_MUL);
            ply.arm.rotation = yAxis * ARM_ROTATION_MUL;

            if (Input.getButtonPressed(slap, player(ply.padIndex))) {
                ply.arm.slap();
            }
        } else {
            // ply.arm.setOffset(0, Math.sin(Sys.time() * 5) * height * ARM_DEFLECTION_Y_MUL);
            var targetOffset = ball.y - height / 2;
            ply.arm.setOffset(0, targetOffset * 0.8 + Math.sin(Sys.time() * 2) * height * 0.2);

            if (ball.x > width * AI_SLAP_X_THRESHOLD_MUL) {
                ply.arm.slap();
            }
        }
    }
}
