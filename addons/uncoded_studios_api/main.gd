@tool
extends EditorPlugin

const autoload_name := "usapi"

func _enter_tree():
    print("Init usapi plugin")
    add_autoload_singleton(autoload_name, "res://addons/uncoded_studios_api/scripts/autoload.tscn")
    if !ProjectSettings.has_setting("USAPI/Misc/UseDefaultSettingsMenu"): createDefaultSettings()
    pass

func createDefaultSettings():
    print("Default Project Settings set up! Check GODOT project settings for USAPI config.")

    ProjectSettings.set_setting("USAPI/Caching/DoCaching", true)
    ProjectSettings.set_setting("USAPI/Caching/CacheObjects", true)
    ProjectSettings.set_setting("USAPI/Caching/CacheResources", true)
    ProjectSettings.set_setting("USAPI/Caching/CacheRooms", true)
    ProjectSettings.set_setting("USAPI/Caching/CacheAudio", false)
    ProjectSettings.set_setting("USAPI/Caching/CacheLimit", 50)
    ProjectSettings.set_setting("USAPI/Caching/CacheObjectsOnStart", true)
    ProjectSettings.set_setting("USAPI/Caching/CacheResourcesOnStart", true)
    ProjectSettings.set_setting("USAPI/Caching/CacheRoomsOnStart", true)
    ProjectSettings.set_setting("USAPI/Caching/CacheAudioOnStart", false)
    
    ProjectSettings.set_setting("USAPI/Paths/ObjectsPath", "res://objects")
    ProjectSettings.set_setting("USAPI/Paths/ResourcesPath", "res://resources")
    ProjectSettings.set_setting("USAPI/Paths/AudioPath", "res://audio")
    ProjectSettings.set_setting("USAPI/Paths/ScriptsPath", "res://scripts")
    ProjectSettings.set_setting("USAPI/Paths/AssetsPath", "res://assets")
    ProjectSettings.set_setting("USAPI/Paths/RoomsPath", "res://rooms")
    ProjectSettings.set_setting("USAPI/Paths/SaveFilePath", "user://saves")
    ProjectSettings.set_setting("USAPI/Paths/ModPackPath", "user://mods")
    
    if !DirAccess.dir_exists_absolute("res://objects"):DirAccess.make_dir_absolute("res://objects")
    if !DirAccess.dir_exists_absolute("res://resources"):DirAccess.make_dir_absolute("res://resources")
    if !DirAccess.dir_exists_absolute("res://audio"):DirAccess.make_dir_absolute("res://audio")
    if !DirAccess.dir_exists_absolute("res://scripts"):DirAccess.make_dir_absolute("res://scripts")
    if !DirAccess.dir_exists_absolute("res://assets"):DirAccess.make_dir_absolute("res://assets")
    if !DirAccess.dir_exists_absolute("res://rooms"):DirAccess.make_dir_absolute("res://rooms")

    ProjectSettings.set_setting("USAPI/Console/ConsoleEnabled", true)
    ProjectSettings.set_setting("USAPI/Console/AllowCustomConsoleCommands", false)
    
    ProjectSettings.set_setting("USAPI/Misc/UseDefaultSettingsMenu", true)

func _exit_tree():
    print("Removed usapi plugin")
    remove_autoload_singleton(autoload_name)
    pass
