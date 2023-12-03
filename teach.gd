extends CanvasLayer
class_name TeachScene


@onready var containers: Array[Node] = [
	$ScrollContainer/MarginContainer/VBoxContainer/HBoxContainer/Container1,
	$ScrollContainer/MarginContainer/VBoxContainer/HBoxContainer/Container2
];
@onready var grid: Array[Node] = $ScrollContainer/MarginContainer/VBoxContainer/GridContainer.get_children();

const ropt_label: String = "Оптимальний радіус для %d-го класу = %d";
const delta_label: String = "Delta = %d";
const row_scene: PackedScene = preload("res://table_row.tscn")

@export var delta: int = 50;

var EM: Array[PackedInt32Array];
var BM: Array[PackedByteArray];
var SK: Array[PackedInt32Array];
var DK: Array[PackedInt32Array];
var D1: Array[PackedFloat32Array];
var D2: Array[PackedFloat32Array];
var Alpha: Array[PackedFloat32Array];
var Beta: Array[PackedFloat32Array];
var KFE: Array[PackedFloat32Array];
var width: int = 100;
var height: int = 100;
var n_class: int = 2;

func _ready() -> void:
	App.n_class = n_class;
	App.attributes = width;
	App.realizations = height;
	App.AVG.resize(width);
	App.NDK.resize(width);
	App.VDK.resize(width);
	App.EV.resize(n_class);
	App.ROPT.resize(n_class);
	
	EM.resize(n_class);
	BM.resize(n_class);
	SK.resize(n_class * 2);
	DK.resize(n_class);
	D1.resize(n_class);
	D2.resize(n_class);
	Alpha.resize(n_class);
	Beta.resize(n_class);
	KFE.resize(n_class);
	
	for c in n_class:
		App.EV[c].resize(width);
		EM[c].resize(width * height);
		BM[c].resize(width * height);
		SK[c * 2].resize(height);
		SK[c * 2 + 1].resize(height);
		DK[c].resize(n_class);
		D1[c].resize(height);
		D2[c].resize(height);
		Alpha[c].resize(height);
		Beta[c].resize(height);
		KFE[c].resize(height);

func _on_load_image_1_pressed() -> void:
	App.open_file_dialog(_on_image1_selected);

func _on_load_image_2_pressed() -> void:
	App.open_file_dialog(_on_image2_selected);

func calculate_educational_matrix(em_ind: int, image: Image) -> void:
	for y in height:
		for x in width:
			var pixel := image.get_pixel(x, y);
			EM[em_ind][x + y * width] = round((0.2989 * pixel.r8 + 0.5870 * pixel.g8 + 0.1140 * pixel.b8));

func calc_avg(em_ind: int) -> void:
	var sum: float;
	for x in width:
		sum = 0;
		for y in height:
			sum += EM[em_ind][x + y * width];
		App.AVG[x] = round(sum / width);

func calc_vdk_ndk() -> void:
	for x in width:
		App.NDK[x] = App.AVG[x] - delta;
		App.VDK[x] = App.AVG[x] + delta;

func calc_binary_matrix(ind: int) -> void:
	for x in width:
		for y in height:
			if App.NDK[x] <= EM[ind][x + y * width] && EM[ind][x + y * width] <= App.VDK[x]:
				BM[ind][x + y * width] = 1;
			else:
				BM[ind][x + y * width] = 0;

func calc_etalon_vector(ind: int) -> void:
	var sum: float;
	for x in width:
		sum = 0;
		for y in height:
			sum += BM[ind][x + y * width];
		App.EV[ind][x] = 1 if sum / 100 > 0.5 else 0;

func calc_dk(ind: int) -> void:
	var d: int;
	for c in n_class:
		if c != ind:
			d = App.distance(App.EV[ind], App.EV[c]);
		else:
			d = -1;
		DK[ind][c] = d;

func calc_sk(ind: int, neigh: int) -> void:
	for y in height:
		var d0: int = 0;
		var d1: int = 0;
		for x in width:
			d0 += abs(App.EV[ind][x] - BM[ind][x + y * width]);
			d1 += abs(App.EV[ind][x] - BM[neigh][x + y * width]);
		SK[ind * 2][y] = d0;
		SK[ind * 2 + 1][y] = d1;

func calc_characteristics(ind: int) -> int:
	var k0: int;
	var k1: int;
	for y in height:
		k0 = 0;
		k1 = 0;
		for x in width:
			if SK[ind * 2][x] <= y:
				k0 += 1;
			if SK[ind * 2 + 1][x] <= y:
				k1 += 1;
		D1[ind][y] = float(k0) / height;
		D2[ind][y] = float(height - k1) / height;
		Alpha[ind][y] = float(height - k0) / height;
		Beta[ind][y] = float(k1) / height;
	
	var y_max: int = 0;
	var kfe_max: float = 0;
	for y in height:
		var a := Alpha[ind][y];
		var b := Beta[ind][y];
		if D1[ind][y] >= 0.5 && D2[ind][y] >= 0.5:
			KFE[ind][y] = (log((2 - a - b) / (a + b)) / log(2)) * (1 - a - b);
		else:
			KFE[ind][y] = 0;
		if KFE[ind][y] > kfe_max:
			y_max = y;
			kfe_max = KFE[ind][y];
	return y_max;

