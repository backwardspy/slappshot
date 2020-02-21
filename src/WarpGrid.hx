/**
 * Provides a background image to a scene that is distorted by the PointDistortionShader.
 */
class WarpGrid extends h2d.Bitmap {
    static inline final DEFAULT_POINTSTRENGTH:Float = 1.0;
    static inline final MAX_WAVE_RADIUS:Float = 1.5;
    static inline final WAVE_EXPANSION_PER_SECOND:Float = 1.5;

    var shader:shaders.PointDistortionShader;

    public function new(tile:h2d.Tile, scene:h2d.Scene) {
        super(tile, scene);

        shader = new shaders.PointDistortionShader();
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
