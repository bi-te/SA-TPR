extends Node

var teach_scene: TeachScene = preload("res://teach.tscn").instantiate();
var examine_scene: ExamineScene = preload("res://examine.tscn").instantiate();

func _ready() -> void:
	add_child(teach_scene);
	teach_scene.get_node("BackButton").pressed.connect(_on_back_button_pressed);
	teach_scene.hide();
	add_child(examine_scene);
	examine_scene.hide();
	examine_scene.get_node("BackButton").pressed.connect(_on_back_button_pressed);

func _on_teach_pressed() -> void:
	$VBoxContainer.hide();
	teach_scene.show();

func _on_examine_pressed() -> void:
	$VBoxContainer.hide();
	examine_scene.show();

func _on_back_button_pressed() -> void:
	teach_scene.hide();
	examine_scene.hide();
	$VBoxContainer.show();
	
