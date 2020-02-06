class Arm {
	var base:h2d.Object;
	var shoulder:h2d.Bitmap;
	var elbow:h2d.Bitmap;
	var wrist:h2d.Bitmap;

	public function new(x:Float, y:Float, shoulder:h2d.Tile, elbow:h2d.Tile, wrist:h2d.Tile, scene:h2d.Scene, ?flip:Bool=false) {
		base = new h2d.Object(scene);
		base.setPosition(x, y);

		if (flip) {
			shoulder.flipY();
			elbow.flipY();
			wrist.flipY();
		}

		// TODO: load all this from arm config
		shoulder.dx = -33;
		shoulder.dy = -32;

		elbow.dx = -27;
		elbow.dy = -15;

		wrist.dx = -36;
		wrist.dy = -16;

		this.shoulder = new h2d.Bitmap(shoulder, base);
		this.elbow = new h2d.Bitmap(elbow, this.shoulder);
		this.wrist = new h2d.Bitmap(wrist, this.elbow);

		this.shoulder.setPosition(0, 0);
		this.elbow.setPosition(99 + shoulder.dx, 31 + shoulder.dy);
		this.wrist.setPosition(105 + elbow.dx, 14 + elbow.dy);
	}

	public function rotate(delta: Float) {
		this.shoulder.rotation += delta;
		this.elbow.rotation += delta;
		this.wrist.rotation += delta;
	}
}
