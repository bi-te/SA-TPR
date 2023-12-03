extends Node
class_name ExamineScene

const result_label = "Зображення належить класу %d";

var EM: Array[PackedInt32Array];
var BM: Array[PackedInt32Array];
var U: Array[float];
var width: int;
var height: int;

func _ready() -> void:
	width = App.attributes
	height = App.realizations;
	
	EM.resize(width);
	BM.resize(width);
	U.resize(App.n_class);
	
	for a in width:
		EM[a].resize(height);
		BM[a].resize(height);

func calculate_educational_matrix(image: Image) -> void:
	for y in height:
		for x in width:
			var pixel := image.get_pixel(x, y);
			EM[y][x] = round((0.2989 * pixel.r8 + 0.5870 * pixel.g8 + 0.1140 * pixel.b8));

func calc_binary_matrix() -> void:
	for y in height:
		for x in width:
			if App.NDK[x] <= EM[y][x] && EM[y][x] <= App.VDK[x]:
				BM[y][x] = 1;
			else:
				BM[y][x] = 0;

func examine() -> void:
	var d: int;
	for c in App.n_class:
		for j in App.realizations:
			d = App.distance(BM[j], App.EV[c]);
			U[c] += 1 - float(d) / App.ROPT[c]
		U[c] /= App.realizations;

func render() -> void:
	#render binary matrix as image
	var image_data := PackedByteArray();
	image_data.resize(width * height);
	for x in width:
		for y in height:
			image_data[x + y * width] = 255 if BM[y][x] else 0;
	
	var bin_image = Image.create_from_data(width, height, false, Image.FORMAT_L8, image_data);
	$Container/BImagePanel/Image.texture = ImageTexture.create_from_image(bin_image);
	
	#render result
	var u_max: float = U[0];
	var res: int = 0;
	for child in $Container/Results.get_children():
		child.queue_free();
	for c in App.n_class:
		var u_label: Label = Label.new();
		u_label.text = "Функція належності[%d] = %.4f"%[c, U[c]];
		$Container/Results.add_child(u_label);
		if u_max < U[c]:
			res = c;
			u_max = U[c];
	$Container/ResultLabel.text = result_label%res;

func _on_load_image_pressed() -> void:
	App.open_file_dialog(_on_image_selected);

func _on_image_selected(path: String) -> void:
	var image: Image = Image.load_from_file(path);
	$Container/ImagePanel/Image.texture = ImageTexture.create_from_image(image);
	calculate_educational_matrix(image);
	calc_binary_matrix();
	examine();
	render();

