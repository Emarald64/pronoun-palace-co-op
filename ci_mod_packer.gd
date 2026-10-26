extends Node

var mod_id="co-op"
var make_global_script_cache:=true
var make_uid_cache:=true
var zip_pack:=false

#var additional_files: PackedStringArray = [
	##"res://source/spell/spell_data.gd",
	##"res://strings/menu/settings.txt",
	##"res://strings/credits/mods/framework.txt",
	##"res://source/minigames/tile_fish.tscn",
	##"res://source/spells/red_letter.gd",
	##"res://.godot/uid_cache.bin", # saves uids so you dont get warning for every file you load
	##"res://.godot/global_script_class_cache.cfg" # saves global classes
#]

var packer:Object
var uids:=[]
var global_scripts=[]

var excluded:PackedStringArray=[
	"res://mods/"+mod_id+"/ci_mod_packer.gd",
	"res://mods/co-op/readme.md",
	"res://mods/co-op/todo.txt",
	"res://mods/co-op/mod.json",
	"res://mods/co-op/mod_packer.tscn",
]

var excluded_extentions:PackedStringArray=[
	"import",
	"pxo",
	"authoring",
	"ignore",
	"zip",
	"pck",
	"uid"
]

func pack_folder(path:String):
	for folder in DirAccess.get_directories_at(path):
		pack_folder(path+folder+"/")
	var files=DirAccess.get_files_at(path)
	print(path,files)
	for file in files:
		var full_path=path+file
		if full_path not in excluded and file.rsplit(".",true,1).get(1) not in excluded_extentions: 
			if FileAccess.file_exists(full_path + ".import"):
				var config:=ConfigFile.new()
				config.load(full_path + ".import")
				var imported_path=config.get_value("remap","path")
				if zip_pack:
					add_file_to_zip(full_path + ".import")
					add_file_to_zip(imported_path)
				else:
					packer.add_file(full_path + ".import", full_path + ".import")
					packer.add_file(imported_path, imported_path)
			else:
				pack_file(full_path)

func pack_file(path:String):
	print("packed: ",path)
	if zip_pack:
		add_file_to_zip(path)
	else:
		packer.add_file(path, path)

func _ready() -> void :
	#var packer
	if zip_pack:
		packer=ZIPPacker.new()
		packer.open("res://"+mod_id+".zip")
	else:
		packer = PCKPacker.new()
		packer.pck_start("res://"+mod_id+".pck")
	
	pack_folder("res://mods/%s/"%mod_id)
	
	pack_file("res://.godot/global_script_class_cache.cfg")
	pack_file("res://.godot/uid_cache.bin")
	
	if zip_pack:
		packer.close()
	else:
		packer.flush()

func add_file_to_zip(path:String):
	packer.start_file(path)
	packer.write_file(FileAccess.get_file_as_bytes(path))
	packer.close_file()
