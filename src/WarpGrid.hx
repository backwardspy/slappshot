class PointDistortionShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture:Sampler2D;
		@param var point:Vec2;
		@param var pointStrength:Float;
		@param var waveCenter:Vec2;
		@param var waveRadius:Float;
		@param var waveStrength:Float;
		function fragment() {
			var pointDiff = pointStrength * pow(1 - clamp(length(point - input.uv), 0, 1), 8 + pointStrength) / 150;
			var waveDiff = waveStrength * pow(1 - clamp(abs(length(waveCenter - input.uv) - waveRadius), 0, 1), 8 + waveStrength) / 150;
			var diff = pointDiff + waveDiff;

			var uv = -1 + 2 * input.uv;
			uv /= pow(1 + diff, 3);
			uv = 0.5 + 0.5 * uv;

			var r = texture.get(uv - vec2(diff / 2)).r;
			var g = texture.get(uv).g;
			var b = texture.get(uv + vec2(diff / 2)).b;
			pixelColor = vec4(r, g, b, 1);
		}
	}
}

class WarpGrid extends h2d.Bitmap {
	var shader:PointDistortionShader;

	static inline final DEFAULT_POINTSTRENGTH = 1.0;

	public function new(tile:h2d.Tile, scene:h2d.Scene) {
		super(tile, scene);

		shader = new PointDistortionShader();
		shader.pointStrength = DEFAULT_POINTSTRENGTH;
		shader.waveStrength = 0;
		filter = new h2d.filter.Shader(shader);
	}

	public function update(dt:Float) {
		if (shader.waveRadius < 1.5) {
			shader.waveRadius += dt * 1.5;

			if (shader.waveRadius >= 1.5) {
				shader.waveStrength = 0;
			}
		}
	}

	public function setPoint(x:Float, y:Float, strength:Float = DEFAULT_POINTSTRENGTH) {
		shader.point.x = x;
		shader.point.y = y;
		shader.pointStrength = strength;
	}

	public function startWave(x:Float, y:Float, strength:Float) {
		shader.waveCenter.x = x;
		shader.waveCenter.y = y;
		shader.waveRadius = 0;
		shader.waveStrength = strength;
	}
}
