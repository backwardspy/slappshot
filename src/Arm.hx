// TODO: move the non-arm types into their own files.

/**
 * The direction the arm is moving during a slap.
 */
enum SlapDirection {
	up;
	down;
}

/**
 * Smoothly interpolates between two values over a given duration.
 */
class Tween {
	static inline final EASE_POWER:Int = 5;

	/**
	 * Whether the tween is currently active or not.
	 */
	public var active(default, null):Bool;

	/**
	 * The value to tween from.
	 */
	public var from(default, null):Float;

	/**
	 * The value to tween to.
	 */
	public var to(default, null):Float;

	/**
	 * The current interpolated value.
	 */
	public var value(get, null):Float;

	/**
	 * The linear progress through the tween's duration.
	 */
	public var progress(default, null):Float;

	/**
	 * How long the tween should take, in seconds.
	 */
	public var length(default, null):Float;

	public function new() {
		from = 0;
		to = 1;
		length = 1;
		progress = 1;
		active = false;
	}

	/**
	 * Initialise the tween, setting it active.
	 * @param tweenFrom The value to start from.
	 * @param tweenTo The value to stop on.
	 * @param tweenLength How long the tween should last, in seconds.
	 */
	public function init(tweenFrom:Float, tweenTo:Float, tweenLength:Float) {
		this.from = tweenFrom;
		this.to = tweenTo;
		this.length = tweenLength;
		progress = 0;
		active = true;
	}

	/**
	 * Updates the tween, setting it inactive if the duration has passed.
	 * @param dt Delta time.
	 */
	public function update(dt:Float) {
		if (!active) {
			return;
		}

		if (progress < length) {
			progress = Math.min(progress + dt, length);
		} else {
			progress = length;
			active = false;
		}
	}

	/**
	 * Ease the given parameter using a power function.
	 * @param k The value to ease.
	 * @return The eased value.
	 */
	public function ease(k:Float):Float {
		return 1 - Math.pow(1 - k, EASE_POWER);
	}

	function get_value():Float {
		if (!active) {
			return to;
		}

		var k = progress / length;
		return hxd.Math.lerp(from, to, ease(k));
	}
}

/**
 * Result of an arm <=> ball collision
 */
typedef SlapResult = {collided:Bool, power:Float, normalX:Float, normalY:Float};

/**
 * A player's arm. Used to slap the ball.
 */
class Arm extends h2d.Object {
	// TODO: variable?
	static inline final MAX_LIVES:Int = 3;

	static inline final HITZONE_ACTIVE_TIME:Float = 0.15;
	static inline final SLAP_ANIM_LENGTH:Float = 0.3;

	static inline final SLAP_RADIUS:Float = 350.0;

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

		// TODO: load all this from arm config
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
		scaleX = 2;
		scaleY = switch (flipped) {
			case true: -2;
			case false: 2;
		}

		slapTween = new Tween();
		slapDirection = up;
		setBend(1);

		lives = MAX_LIVES;
	}

	/**
	 * Updates the arm.
	 * @param dt Delta time
	 */
	public function update(dt:Float) {
		slapTween.update(dt);
		setBend(slapTween.value * 0.8);

		if (hitZoneTimer > 0.0) {
			hitZoneTimer -= dt;

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
		if (slapTween.active) {
			return;
		}

		canHit = true;
		hitZoneTimer = HITZONE_ACTIVE_TIME;

		switch (this.slapDirection) {
			case up:
				this.slapDirection = down;
				slapTween.init(1, -1, SLAP_ANIM_LENGTH);
			case down:
				this.slapDirection = up;
				slapTween.init(-1, 1, SLAP_ANIM_LENGTH);
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

		if (!canHit || hitZoneTimer <= 0.0) {
			return result;
		}

		var dy = ball.y - y;
		var dx = ball.x - x;
		var distSq = dx * dx + dy * dy;

		if (distSq > SLAP_RADIUS * SLAP_RADIUS) {
			return result;
		}

		var dist = Math.sqrt(distSq);
		dy /= dist;
		dx /= dist;

		result.collided = true;
		result.power = 1;
		result.normalX = dx;
		result.normalY = dy;

		canHit = false; // can't hit again until the next slap

		return result;
	}
}
