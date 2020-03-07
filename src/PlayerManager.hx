/**
 * A singleton that manages players in the game.
 */
class PlayerManager {
    /**
     * The maximum number of supported players.
     */
    public static inline final MAX_PLAYERS:Int = 4;

    static var instance:PlayerManager;

    /**
     * Count the number of active players.
     */
    public static var numActivePlayers(get, null):Int;

    static function get_numActivePlayers():Int {
        return [
            for (i in 0...MAX_PLAYERS) {
                if (getPlayer(i).active) {
                    i;
                }
            }
        ].length;
    }

    var players:Array<Player>;

    function new() {
        players = [];
        for (i in 0...MAX_PLAYERS) {
            addPlayer(i);
        }
    }

    /**
     * Initialise the static instance on the first call. Subsequent calls do nothing.
     */
    public static function init() {
        if (instance == null) {
            instance = new PlayerManager();
        }
    }

    /**
     * Get a reference to the player at the given index.
     * @param index The index of the player.
     * @return Player The player at the given index.
     */
    public static function getPlayer(index:Int):Player {
        checkIndex(index);
        return instance.players[index];
    }

    static function checkIndex(index:Int) {
        if (index < 0 || index > MAX_PLAYERS) {
            throw "index out of bounds";
        }
    }

    function addPlayer(index:Int) {
        checkIndex(index);
        players[index] = {
            active: false,
            ready: false,
            gizmo: null,
            side: if (index % 2 == 0) left else right,
            arm: null,
            padIndex: index
        }
    }
}
