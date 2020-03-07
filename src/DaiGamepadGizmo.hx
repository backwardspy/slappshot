/**
 * A special GamepadGizmo used by Dai.
 */
class DaiGamepadGizmo extends GamepadGizmo {
    static inline final TINT:Int = 0xFF7733;

    public function new(x:Float, y:Float, ?parent:h2d.Object) {
        super(x, y, parent);

        super.setText("D.A.I");
        super.setTint(TINT);
    }

    override function setText(textString:String) {}

    override function setTint(colour:Int) {}
}
