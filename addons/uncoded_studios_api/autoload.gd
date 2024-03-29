extends Node

@onready var console = $Console
@onready var consoleLogs = $Console/Panel/Logs
@onready var consoleInput = $Console/Panel/CmdInput

@export var projectSettingsDefaultPath = "USAPI/"

var cache := {
    "objects": {
        # "aliasOfCachedObject": {
        #     "object": Node,
        #     "times_used": 1,
        #     "last_used": 0.0,
        #     "cache_timestamp": 0.0
        # }
    },
    "audio": {

    },
    "resources": {

    },
    "rooms": {

    }
}

var projectConfig := {}
var commands := {}

var internallogs := []

var modLoader = null

var debugMode := false

var global_volume = 1.0

enum LogLevels {Internal, Log, Warn, Error, Fatal}

func _ready():
    doLog("Hello, World!")
    projectConfig = {
        # Pathing
        "objectsFolder": ProjectSettings.get_setting("USAPI/Paths/ObjectsPath"),
        "resourcesFolder": ProjectSettings.get_setting("USAPI/Paths/ResourcesPath"),
        "roomsFolder": ProjectSettings.get_setting("USAPI/Paths/RoomsPath"),
        "audioFolder": ProjectSettings.get_setting("USAPI/Paths/AudioPath"),
        "scriptsFolder": ProjectSettings.get_setting("USAPI/Paths/ScriptsPath"),
        "assetsFolder": ProjectSettings.get_setting("USAPI/Paths/AssetsPath"),

        # Caching
        "doCaching": ProjectSettings.get_setting("USAPI/Caching/DoCaching"),
        "cacheLimit": ProjectSettings.get_setting("USAPI/Caching/CacheLimit"),
        "cacheObjects": ProjectSettings.get_setting("USAPI/Caching/CacheObjects"),
        "cacheResources": ProjectSettings.get_setting("USAPI/Caching/CacheResources"),
        "cacheRooms": ProjectSettings.get_setting("USAPI/Caching/CacheRooms"),
        "cacheAudio": ProjectSettings.get_setting("USAPI/Caching/CacheAudio"),
        "cacheObjectsOnStart": ProjectSettings.get_setting("USAPI/Caching/CacheObjectsOnStart"),
        "cacheAudioOnStart": ProjectSettings.get_setting("USAPI/Caching/CacheAudioOnStart"),
        "cacheResourcesOnStart": ProjectSettings.get_setting("USAPI/Caching/CacheResourcesOnStart"),
        "cacheRoomsOnStart": ProjectSettings.get_setting("USAPI/Caching/CacheRoomsOnStart"),

        # Console Related
        "consoleEnabled": ProjectSettings.get_setting("USAPI/Console/ConsoleEnabled") and InputMap.has_action("Console"),
        "customConsoleCommands": ProjectSettings.get_setting("USAPI/Console/AllowCustomConsoleCommands")

        # Anything else is excluded, we call from ProjectSettings for those.
    }
    projectConfig.make_read_only() # Prevent any additional modifiers. Since we are grabbing from ProjectSettings, no reason to edit this anyway.

    doLog("Current config:")
    doLog(str(projectConfig))

    if !InputMap.has_action("Console"):
        doLog("No Console input action detected. Disabling Console.", LogLevels.Warn)
    
    if !projectConfig.consoleEnabled:
        console.queue_free()
    
    if projectConfig.doCaching:
        var cache_clear_timer := Timer.new()
        cache_clear_timer.autostart = true
        cache_clear_timer.wait_time = 120
        cache_clear_timer.timeout.connect(func() -> void:
            clearCaches("objects")
            clearCaches("resources")
        )
        add_child(cache_clear_timer)

    for i: String in projectConfig: # Check if folder paths are valid.
        if !(i is String and i.ends_with("Folder")): continue ;
        if ProjectSettings.get_setting("USAPI/Misc/DoNotFolderTest"): break ;
        assert(projectConfig[i] != null, "ProjectSettings are not configured correctly. Missing \"{0}\".".format([i]))
        assert(DirAccess.dir_exists_absolute(projectConfig[i]), "Directory for \"{0}\" is invalid; Points to \"{1}\"".format([i, projectConfig[i]]))
    
    # Check if ModLoader exists.
    if ResourceLoader.exists(projectConfig.scriptsFolder + "/usapi-modloader.gd"):
        doLog("Detected USAPI ModLoader!")
        modLoader = load(projectConfig.scriptsFolder + "/usapi-modloader.gd")
        var modLoaderNode := Node.new()
        modLoaderNode.name = "modLoader"
        add_child(modLoaderNode)
        modLoaderNode.set_script(modLoader)
        modLoader = modLoaderNode
    setCommand("clear_all_caches", clearCaches)
    setCommand("reload_room", reloadScene)
    setCommand("summon_object", func(args) -> void:
        if args.is_empty(): return ;
        summonObject(args[0])
    )

