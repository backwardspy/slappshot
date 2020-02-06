class Main extends hxd.App {
	var pad:hxd.Pad;

	var arm:Arm;
	var arm2:Arm;

	override function init() {
		hxd.Res.initEmbed();

		hxd.Pad.wait(onPad);

		this.engine.backgroundColor = 0xff241734;

		arm = new Arm(s2d.width / 2, 2 * s2d.height / 5, hxd.Res.graphics.arm_male_shoulder.toTile(), hxd.Res.graphics.arm_male_elbow.toTile(), hxd.Res.graphics.arm_male_wrist.toTile(), s2d);
		arm2 = new Arm(s2d.width / 2, 3 * s2d.height / 5, hxd.Res.graphics.arm_male_shoulder.toTile(), hxd.Res.graphics.arm_male_elbow.toTile(), hxd.Res.graphics.arm_male_wrist.toTile(), s2d, true);
	}

	override function update(dt:Float) {
		arm.rotate(dt);
		arm2.rotate(-dt);
	}

	function onPad(pad:hxd.Pad) {
		if (this.pad == null)
			this.pad = pad;
	}

	static function main() {
		new Main();
	}
}
