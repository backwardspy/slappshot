/**
 * A singleton that manages players in the game.
 */
class PlayerManager {
    /**
     * The maximum number of supported players.
     */
    public static inline final MAX_PLAYERS:Int = 4;

    /**
     * The index of Dai in the players array.
     */
    public static inline final DAI_INDEX:Int = 1;

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

    /**
     * Debug AI player. Only present when player 1 is the sole active player.
     */
    public static var dai(default, null):Player;

    var players:Array<Player>;

    function new() {
        players = [];
        for (i in 0...MAX_PLAYERS) {
            setupPlayer(i);
        }
        setupDAI();
    }

    static function setupDAI() {
        if (dai != null) {
            return;
        }

        dai = {
            active: true,
            ready: true,
            gizmo: null,
            side: right,
            arm: null,
            padIndex: DAI_INDEX,
        };
    }

    function setupPlayer(index:Int) {
        checkIndex(index);
        players[index] = {
            active: false,
            ready: false,
            gizmo: null,
            side: if (index % 2 == 0) left else right,
            arm: null,
            padIndex: index,
        };
    }

    /**
     * Put Dai into the players array.
     */
    public static function addDai() {
        if (instance.players[DAI_INDEX] != dai) {
            instance.players[DAI_INDEX] = dai;
        }
    }

    /**
     * Remove Dai from the players array.
     */
    public static function removeDai() {
        if (instance.players[DAI_INDEX] == dai) {
            instance.setupPlayer(DAI_INDEX);
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
}
