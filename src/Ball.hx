typedef BounceResult = {hitSide:Bool, side:Side};

class Ball extends h2d.Object {
	var radius:Float;

	var vx:Float;
	var vy:Float;

	static inline final BASE_SPEED = 500;

	public var speedMod(default, null):Float; // starts at 1 and rises with each hit

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
		pg.isRelative = false;
		pg.speed = 1;
		pg.emitDist = 10;
		pg.texture = hxd.Res.graphics.star_particle.toTexture();
		pg.life = 0.2;
		pg.lifeRand = 0.5;
		pg.size = 0.8;
		pg.sizeRand = 0.2;
		p.addGroup(pg);

		new h2d.Bitmap(tile, this);

		setPosition(x, y);
	}

	public function hit(nx:Float, ny:Float, power:Float) {
		vx = nx * BASE_SPEED * power * speedMod;
		vy = ny * BASE_SPEED * power * speedMod;
		speedMod += power / 10;
	}

	public function bounce(x0:Float, y0:Float, x1:Float, y1:Float):BounceResult {
		var result:BounceResult = {hitSide: false, side: null};
		if (x < x0) {
			x = x0;
			if (vx < 0) {
				result.hitSide = true;
				result.side = Left;
				vx = -vx;
			}
		}
		if (x >= x1) {
			x = x1;
			if (vx > 0) {
				vx = -vx;
				result.hitSide = true;
				result.side = Right;
			}
		}
		if (y < y0) {
			y = y0;
			if (vy < 0)
				vy = -vy;
		}
		if (y >= y1) {
			y = y1;
			if (vy > 0)
				vy = -vy;
		}

		return result;
	}

	public function calculateSpeed() {
		return Math.sqrt(vx * vx + vy * vy);
	}

	public function update(dt:Float) {
		x += vx * dt;
		y += vy * dt;
	}
}