# Check if console key pressed.
func _input(event):
    if projectConfig.consoleEnabled and event.is_action_pressed("Console") and get_viewport().gui_get_focus_owner() != consoleInput:
        get_tree().paused = !get_tree().paused
        console.visible = !console.visible
        if console.visible: consoleInput.call_deferred("grab_focus")
        get_viewport().set_input_as_handled()
    if projectConfig.consoleEnabled and get_viewport().gui_get_focus_owner() == consoleInput and event is InputEventKey and event.keycode == KEY_ENTER:
        var args: Array = consoleInput.text.split(" ")
        args.erase(consoleInput.text.split(" ")[0])
        doCommand(consoleInput.text.split(" ")[0], args)
        consoleInput.text = ""
        get_viewport().set_input_as_handled()

func _process(delta):
    if projectConfig.consoleEnabled: consoleLogs.text = ""; for i in internallogs:
        consoleLogs.text = consoleLogs.text + i + "\n"

## Clears all caches. May free up memory at the cost of lag when loading objects again.
func clearCaches(type=""):
    match type:
        "objects":
            doLog("Cleared object cache.", LogLevels.Internal)
            cache.objects.clear()
        "audio":
            doLog("Cleared audio cache.", LogLevels.Internal)
            cache.audio.clear()
        "resources":
            doLog("Cleared resource cache.", LogLevels.Internal)
            cache.resources.clear()
        "rooms":
            doLog("Cleared room cache.", LogLevels.Internal)
            cache.rooms.clear()
        _:
            doLog("Cleared all caches.")
            cache.objects.clear()
            cache.audio.clear()
            cache.resources.clear()
            cache.rooms.clear()

## Creates a command.
func setCommand(alias: String, callable: Callable):
    alias = alias.to_lower()
    for c in ["\\", "|", "\"", "'", ";", ":", "/", "?", ".", ">", ",", "<", "[", "]", "{", "}", "=", "+", "-", ")", "(", "*", "&", "^", "%", "$", "#", "@", "~", "`"]:
        alias = alias.replace(c, "")
    commands[alias] = callable

## Calls a command.
func doCommand(alias: String, arguments: Array):
    if alias.strip_edges() == "": return ;
    doLog("> {0} {1}".format([alias, str(arguments)]))
    if !commands.has(alias): return doLog("Command \"" + alias + "\" does not exist.", LogLevels.Warn)
    if alias.begins_with("db_") and !debugMode: return doLog("Command \"" + alias + "\" will not run with your current permissions.", LogLevels.Warn)
    return commands[alias].call(arguments)

## Custom log command.
func doLog(text: String, type: LogLevels=LogLevels.Log):
    internallogs.append(text)
    if type == LogLevels.Internal:
        return ;
    if type == LogLevels.Warn:
        print_rich("(W) USAPI: " + text)
        push_warning("USAPI: " + text)
        return ;
    if type == LogLevels.Error:
        printerr("(E) USAPI: " + text)
        push_error("USAPI: " + text)
        return ;
    if type == LogLevels.Fatal:
        printerr("(F) USAPI: " + text)
        assert(false, "USAPI " + text)
        propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
        get_tree().quit()
        return ;
    print("USAPI: " + text)

