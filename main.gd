extends Node

var Y1: PackedInt32Array;
var Y2: PackedInt32Array;
var width: int = 100;
var height: int = 100;

func _ready() -> void:
	Y1 = PackedInt32Array();
	Y1.resize(width * height);
	
	Y2 = PackedInt32Array();
	Y2.resize(width * height);

func open_file_dialog(call: Callable) -> void:
	var fileDialog = FileDialog.new();
	fileDialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE;
	fileDialog.access = FileDialog.ACCESS_FILESYSTEM;
	get_viewport().add_child(fileDialog);
	fileDialog.file_selected.connect(call);
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

func write_educational_matrix(Y: PackedInt32Array, output: TextEdit) -> void:
	var row: String;	
	for y in height:
		row = "";
		for x in width:
			var a = "%-4d" %[Y[x + y * width]];
			row += a;
		output.insert_line_at(y, row);

func _on_image1_selected(path: String) -> void:
	var image: Image = Image.load_from_file(path);
	calculate_educational_matrix(Y1, image);
	write_educational_matrix(Y1, $Container1/EMatrix);
	$Container1/ImagePanel/Image.texture = ImageTexture.create_from_image(image);

func _on_image2_selected(path: String) -> void:
	var image: Image = Image.load_from_file(path);
	calculate_educational_matrix(Y2, image);
	write_educational_matrix(Y2, $Container2/EMatrix);
	$Container2/ImagePanel/Image.texture = ImageTexture.create_from_image(image);