func _on_image1_selected(path: String) -> void:
	var image: Image = Image.load_from_file(path);
	calculate_educational_matrix(0, image);
	containers[0].get_node("ImagePanel/Image").texture = ImageTexture.create_from_image(image);

func _on_image2_selected(path: String) -> void:
	var image: Image = Image.load_from_file(path);
	calculate_educational_matrix(1, image);
	containers[1].get_node("ImagePanel/Image").texture = ImageTexture.create_from_image(image);

func _on_calculate() -> void:	
	calc_avg(0);
	var desired_delta: int;
	var delta_max: int = 80;
	var delta_min: int = 20;
	var radius: int;
	var kfe_max: Dictionary;
	
	var res_dir = DirAccess.open(".");
	if !res_dir.dir_exists("result"):
		res_dir.make_dir("result");
	
	var delta_kfe_file: FileAccess = FileAccess.open("result/delta_kfe.csv", FileAccess.WRITE);
	delta_kfe_file.store_csv_line(PackedStringArray(["delta", "KFE 1", "KFE 2"]));
	
	for delt in range(delta_max, delta_min, -1):
		delta = delt;
		calc_vdk_ndk();
		
		for c in n_class:
			calc_binary_matrix(c);
			calc_etalon_vector(c);
		
		for c in n_class:
			calc_dk(c);
		
		calc_sk(0, 1);
		calc_sk(1, 0);
		
		var kfe_max_arr: Array;
		kfe_max_arr.resize(n_class);
		for c in n_class:
			radius = calc_characteristics(c);
			kfe_max_arr[c] = KFE[c][radius];
		kfe_max[delta] = kfe_max_arr;
		delta_kfe_file.store_csv_line(PackedStringArray([delta, kfe_max_arr[0], kfe_max_arr[1]]));
	
	delta_kfe_file.close();
	
	var max_summ: float = 0;
	for delt in range(delta_max, delta_min, -1):
		var summ: float = 0;
		for c in n_class:
			summ += kfe_max[delt][c];
		if summ > max_summ:
			delta = delt;
			max_summ = summ;
	
	calc_vdk_ndk();
	
	for c in n_class:
		calc_binary_matrix(c);
		calc_etalon_vector(c);
	
	for c in n_class:
		calc_dk(c);
	
	calc_sk(0, 1);
	calc_sk(1, 0);
	
	for c in n_class:
		App.ROPT[c] = calc_characteristics(c);
	
	render();

func render() -> void:
	$ScrollContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/DeltaLabel.text = delta_label%[delta];
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
			strrow += "%-4d" %[App.EV[c][x]];
		containers[c].get_node("EV").insert_line_at(0, strrow);
		
		#render ev to user
		image_data.resize(width * 10);
		for x in width:
			var val: int = 255 if App.EV[c][x] else 0
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
		
		#render&write Characteristics table
		var kfe_file: FileAccess = FileAccess.open("result/kfe%d.csv"%[c+1], FileAccess.WRITE);
		kfe_file.store_csv_line(PackedStringArray(["r", "KFE"]));
		var table: VBoxContainer = get_node("ScrollContainer/MarginContainer/VBoxContainer/Table%d/VBoxContainer"%[c]);
		for y in height:
			var row = row_scene.instantiate();
			var kfe: float = KFE[c][y];
			table.add_child(row);
			row.cells[0].text = str(y);
			row.cells[1].text = "%.2f" % [ D1[c][y] ];
			row.cells[2].text = "%.2f" % [ D2[c][y] ];
			row.cells[3].text = "%.2f" % [ Alpha[c][y] ];
			row.cells[4].text = "%.2f" % [ Beta[c][y] ];
			row.cells[5].text = "%.2f" % [ kfe ];
			if kfe > 0:
				row.set_modulate(Color.RED);
			kfe_file.store_csv_line(PackedStringArray([str(y), "%.2f" % [ kfe ]])
			);
		
		kfe_file.close();
		#render optimal redius
		get_node("ScrollContainer/MarginContainer/VBoxContainer/ROPT%d"%c).text = ropt_label%[c + 1, App.ROPT[c]];
	
	#print ndk & vdk to user
	strrow = "";
	strrow2 = "";
	for x in width:
		strrow += "%-4d" %[App.NDK[x]];
		strrow2 += "%-4d" %[App.VDK[x]];
	containers[0].get_node("NDK").insert_line_at(0, strrow);
	containers[1].get_node("VDK").insert_line_at(0, strrow2);




func _on_back_button_pressed() -> void:
	pass # Replace with function body.
