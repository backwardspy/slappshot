/**
 * Applies a noisy grain effect to the screen.
 */
class GrainShader extends h3d.shader.ScreenShader {
	static var SRC:String = {
		@param var time:Float;
		@param var texture:Sampler2D;
		function fragment() {
			var uv = input.uv;
			var tc = texture.get(uv);

			// https://www.shadertoy.com/view/4t2fRz
			var seed = dot(uv, vec2(12.9898, 78.233));
			var noise = 0.8 + 0.2 * fract(sin(seed) * 43758.5453 + time);

			pixelColor = vec4(tc.rgb * noise, tc.a);
		}
	}
}
