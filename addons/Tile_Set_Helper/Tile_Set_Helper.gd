@tool
extends EditorPlugin

var hb: HBoxContainer = HBoxContainer.new()

func _enter_tree() -> void:
	var editor_button: Button = Button.new()
	editor_button.text = "Sync"
	editor_button.pressed.connect(_on_editor_button_pressed)
	
	hb.size_flags_horizontal = 10
	hb.add_child(editor_button)
	
	var tile_set_editor = EditorInterface.get_base_control().get_children()[0].get_children()[1].get_children()[1].get_children()[1].get_children()[0].get_children()[0].get_children()[1].get_children()[0].get_children()[12]
	tile_set_editor.get_children()[0].get_children()[0].add_child(hb)

func _on_editor_button_pressed():
	var selected_nodes: Array[Node] = EditorInterface.get_selection().get_selected_nodes()
	for node: Node in selected_nodes:
		if node is TileMapLayer:
			if node.tile_set == null: continue
			var sync: AcceptDialog = load("res://addons/Tile_Set_Helper/Sync.tscn").instantiate()
			sync.tile_map_layer = node
			sync.tile_set = node.tile_set
			hb.add_child(sync)
			sync.update_view()
			break

func _exit_tree() -> void:
	hb.queue_free()
