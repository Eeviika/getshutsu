extends Node

func _init():
	print("USAPI-MODLOADER: Ready!")

func transferMods():
	print("USAPI-MODLOADER: Transferring mods from user://mods to working directory (res://)...")
	if !DirAccess.dir_exists_absolute("user://mods"): printerr("USAPI-MODLOADER: Could not transfer mods! No user://mods directory exists."); return {"success": GlobalEnums.Success.NO, "error": "No user://mods directory created"};
	if len(DirAccess.get_directories_at("user://mods")) == 0: printerr("USAPI-MODLOADER: Could not transfer mods! Mods directory is empty."); return {"success": GlobalEnums.Success.NO, "error": "Mods directory empty"};
	print("USAPI-MODLOADER: " + str(len(DirAccess.get_directories_at("user://mods"))) + " mod(s) detected.") 
	for modDirectory in DirAccess.get_directories_at("user://mods"):
		var contents := DirAccess.get_files_at("user://mods/" + modDirectory)
		if contents.is_empty(): printerr("USAPI-MODLOADER: Error when transferring mod user://mods/" + modDirectory + ", no contents!"); continue;
		if !("pack.json" in contents): printerr("USAPI-MODLOADER: Error when transferring mod user://mods/" + modDirectory + ", no pack.json!"); continue;
		var packFile := FileAccess.open("user://mods/"+ modDirectory + "/pack.json", FileAccess.READ)
		var packData: Dictionary = JSON.parse_string(packFile.get_as_text())
		packFile.close()
		if !(packData.has("title") and packData.has("author") and packData.has("version") and packData.has("description")): printerr("USAPI-MODLOADER: Error when transferring mod user://mods/" + modDirectory + ", pack.json missing elements or is invalid!"); continue;
		print('USAPI-MODLOADER: Transferring mod "{0}", version "{1}" by "{2}", to res://'.format([packData.title, packData.version, packData.author]))
		contents = DirAccess.get_directories_at("user://mods/" + modDirectory)
		for directory in contents: # Entirety of transferring mod files to res://.
			if !(directory in ["scripts", "assets", "objects", "resources", "audio", "rooms"]): continue;
			print("USAPI-MODLOADER: Transferring " + directory + " (" + packData.title + ") directory.")
			if directory == "scripts":
				for file in DirAccess.get_files_at("user://mods/"+modDirectory+"/"+directory):
					if !file.ends_with(".gd"): continue;
					var originalfile = FileAccess.open("user://mods/"+modDirectory+"/"+directory+"/"+file, FileAccess.READ)
					var newfile = FileAccess.open("res://scripts/"+file, FileAccess.WRITE)
					newfile.store_string(originalfile.get_as_text())
					newfile.close()
			elif directory == "objects" or directory == "rooms" or directory == "resources":
				for file in DirAccess.get_files_at("user://mods/"+modDirectory+"/"+directory):
					if !file.ends_with(".tscn"): continue;
					var originalfile = FileAccess.open("user://mods/"+modDirectory+"/"+directory+"/"+file, FileAccess.READ)
					var newfile = FileAccess.open("res://"+directory+"/"+file, FileAccess.WRITE)
					newfile.store_string(originalfile.get_as_text())
					newfile.close()
			elif directory == "audio":
				for file in DirAccess.get_files_at("user://mods/"+modDirectory+"/"+directory):
					if !(file.ends_with(".mp3") or file.ends_with(".wav") or file.ends_with(".ogg")): continue;
					var originalfile = FileAccess.open("user://mods/"+modDirectory+"/"+directory+"/"+file, FileAccess.READ)
					var newfile = FileAccess.open("res://audio/"+file, FileAccess.WRITE)
					newfile.store_string(originalfile.get_as_text())
					newfile.close()
			else:
				for file in DirAccess.get_files_at("user://mods/"+modDirectory+"/"+directory):
					var originalfile = FileAccess.open("user://mods/"+modDirectory+"/"+directory+"/"+file, FileAccess.READ)
					var newfile = FileAccess.open("res://assets/"+file, FileAccess.WRITE)
					newfile.store_string(originalfile.get_as_text())
					newfile.close()
			

	return {"success": GlobalEnums.Success.YES};
