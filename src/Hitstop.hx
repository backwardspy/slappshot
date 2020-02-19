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
