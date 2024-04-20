extends Node

## Summons an object into the current scene and returns it. If the object is not already cached, it will be cached to prevent lag. 
## If `cache` is disabled, the object will never be cached (unless it already is).
static func summonObject(alias: String, doCache=true):
    # Check if object exists via ResourceLoader, because when game is exported, objects will be imported into game and can't be checked via FileAccess.
    if alias in usapi.cache.objects.keys(): # Load the preloaded object instead to prevent major disk usage.
        usapi.cache.objects[alias].times_used += 1
        usapi.cache.objects[alias].last_used = Time.get_ticks_msec()
        var newobj = usapi.cache.objects[alias].object.instantiate()
        usapi.getTree().current_scene.add_child(newobj)
        return newobj
    # Load the object from disk and cache it.
    if not ResourceLoader.exists(usapi.projectConfig.objectsFolder + "/" + alias + ".tscn"): usapi.doLog("Cannot summon alias \"{0}\", file path \"{1}\" could not be found.".format([alias, usapi.projectConfig.objectsFolder + "/" + alias + ".tscn"]), usapi.LogLevels.Warn); return null;
    var newobj = load(usapi.projectConfig.objectsFolder + "/" + alias + ".tscn")
    if doCache: var cacheSuccess = usapi._smart_cache(newobj, alias);
    newobj = newobj.instantiate()
    usapi.getTree().current_scene.add_child(newobj)
    return newobj
