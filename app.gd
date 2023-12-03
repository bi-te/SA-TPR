extends Node

var n_class: int;
var attributes: int;
var realizations: int;
var AVG: PackedInt32Array;
var NDK: PackedInt32Array;
var VDK: PackedInt32Array;
var EV: Array[PackedInt32Array];
var ROPT: Array[int];

func open_file_dialog(fcall: Callable) -> void:
	var fileDialog = FileDialog.new();
	fileDialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE;
	fileDialog.access = FileDialog.ACCESS_FILESYSTEM;
	fileDialog.file_selected.connect(fcall);
	get_viewport().add_child(fileDialog);
	fileDialog.popup(Rect2i(400, 300, 500, 300));

func distance(vec1: PackedInt32Array, vec2: PackedInt32Array) -> int:
	assert(vec1.size() == vec2.size())
	var d: int = 0;
	for i in vec1.size():
		d += abs(vec1[i] - vec2[i]);
	return d;
