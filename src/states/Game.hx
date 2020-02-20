package states;

class Game extends State {
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

	var rand:hxd.Rand = new hxd.Rand(Std.int(Sys.time()));

	public function new() {
		super();

		for (i in 0...SLAPP_SOUNDS_COUNT) {
			var path = 'audio/slap$i.ogg';
			slappSounds.push(hxd.Res.load(path).toSound());
		}

		grid = new WarpGrid(hxd.Res.graphics.backdrop_castle.toTile(), this);

		leftArm = new Arm(0, height / 2, hxd.Res.graphics.arm_male_shoulder.toTile(), hxd.Res.graphics.arm_male_elbow.toTile(),
			hxd.Res.graphics.arm_male_wrist.toTile(), this);
		rightArm = new Arm(width, height / 2, hxd.Res.graphics.arm_male_shoulder.toTile(), hxd.Res.graphics.arm_male_elbow.toTile(),
			hxd.Res.graphics.arm_male_wrist.toTile(), this, true);
		rightArm.setRotation(Math.PI);

		ball = new Ball(width / 4, height / 2, hxd.Res.graphics.ball_eye.toTile(), this);

		filter = new h2d.filter.Group([new h2d.filter.Shader(grainShader), new h2d.filter.Shader(new VignetteShader())]);
	}

	public override function update(dt:Float) {
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
			var result = ball.bounce(0, 0, width, height);
			if (result.hitSide) {
				hurtArm(result.side);
			}
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
			grid.startWave(ball.x / width, ball.y / height, ball.speedMod / 5);
		}

		// effects to run when a hitstop ends
		if (hitWasActive && !hitstop.active) {
			hitParticles(Math.atan2(hitstop.hit.normalY, hitstop.hit.normalX));
		}

		grid.setPoint(ball.x / width, ball.y / height, ball.speedMod / 3);
		grid.update(dt);
	}

	function hurtArm(side:Side) {
		switch (side) {
			case Left:
				var died = leftArm.hurt();
				if (died) {
					// TODO: ragdoll left arm
					states.replace(new states.GameOver(Right));
				}
			case Right:
				var died = rightArm.hurt();
				if (died) {
					// TODO: ragdoll right arm
					states.replace(new states.GameOver(Left));
				}
		}
	}

	function playSlappSound() {
		slappSounds[rand.random(slappSounds.length)].play();
	}

	function doMovement(side:Side) {
		// TODO: generalise
		// TODO: remove hardcoded pad indices
		if (side == Left) {
			var yAxis = Input.getAxis(MoveY, 0);
			leftArm.setOffset(Input.getAxis(MoveX, 0) * 50, yAxis * height * 0.4);
			leftArm.rotation = yAxis * 0.3;

			if (Input.getButtonPressed(Slap, 0)) {
				leftArm.slapp();
			}
		} else {
			rightArm.setOffset(0, Math.sin(Sys.time()) * height * 0.4);

			if (ball.x > 4 * width / 5)
				rightArm.slapp();
		}
	}

	function hitParticles(angle:Float) {
		// TODO: use a pool to avoid all these allocations
		var p = new h2d.Particles(this);
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
}
