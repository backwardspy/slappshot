/**
 * An object to be stored in a pool.
 */
typedef PooledObject<T> = {instance:T, alive:Bool}

/**
 * Manages a list of objects, providing methods to get or create an instance.
 */
class Pool<T> {
    var objects:List<PooledObject<T>>;

    public function new() {
        objects = new List<PooledObject<T>>();
    }

    /**
     * Get or create an object. This object may need to be reinitialised.
     * @param createNew A function to create a new T instance if necessary.
     * @return T The object from the pool.
     */
    public function get(createNew:() -> T):T {
        for (object in objects) {
            if (!object.alive) {
                object.alive = true;
                return object.instance;
            }
        }

        var instance = createNew();
        objects.add({instance: instance, alive: true});
        trace('pool now contains ${objects.length} items');
        return instance;
    }

    /**
     * Return an object to the pool. The object should not be used after calling this function.
     * @param instance The T instance to return.
     */
    public function release(instance:T) {
        for (object in objects) {
            if (object.instance == instance && object.alive) {
                object.alive = false;
                return;
            }
        }
    }
}
