package states;

class GameOver extends State {
	public function new(winningSide:Side) {
		super();
		var text = new h2d.Text(hxd.res.DefaultFont.get(), this);
		text.text = '$winningSide wins!';
		text.textAlign = Center;
		text.setPosition(width / 2, height / 2);
	}
}
