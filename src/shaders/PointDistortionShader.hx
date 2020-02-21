package shaders;

/**
 * Distorts the background around a given position and wave center/radius.
 */
class PointDistortionShader extends h3d.shader.ScreenShader {
    @SuppressWarnings("checkstyle:MagicNumber")
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
