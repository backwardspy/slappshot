class VignetteShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture:Sampler2D;
		function fragment() {
			var uv = input.uv;

			var tc = texture.get(uv);

			uv -= 0.5;
			var vig = 1 - smoothstep(0.2, 0.9, length(uv));

			pixelColor = vec4(tc.rgb * vig, tc.a);
		}
	}
}
