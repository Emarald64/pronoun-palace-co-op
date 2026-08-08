@tool
extends EditorScript

const IGNORED_FILES = [
	"mod.json", 
	".authoring", 
	".ignore"
]

const IGNORED_EXTENSIONS = [
	"pck", 
	"zip"
]

var mod_id: String = "co-op"
var pack_name: = "co-op"
var pack_zip: = false


func _run() -> void :
	var pack: = PackMeta.new()

	var mod_folder: = "res://mods/%s/" % mod_id
	for file in FileUtil.get_file_paths_recursive(mod_folder):
		var file_name: = file.get_file()
		if file_name not in IGNORED_FILES and file_name.get_extension() not in IGNORED_EXTENSIONS:
			pack.pack_file(file)

	if pack_zip:
		pack.pack_zip("res://mods/%s/%s.zip" % [mod_id, pack_name])
	else:
		pack.pack_pck("res://mods/%s/%s.pck" % [mod_id, pack_name])


class PackMeta extends RefCounted:
	var packed_files: Array[String] = []
	var packed_resource_uids: Array[int] = []
	var packed_resource_files: Array[String] = []

	var global_classes: Array[Dictionary] = []


	func pack_file(file: String) -> void :
		if ResourceLoader.exists(file):
			var uid: = ResourceLoader.get_resource_uid(file)
			packed_resource_files.append(file)
			packed_resource_uids.append(uid)

			var import_path: = file + ".import"
			if FileAccess.file_exists(import_path):
				packed_files.append(import_path)

				var config: = ConfigFile.new()
				config.load(import_path)
				var remapped_path: Variant = config.get_value("remap", "path", "")

				if remapped_path is String and remapped_path != "":
					packed_files.append(remapped_path)
			else:
				packed_files.append(file)

			if ResourceLoader.exists(file, "Script"):
				for global_class in ProjectSettings.get_global_class_list():
					if global_class.path == file:
						global_classes.append(global_class)
		else:
			packed_files.append(file)


	func get_global_classes_buffer() -> PackedByteArray:
		var config: = ConfigFile.new()
		config.set_value("", "list", global_classes)
		return config.encode_to_text().to_utf8_buffer()


	func get_uid_cache() -> PackedByteArray:
		var buffer: = StreamPeerBuffer.new()

		buffer.put_u32(packed_resource_uids.size())
		for i in packed_resource_uids.size():
			buffer.put_64(packed_resource_uids[i])
			buffer.put_32(len(packed_resource_files[i]))
			buffer.put_data(packed_resource_files[i].to_utf8_buffer())

		return buffer.data_array


	func write_zip_file(packer: ZIPPacker, file: String, bytes: PackedByteArray) -> void :
		packer.start_file(file)
		packer.write_file(bytes)
		packer.close_file()


	func pack_zip(path: String) -> void :
		var packer: = ZIPPacker.new()
		packer.open(path)

		for file in packed_files:
			write_zip_file(packer, file, FileAccess.get_file_as_bytes(file))

		if not global_classes.is_empty():
			write_zip_file(packer, "res://.godot/global_script_class_cache.cfg", get_global_classes_buffer())

		if not packed_resource_uids.is_empty():
			write_zip_file(packer, "res://.godot/uid_cache.bin", get_uid_cache())


	func pack_pck(path: String) -> void :
		var packer: = PCKPacker.new()
		packer.pck_start(path)

		for file in packed_files:
			packer.add_file(file, file)

		if not global_classes.is_empty():
			packer.add_file_from_buffer("res://.godot/global_script_class_cache.cfg", get_global_classes_buffer())

		if not packed_resource_uids.is_empty():
			packer.add_file_from_buffer("res://.godot/uid_cache.bin", get_uid_cache())

		packer.flush()
