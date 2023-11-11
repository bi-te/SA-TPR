extends Node

var EM: Array[PackedInt32Array];
var BM: Array[PackedByteArray];
var NDK: PackedInt32Array;
var VDK: PackedInt32Array;
var EV: Array[PackedInt32Array];
var width: int = 100;
var height: int = 100;
var n_class: int = 2;
@export var delta: int = 25;

func _ready() -> void:
	EM.resize(n_class);
	BM.resize(n_class);
	EV.resize(n_class);
	NDK.resize(width);
	VDK.resize(width);
	
	for k in n_class:
		EM[k].resize(width * height);
		BM[k].resize(width * height);
		EV[k].resize(width);


func open_file_dialog(fcall: Callable) -> void:
	var fileDialog = FileDialog.new();
	fileDialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE;
	fileDialog.access = FileDialog.ACCESS_FILESYSTEM;
	get_viewport().add_child(fileDialog);
	fileDialog.file_selected.connect(fcall);
	fileDialog.popup(Rect2i(400, 300, 500, 300));

func _on_load_image_1_pressed() -> void:	
	open_file_dialog(_on_image1_selected);

func _on_load_image_2_pressed() -> void:
	open_file_dialog(_on_image2_selected);

func calculate_educational_matrix(Y: PackedInt32Array, image: Image) -> void:
	for y in height:
		for x in width:
			var pixel := image.get_pixel(x, y);
			Y[x + y * width] = round((0.2989 * pixel.r8 + 0.5870 * pixel.g8 + 0.1140 * pixel.b8));

func calc_vdk_ndk(Y: PackedInt32Array, N: PackedInt32Array, V:PackedInt32Array) -> void:
	var sum: float;
	for x in width:
		sum = 0;
		for y in height:
			sum += Y[x + y * width];
		N[x] = round(sum / width) - delta;
		V[x] = round(sum / width) + delta;

func calc_binary_matrix(Y: PackedInt32Array, N: PackedInt32Array, V:PackedInt32Array, 
						B: PackedByteArray) -> void:
	for x in width:
		for y in height:
			if N[x] <= Y[x + y * width] && Y[x + y * width] <= V[x]:
				B[x + y * width] = 1;
			else:
				B[x + y * width] = 0;

func calc_etalon_vector(B: PackedByteArray, E: PackedInt32Array) -> void:
	var sum: float;
	for x in width:
		sum = 0;
		for y in height:
			sum += B[x + y * width];
		E[x] = 1 if sum / 100 > 0.5 else 0;

func _on_image1_selected(path: String) -> void:
	var image: Image = Image.load_from_file(path);
	calculate_educational_matrix(EM[0], image);
	$Container1/ImagePanel/Image.texture = ImageTexture.create_from_image(image);

func _on_image2_selected(path: String) -> void:
	var image: Image = Image.load_from_file(path);
	calculate_educational_matrix(EM[1], image);
	$Container2/ImagePanel/Image.texture = ImageTexture.create_from_image(image);

func _on_calculate() -> void:
	calc_vdk_ndk(EM[0], NDK, VDK);
	
	for c in n_class:
		calc_binary_matrix(EM[c], NDK, VDK, BM[c]);
	
	render();

func render() -> void:
	var ed_row: String;
	var bin_row: String;
	var ndk_row: String;
	var vdk_row: String;
	for c in n_class:
		# print educational and binary matrix to user
		for y in height:
			ed_row = "";
			bin_row = "";
			for x in width:
				ed_row += "%-4d" %[EM[c][x + y * width]];
				bin_row += "%-3d" %[BM[c][x + y * width]];
			get_node("Container%d/EMatrix"%[c + 1]).insert_line_at(y, ed_row);
			get_node("Container%d/BMatrix"%[c + 1]).insert_line_at(y, bin_row);		
		
		#render binary matrix as image
		var image_data := PackedByteArray();
		image_data.resize(width * height);
		for x in width:
			for y in height:
				image_data[x + y * width] = 255 if BM[c][x + y * width] else 0;
		
		var bin_image = Image.create_from_data(width, height, false, Image.FORMAT_L8, image_data);
		get_node("Container%d/BImagePanel/Image"%[c + 1]).texture = ImageTexture.create_from_image(bin_image);
	
	#print ndk & vdk to user
	ndk_row = "";
	vdk_row = "";
	for x in width:
		ndk_row += "%-4d" %[NDK[x]];
		vdk_row += "%-4d" %[VDK[x]];
	get_node("Container1/NDK").insert_line_at(0, ndk_row);
	get_node("Container2/VDK").insert_line_at(0, vdk_row);
	
