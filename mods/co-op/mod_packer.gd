@tool
extends EditorScript

var mod_id="co-op"
var make_global_script_cache:=true
var make_uid_cache:=true
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
	"res://strings/spell/blue_box.txt",
	"res://source/spells/blue_box.gd",
	"res://source/enemies/bottom_feeder.gd",
	"res://source/enemies/npcs.gd",
	"res://source/spells/fishing_rod.gd",
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
	var global_scripts=[]
	var uids:Array[Array]=[]
	for file in mod_files+additional_files:
		if file not in excluded and not file.ends_with(".uid"): 
			if ResourceLoader.exists(file):
				
				var uid=ResourceLoader.get_resource_uid(file)
				if uid>=0:
					uids.append([uid,file])
				
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
				elif make_global_script_cache and loaded is GDScript:
					var name=loaded.get_global_name()
					if not name.is_empty():
						global_scripts.append({
							"class":StringName(name),
							"base":loaded.get_instance_base_type(),
							"language":&"GDScript",
							"path":file,
							"is_abstract":loaded.is_abstract(),
							"is_tool":loaded.is_tool()
						})
					if zip_pack:
						add_file_to_zip(packer,file)
					else:
						packer.add_file(file, file)
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
	
	if make_global_script_cache:
		var cf=ConfigFile.new()
		cf.set_value("","list",global_scripts)
		var buffer=cf.encode_to_text().to_utf8_buffer()
		if zip_pack:
			packer.start_file("res://.godot/global_script_class_cache.cfg")
			packer.write_file(buffer)
			packer.close_file()
		else:
			packer.add_file_from_buffer("res://.godot/global_script_class_cache.cfg",buffer)
	
	if make_uid_cache:
		var buffer=StreamPeerBuffer.new()
		#buffer.resize(4+(12*uids.size())+uids.reduce(func (accum:int,uid_pair:Array):return accum+uid_pair[1].length(),0))
		buffer.put_u32(uids.size())
		for entry in uids:
			buffer.put_u64(entry[0])
			buffer.put_u32(entry[1].length())
			buffer.put_data(entry[1].to_utf8_buffer())
		
		if zip_pack:
			packer.start_file("res://.godot/uid_cache.bin")
			packer.write_file(buffer.data_array)
			packer.close_file()
		else:
			packer.add_file_from_buffer("res://.godot/uid_cache.bin",buffer.data_array)
		
	
	if zip_pack:
		packer.close()
	else:
		packer.flush()

static func add_file_to_zip(packer:ZIPPacker,path:String):
	packer.start_file(path)
	packer.write_file(FileAccess.get_file_as_bytes(path))
	packer.close_file()
