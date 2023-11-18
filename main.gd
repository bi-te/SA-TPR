extends Node

@onready var containers: Array[Node] = [
	$ScrollContainer/MarginContainer/VBoxContainer/HBoxContainer/Container1,
	$ScrollContainer/MarginContainer/VBoxContainer/HBoxContainer/Container2
];
@onready var grid: Array[Node] = $ScrollContainer/MarginContainer/VBoxContainer/GridContainer.get_children();

@export var delta: int = 50;

var EM: Array[PackedInt32Array];
var BM: Array[PackedByteArray];
var NDK: PackedInt32Array;
var VDK: PackedInt32Array;
var EV: Array[PackedInt32Array];
var SK: Array[PackedInt32Array];
var DK: Array[PackedInt32Array];
var width: int = 100;
var height: int = 100;
var n_class: int = 2;

func _ready() -> void:
	EM.resize(n_class);
	BM.resize(n_class);
	EV.resize(n_class);
	NDK.resize(width);
	VDK.resize(width);
	DK.resize(n_class);
	
	for c in n_class:
		EM[c].resize(width * height);
		BM[c].resize(width * height);
		EV[c].resize(width);
		DK[c].resize(n_class);
	
	SK.resize(4);
	for i in 4:
		SK[i].resize(height);

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

func calculate_educational_matrix(em_ind: int, image: Image) -> void:
	for y in height:
		for x in width:
			var pixel := image.get_pixel(x, y);
			EM[em_ind][x + y * width] = round((0.2989 * pixel.r8 + 0.5870 * pixel.g8 + 0.1140 * pixel.b8));

func calc_vdk_ndk(em_ind: int) -> void:
	var sum: float;
	for x in width:
		sum = 0;
		for y in height:
			sum += EM[em_ind][x + y * width];
		NDK[x] = round(sum / width) - delta;
		VDK[x] = round(sum / width) + delta;

func calc_binary_matrix(ind: int) -> void:
	for x in width:
		for y in height:
			if NDK[x] <= EM[ind][x + y * width] && EM[ind][x + y * width] <= VDK[x]:
				BM[ind][x + y * width] = 1;
			else:
				BM[ind][x + y * width] = 0;

func calc_etalon_vector(ind: int) -> void:
	var sum: float;
	for x in width:
		sum = 0;
		for y in height:
			sum += BM[ind][x + y * width];
		EV[ind][x] = 1 if sum / 100 > 0.5 else 0;

func calc_dk(ind: int) -> void:
	var d: int;
	for c in n_class:
		if c != ind:
			d = 0;
			for x in width:
				d += abs(EV[ind][x] - EV[c][x]);
		else:
			d = -1;
		DK[ind][c] = d;

func calc_sk(ind: int, neigh: int) -> void:
	for y in height:
		var d0: int = 0;
		var d1: int = 0;
		for x in width:
			d0 += abs(EV[ind][x] - BM[ind][x + y * width]);
			d1 += abs(EV[ind][x] - BM[neigh][x + y * width]);
		SK[ind * 2][y] = d0;
		SK[ind * 2 + 1][y] = d1;

func _on_image1_selected(path: String) -> void:
	var image: Image = Image.load_from_file(path);
	calculate_educational_matrix(0, image);
	containers[0].get_node("ImagePanel/Image").texture = ImageTexture.create_from_image(image);

func _on_image2_selected(path: String) -> void:
	var image: Image = Image.load_from_file(path);
	calculate_educational_matrix(1, image);
	containers[1].get_node("ImagePanel/Image").texture = ImageTexture.create_from_image(image);

func _on_calculate() -> void:
	calc_vdk_ndk(0);
	
	var sk: Array[PackedInt32Array];
	for c in n_class:
		calc_binary_matrix(c);
		calc_etalon_vector(c);
	
	for c in n_class:
		calc_dk(c);
	
	calc_sk(0, 1);
	calc_sk(1, 0);
	
	render();

func render() -> void:
	var strrow: String;
	var strrow2: String;
	for c in n_class:
		# print educational and binary matrix to user
		for y in height:
			strrow = "";
			strrow2 = "";
			for x in width:
				strrow += "%-4d" %[EM[c][x + y * width]];
				strrow2 += "%-3d" %[BM[c][x + y * width]];
			containers[c].get_node("EMatrix").insert_line_at(y, strrow);
			containers[c].get_node("BMatrix").insert_line_at(y, strrow2);
		
		#render binary matrix as image
		var image_data := PackedByteArray();
		image_data.resize(width * height);
		for x in width:
			for y in height:
				image_data[x + y * width] = 255 if BM[c][x + y * width] else 0;
		
		var bin_image = Image.create_from_data(width, height, false, Image.FORMAT_L8, image_data);
		containers[c].get_node("BImagePanel/Image").texture = ImageTexture.create_from_image(bin_image);
		
		#print ev to user
		strrow = "";
		for x in width:
			strrow += "%-4d" %[EV[c][x]];
		containers[c].get_node("EV").insert_line_at(0, strrow);
		
		#render ev to user
		image_data.resize(width * 10);
		for x in width:
			var val: int = 255 if EV[c][x] else 0
			for y in 10:
				image_data[x + y * width] = val;
		
		bin_image = Image.create_from_data(width, 10, false, Image.FORMAT_L8, image_data);
		containers[c].get_node("EVImagePanel/Image").texture = ImageTexture.create_from_image(bin_image);
		
		#render SK to user
		strrow = "";
		strrow2 = "";
		for y in height:
			strrow += "%-4d" %[SK[c * 2][y]];
			strrow2 += "%-4d" %[SK[c * 2 + 1][y]];
		containers[c].get_node("SK").insert_line_at(0, strrow);
		containers[c].get_node("SK2").insert_line_at(0, strrow2);
		
		#render distance matrix
		var class_tex: Texture2D = containers[c].get_node("ImagePanel/Image").texture;
		grid[c + 1].get_node("Image").texture = class_tex;
		grid[(c + 1) * (n_class + 1)].get_node("Image").texture = class_tex;
		var d: String;
		for dist_class in n_class:
			d = str(DK[c][dist_class]) if dist_class != c else "-";
			grid[(c + 1) * (n_class + 1) + dist_class + 1].get_node("Label").text = d;
		
	
	#print ndk & vdk to user
	strrow = "";
	strrow2 = "";
	for x in width:
		strrow += "%-4d" %[NDK[x]];
		strrow2 += "%-4d" %[VDK[x]];
	containers[0].get_node("NDK").insert_line_at(0, strrow);
	containers[1].get_node("VDK").insert_line_at(0, strrow2);
	