## Reloads the currently active scene.
func reloadScene(hardReload=false):
    if hardReload:
        doLog("Preparing to hard reload.")
        clearCaches("objects")
        clearCaches("rooms")
        clearCaches("resources")
    get_tree().reload_current_scene()
    doLog("Reloaded scene.")

## Summons an object into the current scene and returns it. If the object is not already cached, it will be cached to prevent lag. 
## If `cache` is disabled, the object will never be cached (unless it already is).
func summonObject(alias: String, doCache=true):
    # Check if object exists via ResourceLoader, because when game is exported, objects will be imported into game and can't be checked via FileAccess.
    if alias in cache.objects.keys(): # Load the preloaded object instead to prevent major disk usage.
        cache.objects[alias].times_used += 1
        cache.objects[alias].last_used = Time.get_ticks_msec()
        var newobj = cache.objects[alias].object.instantiate()
        get_tree().current_scene.add_child(newobj)
        return newobj
    # Load the object from disk and cache it.
    if not ResourceLoader.exists(projectConfig.objectsFolder + "/" + alias + ".tscn"): doLog("Cannot summon alias \"{0}\", file path \"{1}\" could not be found.".format([alias, projectConfig.objectsFolder + "/" + alias + ".tscn"]), LogLevels.Warn); return null;
    var newobj = load(projectConfig.objectsFolder + "/" + alias + ".tscn")
    if doCache: var cacheSuccess = _smart_cache(newobj, alias); doLog(str(cacheSuccess))
    newobj = newobj.instantiate()
    get_tree().current_scene.add_child(newobj)
    return newobj

func bindVisibilityToObject(objectBinder: Node2D, objectBinded: Node2D):
    if !objectBinded: return ;
    var ray := RayCast2D.new()
    var timer := Timer.new()
    timer.wait_time = 0.01
    timer.autostart = true
    timer.one_shot = false
    ray.name = "visibilityRayTo" + objectBinded.name
    objectBinder.add_child(ray)
    ray.add_child(timer)
    timer.timeout.connect(func():
        if !objectBinded:
            ray.queue_free()
            timer.queue_free()
            return ;
        objectBinded.visible=false
        ray.target_position=objectBinder.to_local(objectBinder.global_position)
        if ray.get_collider() == objectBinded:
            objectBinded.visible=true
    )

func startAudio(alias: String, startAt: int=0, doCache: bool=true):
    if alias in cache.audio.keys():
        cache.audio[alias].times_used += 1
        cache.audio[alias].last_used = Time.get_ticks_msec()
        var audiostr: AudioStream = cache.audio[alias].object
        var audioobj = AudioStreamPlayer.new()
        audioobj.stream = audiostr
        audioobj.autoplay = true
        audioobj.volume_db = -80 * (global_volume - 1.0)
        $AudioPlayers.add_child(audioobj)
        return audioobj
    if not (ResourceLoader.exists(projectConfig.objectsFolder + "/" + alias + ".mp3") or ResourceLoader.exists(projectConfig.objectsFolder + "/" + alias + ".ogg")): doLog("Cannot play audio alias \"{0}\", file path \"{1}\" could not be found.".format([alias, projectConfig.objectsFolder + "/" + alias + ".???"]), LogLevels.Warn); return null;
    var audiostr: AudioStream = load(projectConfig.objectsFolder + "/" + alias + ".mp3") if ResourceLoader.exists(projectConfig.objectsFolder + "/" + alias + ".mp3") else load(projectConfig.objectsFolder + "/" + alias + ".ogg")
    if doCache: var cacheSuccess = _smart_cache(audiostr, alias); doLog(str(cacheSuccess))
    var audioobj = AudioStreamPlayer.new()
    audioobj.stream = audiostr
    audioobj.autoplay = true
    audioobj.volume_db = -80 * (global_volume - 1.0)
    $AudioPlayers.add_child(audioobj)
    return audioobj

