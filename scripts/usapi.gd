extends Node
## USAPI, or Uncoded Studios Application Programming Interface, handles most game logic and objects for Uncoded Studios games.
##
## This script is all the logic and code that USAPI lives off of.
## It is recommended that you do not touch any of this unless you know what you are doing.
##
## Please note that USAPI is experimental game code, and may not work properly in some scenarios.


## Where USAPI will start looking for ProjectSettings. You typically may not want to edit this.
@export var projectSettingsDefaultPath = "uncoded_studios/"

var objectCache = {}
var audioCache = {}
var resourceCache = {}
var roomCache = {}
var projectConfig = {}
var modLoader = null

func _ready():
	customlog("Hello, World!")
	projectConfig = {
		"active": ProjectSettings.get_setting(projectSettingsDefaultPath + "usapi/is_active"),

		"objectsFolder": ProjectSettings.get_setting(projectSettingsDefaultPath + "usapi/objects_folder"),
		"resourcesFolder": ProjectSettings.get_setting(projectSettingsDefaultPath + "usapi/resources_folder"),
		"roomsFolder": ProjectSettings.get_setting(projectSettingsDefaultPath + "usapi/rooms_folder"),
		"audioFolder": ProjectSettings.get_setting(projectSettingsDefaultPath + "usapi/audio_folder"),
		"scriptsFolder": ProjectSettings.get_setting(projectSettingsDefaultPath + "usapi/scripts_folder"),

		"cacheObjectsOnStart": ProjectSettings.get_setting(projectSettingsDefaultPath + "caching/cache_all_objects_on_start"),
		"cacheAudioOnStart": ProjectSettings.get_setting(projectSettingsDefaultPath + "caching/cache_all_audio_on_start"),
		"cacheResourcesOnStart": ProjectSettings.get_setting(projectSettingsDefaultPath + "caching/cache_all_resources_on_start"),
		"cacheRoomsOnStart": ProjectSettings.get_setting(projectSettingsDefaultPath + "caching/cache_all_rooms_on_start"),
		"cacheLimit": ProjectSettings.get_setting(projectSettingsDefaultPath + "caching/cache_limit"),
	}
	projectConfig.make_read_only() # Prevent any additional modifiers. Since we are grabbing from ProjectSettings, no reason to edit this anyway.
	if projectConfig.active == false: print("USAPI has been disabled in project config."); queue_free();

	for i: String in projectConfig: # Check if folder paths are valid.
		if !(i is String and i.ends_with("Folder")): continue;
		assert(projectConfig[i] != null, "ProjectSettings are not configured correctly. Missing \"{0}\".".format([i]))
		assert(DirAccess.dir_exists_absolute(projectConfig[i]), "Directory for \"{0}\" is invalid; Points to \"{1}\"".format([i, projectConfig[i]]))
	
	# Check if ModLoader exists.
	if ResourceLoader.exists(projectConfig.scriptsFolder + "/usapi-modloader.gd"):
		customlog("Detected USAPI ModLoader!")
		modLoader = load(projectConfig.scriptsFolder + "/usapi-modloader.gd")
		var modLoaderNode := Node.new()
		modLoaderNode.name = "modLoader"
		add_child(modLoaderNode)
		modLoaderNode.set_script(modLoader)
		modLoader = modLoaderNode

## Reloads the currently active scene. If hardReload is active, caches will be cleared as well.
func reloadScene(hardReload=false):
	if hardReload:
		clearCaches("object")
		clearCaches("room")
	get_tree().reload_current_scene()

## Summons an object into the current scene and returns it. If the object is not already cached, it will be cached to prevent lag. 
## If `cache` is disabled, the object will never be cached (unless it already is).
func summonObject(object: String, cache = true):
	# Check if object exists via ResourceLoader, because when game is exported, objects will be imported into game and can't be checked.
	if object in objectCache.keys(): # Load the preloaded object instead to prevent major disk usage.
		var newobj = objectCache[object].instantiate()
		get_tree().current_scene.add_child(newobj)
		return newobj
	else: # Load the object from disk and cache it.
		if not ResourceLoader.exists(projectConfig.objectsFolder + "/"+ object +".tscn"): printerr("Cannot summon object \"{0}\", file path \"{1}\" could not be found.".format([object, projectConfig.objectsFolder + "/"+ object +".tscn"])); return null;
		var newobj = load(projectConfig.objectsFolder + "/"+ object +".tscn")
		if cache and (len(objectCache) < projectConfig.cacheLimit and projectConfig.cacheLimit >= 0):
			objectCache[object] = newobj
		elif len(objectCache) >= projectConfig.cacheLimit and projectConfig.cacheLimit >= 0:
			customlog("Cannot cache object \"" + object + "\" because we hit the cache limit!", GlobalEnums.LogLevels.Error)
		newobj = newobj.instantiate()
		get_tree().current_scene.add_child(newobj)
		return newobj

## Get a random tile from the TileMap in the current scene. TileMap must have a unique name (%TileMap).
func getRandomTilePosOnTilemap(tileAtlasCoords: Vector2i):
	var tilemap: TileMap = get_tree().current_scene.get_node_or_null("%tileMap")
	var authorizedTiles = []
	var nonAuthorizedTiles = []
	if !tilemap: customlog("Could not getRandomTilePosOnTilemap(), no tilemap found. Is it set to a unique name?", GlobalEnums.LogLevels.Warn); return;
	for coord in tilemap.get_used_cells(0):
		if !(tilemap.get_cell_atlas_coords(0, coord) == tileAtlasCoords): nonAuthorizedTiles.append(coord); continue;
		else: authorizedTiles.append(coord);
	for coord in nonAuthorizedTiles: if coord in authorizedTiles:
		authorizedTiles.erase(coord)
	
	if authorizedTiles.is_empty(): return;

	return tilemap.to_global(tilemap.map_to_local(authorizedTiles.pick_random()))

## Clears all caches. May free up memory at the cost of lag when loading objects again.
func clearCaches(type=""):
	match type:
		"object":
			objectCache.clear()
		"audio":
			audioCache.clear()
		"resource":
			resourceCache.clear()
		"room":
			roomCache.clear()
		_:
			objectCache.clear()
			audioCache.clear()
			resourceCache.clear()
			roomCache.clear()

# Custom log command.
func customlog(text: String, type=GlobalEnums.LogLevels.Log):
	if type == GlobalEnums.LogLevels.Warn:
		print_rich("[color=yellow]USAPI: " + text + "[/color]")
		push_warning("USAPI: " + text)
		return;
	if type == GlobalEnums.LogLevels.Error:
		printerr("USAPI: " + text)
		push_error("USAPI: " + text)
		return;
	print("USAPI: " + text)