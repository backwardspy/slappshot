/**
 * Distorts the background around a given position and wave center/radius.
 */
class PointDistortionShader extends h3d.shader.ScreenShader {
	static var SRC:String = {
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

/**
 * Provides a background image to a scene that is distorted by the PointDistortionShader.
 */
class WarpGrid extends h2d.Bitmap {
	static inline final DEFAULT_POINTSTRENGTH:Float = 1.0;
	static inline final MAX_WAVE_RADIUS:Float = 1.5;
	static inline final WAVE_EXPANSION_PER_SECOND:Float = 1.5;

	var shader:PointDistortionShader;

	public function new(tile:h2d.Tile, scene:h2d.Scene) {
		super(tile, scene);

		shader = new PointDistortionShader();
		shader.pointStrength = DEFAULT_POINTSTRENGTH;
		shader.waveStrength = 0;
		filter = new h2d.filter.Shader(shader);
	}

	/**
	 * Updates the WarpGrid and PointDistortionShader.
	 * @param dt Delta time.
	 */
	public function update(dt:Float) {
		if (shader.waveRadius < MAX_WAVE_RADIUS) {
			shader.waveRadius += dt * WAVE_EXPANSION_PER_SECOND;

			if (shader.waveRadius >= MAX_WAVE_RADIUS) {
				shader.waveStrength = 0;
			}
		}
	}

	/**
	 * Set the position of the warp point on the grid.
	 * @param x Point X coordinate.
	 * @param y Point Y coordinate.
	 * @param strength How much to warp the grid by.
	 */
	public function setPoint(x:Float, y:Float, strength:Float = DEFAULT_POINTSTRENGTH) {
		shader.point.x = x;
		shader.point.y = y;
		shader.pointStrength = strength;
	}

	/**
	 * Set up a new expanding wave.
	 * @param x The X coordinate of the wave center.
	 * @param y The Y coordinate of the wave center.
	 * @param strength How much to warp the grid by.
	 */
	public function startWave(x:Float, y:Float, strength:Float) {
		shader.waveCenter.x = x;
		shader.waveCenter.y = y;
		shader.waveRadius = 0;
		shader.waveStrength = strength;
	}
}
