@tool
extends EditorScript

var mod_id="co-op"
var zip_pack:=false

var additional_files: PackedStringArray = [
	"res://strings/intent/echo.txt",
	"res://strings/intent/echo_cursed.txt",
	"res://strings/intent/phone_a_friend_recive.txt",
	"res://strings/intent/phone_a_friend_recive_cursed.txt",
	"res://strings/intent/phone_a_friend_send.txt",
	"res://strings/intent/phone_a_friend_send_cursed.txt",
	"res://strings/spell/party_telephone.txt",
	"res://source/spells/party_telephone.gd",
	"res://arte/spells/party_telephone.png",
	"res://.godot/uid_cache.bin", # saves uids so you dont get warning for every file you load
	"res://.godot/global_script_class_cache.cfg", # saves global classes
]

var excluded:PackedStringArray=[
	"res://mods/"+mod_id+"/mod_packer.gd"
]

func _run() -> void :
	var packer
	if zip_pack:
		packer=ZIPPacker.new()
		packer.open("res://mod_packs/"+mod_id+"/"+mod_id+".zip")
	else:
		packer = PCKPacker.new()
		packer.pck_start("res://mod_packs/"+mod_id+"/"+mod_id+".pck")
	# automaticcly includes files in your mod's folder
	var mod_files=FileUtil.get_file_paths_recursive("res://mods/"+mod_id)
	#var global_scripts:Array[Dictionary]=[]
	for file in mod_files+additional_files:
		if file not in excluded and not file.ends_with(".uid"): 
			if ResourceLoader.exists(file):
				var loaded: Resource = ResourceLoader.load(file)
				if loaded is CompressedTexture2D:
					if zip_pack:
						add_file_to_zip(packer,loaded.load_path)
						add_file_to_zip(packer,file + ".import")
					else:
						packer.add_file(loaded.load_path, loaded.load_path)
						packer.add_file(file + ".import", file + ".import")
				elif loaded is AudioStream:
					var config:=ConfigFile.new()
					config.load(file + ".import")
					var imported_path=config.get_value("remap","path")
					if zip_pack:
						add_file_to_zip(packer,file + ".import")
						add_file_to_zip(packer,imported_path)
					else:
						packer.add_file(file + ".import", file + ".import")
						packer.add_file(imported_path, imported_path)
				#elif loaded is GDScript:
					#var name=loaded.get_global_name()
					#if not name.is_empty():
						#global_scripts.append({
							#"class":StringName(name),
							#"base":loaded.get_instance_base_type(),
							#"language":&"GDScript",
							#"path":file,
							#"is_abstact":loaded.is_abstract(),
							#"is_tool":loaded.is_tool()
						#})
					#packer.add_file(file, file)
				else:
					if zip_pack:
						add_file_to_zip(packer,file)
					else:
						packer.add_file(file, file)
			else:
				if zip_pack:
					add_file_to_zip(packer,file)
				else:
					packer.add_file(file, file)
	
	if zip_pack:
		packer.close()
	else:
		packer.flush()

static func add_file_to_zip(packer:ZIPPacker,path:String):
	packer.start_file(path)
	packer.write_file(FileAccess.get_file_as_bytes(path))
	packer.close_file()
