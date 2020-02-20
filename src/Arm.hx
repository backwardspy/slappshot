enum SlapDirection {
	Up;
	Down;
}

class Tween {
	public var active(default, null):Bool;

	public var from(default, null):Float;
	public var to(default, null):Float;
	public var value(get, null):Float;

	public var progress(default, null):Float;
	public var length(default, null):Float;

	public function new() {
		from = 0;
		to = 1;
		length = 1;
		progress = 1;
		active = false;
	}

	public function init(from:Float, to:Float, length:Float) {
		this.from = from;
		this.to = to;
		this.length = length;
		progress = 0;
		active = true;
	}

	public function update(dt:Float) {
		if (!active)
			return;

		if (progress < length) {
			progress = Math.min(progress + dt, length);
		} else {
			progress = length;
			active = false;
		}
	}

	public function ease(k:Float) {
		return 1 - Math.pow(1 - k, 5);
	}

	function get_value() {
		if (!active)
			return to;

		var k = progress / length;
		return hxd.Math.lerp(from, to, ease(k));
	}
}

typedef SlappResult = {collided:Bool, power:Float, normalX:Float, normalY:Float};

class Arm extends h2d.Object {
	public var lives(default, null):Int; // depleted by one on each missed ball

	var flipped:Bool;

	var shoulder:h2d.Bitmap;
	var elbow:h2d.Bitmap;
	var wrist:h2d.Bitmap;

	var baseX:Float;
	var baseY:Float;

	var slapDirection:SlapDirection;

	var slappTween:Tween;

	var slappRadius:Float;

	var canHit:Bool; // set true when a slap is started, set false again when contacting the ball
	var hitZoneTimer:Float;

	static inline final MAX_LIVES = 3; // TODO: variable?

	static inline final HITZONE_ACTIVE_TIME = 0.15; // how long the hitzone is alive for after slapping, in seconds
	static inline final SLAP_ANIM_LENGTH = 0.3; // how long the slap animation is, in seconds

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

		slappRadius = 350;

		this.flipped = flipped;

		baseX = x;
		baseY = y;
		setPosition(x, y);
		scaleX = 2;
		scaleY = flipped ? -2 : 2;

		slappTween = new Tween();
		slapDirection = SlapDirection.Up;
		setBend(1);

		lives = MAX_LIVES;
	}

	public function update(dt:Float) {
		slappTween.update(dt);
		setBend(slappTween.value * 0.8);

		if (hitZoneTimer > 0.0) {
			hitZoneTimer -= dt;

			if (hitZoneTimer < 0.0)
				hitZoneTimer = 0.0;
		}
	}

	public function setRotation(radians:Float) {
		rotation = radians;
	}

	public function setBend(radians:Float) {
		shoulder.rotation = radians;
		elbow.rotation = radians;
		wrist.rotation = radians;
	}

	public function setOffset(x:Float, y:Float) {
		setPosition(baseX + x, baseY + y);
	}

	public function slapp() {
		if (slappTween.active)
			return;

		canHit = true;
		hitZoneTimer = HITZONE_ACTIVE_TIME;

		switch (this.slapDirection) {
			case Up:
				this.slapDirection = Down;
				slappTween.init(1, -1, SLAP_ANIM_LENGTH);
			case Down:
				this.slapDirection = Up;
				slappTween.init(-1, 1, SLAP_ANIM_LENGTH);
		}
	}

	public function hurt():Bool {
		return --lives <= 0;
	}

	public function collide(ball:Ball):SlappResult {
		var result:SlappResult = {
			collided: false,
			power: 0,
			normalX: 0,
			normalY: 0,
		};

		if (!canHit || hitZoneTimer <= 0.0)
			return result;

		var dy = ball.y - y;
		var dx = ball.x - x;
		var distSq = dx * dx + dy * dy;

		if (distSq > slappRadius * slappRadius)
			return result;

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
