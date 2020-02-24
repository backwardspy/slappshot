package shaders;

/**
 * Inverts colours in a radius around a point.
 */
class InversionSphereShader extends h3d.shader.ScreenShader {
    @SuppressWarnings("checkstyle:MagicNumber")
    static var SRC:String = {
        @param var texture:Sampler2D;
        @param var point:Vec2;
        @param var radius:Float;
        @param var aspect:Float;
        function fragment() {
            var c = texture.get(input.uv).rgb;
            var adjust = vec2(aspect, 1);
            var uv = input.uv * adjust;
            var p = point * adjust;
            var inv = smoothstep(radius - 0.005, radius, pow(length(uv - p), 0.5));
            c = mix(1 - c, c, inv);
            pixelColor = vec4(c, 1);
        }
    }
}
