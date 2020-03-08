/**
 * Splits a tile into 9 pieces and renders them to fill a given area.
 */
class NinePatch extends h2d.Object {
    static inline final STRIDE:Int = 3;

    var pieces:Array<Array<h2d.Bitmap>>;
    var pieceSize:Float;

    public function new(tile:h2d.Tile, ?parent:h2d.Object) {
        super(parent);

        pieceSize = tile.width / STRIDE;
        var tiles = tile.grid(pieceSize);

        pieces = [];
        for (i in 0...STRIDE) {
            pieces[i] = [];
            for (j in 0...STRIDE) {
                pieces[i][j] = new h2d.Bitmap(tiles[i][j], this);
                pieces[i][j].setPosition(i * pieceSize, j * pieceSize);
            }
        }
    }

    /**
     * Reshape the NinePatch to fit the given bounding box.
     * @param x Left X coordinate.
     * @param y Top Y coordinate.
     * @param width Box width.
     * @param height Box height.
     */
    public function setBox(x:Float, y:Float, width:Float, height:Float) {
        setPosition(x, y);
        var scaleX = (width - STRIDE * 2) / pieceSize;
        var scaleY = (height - STRIDE * 2) / pieceSize;

        x = 0;
        for (i in 0...STRIDE) {
            var shouldScaleX = i == 1;
            y = 0;
            for (j in 0...STRIDE) {
                var shouldScaleY = j == 1;
                if (shouldScaleX) {
                    pieces[i][j].scaleX = scaleX;
                }
                if (shouldScaleY) {
                    pieces[i][j].scaleY = scaleY;
                }

                pieces[i][j].setPosition(x, y);
                y += pieceSize * (if (shouldScaleY) scaleY else 1);
            }
            x += pieceSize * (if (shouldScaleX) scaleX else 1);
        }
    }
}
