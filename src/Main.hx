enum Side {
	Left;
	Right;
}

class Hitstop {
	public var side(default, null):Side;
	public var hit(default, null):Arm.SlappResult;
	public var active(default, null):Bool;

	var time:Float;

	public function new() {
		active = false;
	}

	public function init(time:Float, side:Side, hit:Arm.SlappResult) {
		if (this.active) {
			trace("warning: attempt to init active hitstop!");
			return;
		}
		this.time = time;
		this.side = side;
		this.hit = hit;
		this.active = true;
	}

	public function update(dt:Float) {
		if (!this.active)
			return;

		this.time -= dt;
		if (this.time <= 0) {
			this.time = 0;
			this.active = false;
		}
	}
}

class Main extends hxd.App {
	var pad:hxd.Pad;

	var grid:WarpGrid;

	var leftArm:Arm;
	var rightArm:Arm;

	static inline final SLAPP_SOUNDS_COUNT = 16;
	var slappSounds = new Array<hxd.res.Sound>();

	var ball:Ball;

	var hitstop = new Hitstop();
	var hitWasActive = false;

	var grainShader = new GrainShader();

	var hitstopTime = 0.1;

	var rand: hxd.Rand = new hxd.Rand(Std.int(Sys.time()));

	override function init() {
		s2d.scaleMode = h2d.Scene.ScaleMode.LetterBox(1280, 800);

		hxd.Res.initEmbed();

		hxd.Pad.wait(onPad);

		for (i in 0...SLAPP_SOUNDS_COUNT) {
			var path = 'audio/slap$i.ogg';
			slappSounds.push(hxd.Res.load(path).toSound());
		}

		grid = new WarpGrid(hxd.Res.graphics.backdrop_castle.toTile(), s2d);

		leftArm = new Arm(0, s2d.height / 2, hxd.Res.graphics.arm_male_shoulder.toTile(), hxd.Res.graphics.arm_male_elbow.toTile(),
			hxd.Res.graphics.arm_male_wrist.toTile(), s2d);
		rightArm = new Arm(s2d.width, s2d.height / 2, hxd.Res.graphics.arm_male_shoulder.toTile(), hxd.Res.graphics.arm_male_elbow.toTile(),
			hxd.Res.graphics.arm_male_wrist.toTile(), s2d, true);
		rightArm.setRotation(Math.PI);

		ball = new Ball(s2d.width / 4, s2d.height / 2, hxd.Res.graphics.ball_eye.toTile(), s2d);

		s2d.filter = new h2d.filter.Group([new h2d.filter.Shader(grainShader), new h2d.filter.Shader(new VignetteShader())]);
	}

	override function update(dt:Float) {
		var lastHit:Arm.SlappResult = null;
		var lastHitSide:Side = null;

		var leftFrozen = hitstop.active && hitstop.side == Left;
		var rightFrozen = hitstop.active && hitstop.side == Right;

		if (!leftFrozen)
			doMovement(Left);
		if (!rightFrozen)
			doMovement(Right);

		if (!leftFrozen)
			leftArm.update(dt);
		if (!rightFrozen)
			rightArm.update(dt);

		if (!leftFrozen) {
			var hit = leftArm.collide(ball);
			if (hit.collided) {
				ball.hit(hit.normalX, hit.normalY, hit.power);
				playSlappSound();
				lastHitSide = Left;
				lastHit = hit;
			}
		}

		if (!rightFrozen) {
			var hit = rightArm.collide(ball);
			if (hit.collided) {
				ball.hit(hit.normalX, hit.normalY, hit.power);
				playSlappSound();
				lastHitSide = Right;
				lastHit = hit;
			}
		}

		// we check lasthit to skip updating on the frame we hit the ball
		if (!hitstop.active && lastHit == null) {
			ball.bounce(0, 0, s2d.width, s2d.height);
			ball.update(dt);
		}

		// TODO: tweak this minimum, good mutator option
		hitstopTime = Math.min(0.05, Math.pow(ball.speedMod / 10, 2));

		grainShader.time = Sys.time();

		hitWasActive = hitstop.active;
		if (lastHit != null) {
			hitstop.init(hitstopTime, lastHitSide, lastHit);
		}
		hitstop.update(dt);

		// effects to run when a hitstop starts
		if (hitstop.active && !hitWasActive) {
			grid.startWave(ball.x / s2d.width, ball.y / s2d.height, ball.speedMod / 5);
		}

		// effects to run when a hitstop ends
		if (hitWasActive && !hitstop.active) {
			hitParticles(Math.atan2(hitstop.hit.normalY, hitstop.hit.normalX));
		}

		grid.setPoint(ball.x / s2d.width, ball.y / s2d.height, ball.speedMod / 3);
		grid.update(dt);
	}

	function playSlappSound() {
		slappSounds[rand.random(slappSounds.length)].play();
	}

	function doMovement(side:Side) {
		// todo: generalise
		if (side == Left) {
			if (this.pad != null) {
				leftArm.setOffset(this.pad.xAxis * 50, this.pad.yAxis * s2d.height * 0.4);
				leftArm.rotation = this.pad.yAxis * 0.3;

				if (this.pad.isPressed(this.pad.config.A)) {
					leftArm.slapp();
				}
			}
		} else {
			rightArm.setOffset(0, Math.sin(Sys.time()) * s2d.height * 0.4);

			if (ball.x > 4 * s2d.width / 5)
				rightArm.slapp();
		}
	}

	function hitParticles(angle:Float) {
		// TODO: use a pool to avoid all these allocations
		var p = new h2d.Particles(s2d);
		p.setPosition(ball.x, ball.y);
		p.rotation = angle - Math.PI / 2;
		var pg = new h2d.Particles.ParticleGroup(p);
		pg.texture = hxd.Res.graphics.diamond_particle.toTexture();
		pg.emitLoop = false;
		pg.nparts = 50;
		pg.speed = ball.calculateSpeed() * 0.4;
		pg.speedRand = 1;
		pg.emitSync = 0.9;
		pg.emitMode = h2d.Particles.PartEmitMode.Cone;
		pg.emitAngle = 0.1;
		pg.emitDist = 50;
		pg.life = 0.5;
		p.addGroup(pg);

		p.onEnd = function() {
			p.remove();
		}
	}

	function onPad(pad:hxd.Pad) {
		if (this.pad == null)
			this.pad = pad;
	}

	static function main() {
		new Main();
	}
}