## INTERNAL FUNCTION.
## Uses advanced logic to cache an object.
func _smart_cache(object, alias: String=str(randf() * 5)) -> bool:
    if !projectConfig.doCaching: doLog("Not caching because caching is disabled globally.", LogLevels.Internal); return false;
    if !object: doLog("Attempted to smart cache null.", LogLevels.Error); return false;
    var is_resource = object is Resource and object.resource_path.begins_with(projectConfig.resourcesFolder)
    var is_audio = object is AudioStream or object is AudioStreamMP3 or object is AudioStreamOggVorbis or object is AudioStreamWAV
    var is_room = object is Resource and object.resource_path.begins_with(projectConfig.roomsFolder)
    var bad_cache_score = -INF
    var bad_cache_alias = ""
    doLog("Attempting to cache {0}, flags - isResource: {1}, isAudio: {2}, isRoom: {3}".format([str(object), str(is_resource), str(is_audio), str(is_room)]), LogLevels.Internal)
    if is_resource:
        var resourceObject: Resource = object; object = null # Transfer variables. This serves no actual purpose but to assist with code suggestions because I don't like reading ;.;
        if len(cache.resources) >= projectConfig.cacheLimit:
            doLog("Resources Cache full, doing smart cache removal", LogLevels.Internal)
            for cached: String in cache.resources.keys():
                var cache_score = \
                    - (cache.resources[cached].times_used * 0.5) + \
                    ((Time.get_ticks_msec() - cache.resources[cached].last_used) * 0.3) + \
                    ((Time.get_ticks_msec() - cache.resources[cached].cache_timestamp) * 0.2)
                if bad_cache_score < cache_score:
                    bad_cache_score = cache_score
                    bad_cache_alias = cached
                    doLog("SmartCache Removal Prep: Resource \"{0}\" at risk of being removed with score \"{1}\"".format([str(cached), str(bad_cache_score)]), LogLevels.Internal)
                    pass
            doLog("SmartCache Removal: Resource \"{0}\" being removed with score \"{1}\"".format([str(bad_cache_alias), str(bad_cache_score)]), LogLevels.Internal)
            cache.resources.erase(bad_cache_alias)
        cache.resources[alias] = {
            "object": resourceObject,
            "times_used": 1,
            "last_used": Time.get_ticks_msec(),
            "cache_timestamp": Time.get_ticks_msec(),
        }
        return true
    if is_audio:
        var audioObject: AudioStream = object; object = null # Transfer variables. This serves no actual purpose but to assist with code suggestions because I don't like reading ;.;
        if audioObject.get_length() >= 90: doLog("Did not cache audio object path \"{0}\", length was {1} which is over 90 seconds.".format([audioObject.resource_path, str(audioObject.get_length())]), LogLevels.Log); return false;
        if len(cache.audio) >= projectConfig.cacheLimit:
            doLog("Audio Cache full, doing smart cache removal", LogLevels.Internal)
            for audioCache: String in cache.audio.keys():
                var cache_score = \
                    - (cache.audio[audioCache].times_used * 0.5) + \
                    ((Time.get_ticks_msec() - cache.audio[audioCache].last_used) * 0.3) + \
                    ((Time.get_ticks_msec() - cache.audio[audioCache].cache_timestamp) * 0.2)
                if bad_cache_score < cache_score:
                    bad_cache_score = cache_score
                    bad_cache_alias = audioCache
                    doLog("SmartCache Removal Prep: Audio \"{0}\" at risk of being removed with score \"{1}\"".format([str(audioCache), str(bad_cache_score)]), LogLevels.Internal)
                    pass
            doLog("SmartCache Removal: Audio \"{0}\" being removed with score \"{1}\"".format([str(bad_cache_alias), str(bad_cache_score)]), LogLevels.Internal)
            cache.audio.erase(bad_cache_alias)
        cache.audio[alias] = {
            "object": audioObject,
            "times_used": 1,
            "last_used": Time.get_ticks_msec(),
            "cache_timestamp": Time.get_ticks_msec(),
        }
        return true
    if is_room:
        var roomObject: PackedScene = object; object = null # Transfer variables. This serves no actual purpose but to assist with code suggestions because I don't like reading ;.;
        if len(cache.rooms) >= projectConfig.cacheLimit:
            doLog("Rooms Cache full, doing smart cache removal", LogLevels.Internal)
            for cached: String in cache.rooms.keys():
                var cache_score = \
                    - (cache.rooms[cached].times_used * 0.5) + \
                    ((Time.get_ticks_msec() - cache.rooms[cached].last_used) * 0.3) + \
                    ((Time.get_ticks_msec() - cache.rooms[cached].cache_timestamp) * 0.2)
                if bad_cache_score < cache_score:
                    bad_cache_score = cache_score
                    bad_cache_alias = cached
                    doLog("SmartCache Removal Prep: Room \"{0}\" at risk of being removed with score \"{1}\"".format([str(cached), str(bad_cache_score)]), LogLevels.Internal)
                    pass
            doLog("SmartCache Removal: Room \"{0}\" being removed with score \"{1}\"".format([str(bad_cache_alias), str(bad_cache_score)]), LogLevels.Internal)
            cache.rooms.erase(bad_cache_alias)
        cache.rooms[alias] = {
            "object": roomObject,
            "times_used": 1,
            "last_used": Time.get_ticks_msec(),
            "cache_timestamp": Time.get_ticks_msec(),
        }
        return true
    # If none of the previous checks worked: then store it in Object cache
    if len(cache.objects) >= projectConfig.cacheLimit:
        doLog("Objects Cache full, doing smart cache removal", LogLevels.Internal)
        for cached: String in cache.objects.keys():
            var cache_score = \
                (-(cache.objects[cached].times_used * 0.5) + \
                ((Time.get_ticks_msec() - cache.objects[cached].last_used) * 0.3) + \
                ((Time.get_ticks_msec() - cache.objects[cached].cache_timestamp) * 0.2)) / 2
            if bad_cache_score < cache_score:
                bad_cache_score = cache_score
                bad_cache_alias = cached
                doLog("SmartCache Removal Prep: Object \"{0}\" at risk of being removed with score \"{1}\"".format([str(cached), str(bad_cache_score)]), LogLevels.Internal)
                pass
        doLog("SmartCache Removal: Object \"{0}\" being removed with score \"{1}\"".format([str(bad_cache_alias), str(bad_cache_score)]), LogLevels.Internal)
        cache.objects.erase(bad_cache_alias)
    cache.objects[alias] = {
        "object": object,
        "times_used": 1,
        "last_used": Time.get_ticks_msec(),
        "cache_timestamp": Time.get_ticks_msec(),
    }
    return true
    
func getRandomTilePosOnTilemap(tileAtlasCoords: Vector2i):
    var tilemap: TileMap = get_tree().current_scene.get_node_or_null("%tileMap")
    var authorizedTiles = []
    var nonAuthorizedTiles = []
    if !tilemap: doLog("Could not getRandomTilePosOnTilemap(), no tilemap found. Is it set to a unique name?", LogLevels.Warn); return ;
    for coord in tilemap.get_used_cells(0):
        if !(tilemap.get_cell_atlas_coords(0, coord) == tileAtlasCoords): nonAuthorizedTiles.append(coord); continue ;
        else: authorizedTiles.append(coord);
    for coord in nonAuthorizedTiles: if coord in authorizedTiles:
        authorizedTiles.erase(coord)
    
    if authorizedTiles.is_empty(): return ;

    return tilemap.to_global(tilemap.map_to_local(authorizedTiles.pick_random()))
