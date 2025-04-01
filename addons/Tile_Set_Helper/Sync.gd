@tool
extends AcceptDialog

@onready var source_node: VBoxContainer = %Source_Node
@onready var physic_node: VBoxContainer = %Physic_Node
@onready var terrain_node: VBoxContainer = %Terrain_Node
@onready var navigation_node: VBoxContainer = %Navigation_Node
@onready var custom_data_node: VBoxContainer = %Custom_Data_Node
@onready var occluder_node: VBoxContainer = %Occluder_Node

@onready var root: Node = get_tree().root

var sync_row: PackedScene = load("res://addons/Tile_Set_Helper/Sync_Row.tscn")

var tile_map_layer: TileMapLayer
var tile_set: TileSet
var tiles_data: Dictionary[Dictionary, TileData]
var copy_tiles_data: Dictionary[Dictionary, TileData]
var paste_tiles_data: Dictionary[Dictionary, TileData]
var current_source_index: int = -1
var current_source_id: int = -1
var copy_layer_id: int = -1
var copy_terrain_mode: int = -1
var copy_custom_data_layer_name: String = ""

func _exit_tree() -> void:
	var sync_data: Dictionary = {
		"copy_tiles_data": copy_tiles_data,
		"copy_layer_id": copy_layer_id,
		"copy_terrain_mode": copy_terrain_mode,
		"copy_custom_data_layer_name": copy_custom_data_layer_name,
	}
	root.set_meta("sync_data", sync_data)

func read_data():
	if root.has_meta("sync_data") == false:
		root.set_meta("sync_data", {})
	else:
		var sync_data: Dictionary = root.get_meta("sync_data")
		copy_tiles_data = sync_data.get_or_add("copy_tiles_data", copy_tiles_data)
		copy_layer_id = sync_data.get_or_add("copy_layer_id", copy_layer_id)
		copy_terrain_mode = sync_data.get_or_add("copy_terrain_mode", copy_terrain_mode)
		copy_custom_data_layer_name = sync_data.get_or_add("copy_custom_data_layer_name", copy_custom_data_layer_name)

func update_view():
	read_data()
	count_tiles_data()
	var button_group: ButtonGroup = ButtonGroup.new()
	var source_count: int = tile_set.get_source_count()
	for source_index in tile_set.get_source_count():
		var source_id: int = tile_set.get_source_id(source_index)
		var check_box: CheckBox = CheckBox.new()
		check_box.button_group = button_group
		check_box.text = "Source " + str(source_id)
		source_node.add_child(check_box)
		source_node.add_child(HSeparator.new())
		check_box.pressed.connect(_on_update_source_index.bind(source_index))
		if source_index == 0:
			check_box.button_pressed = true
			_on_update_source_index(source_index)
	
	var physics_layers: int = tile_set.get_physics_layers_count()
	for layer_id: int in physics_layers:
		var sync_row: HBoxContainer = sync_row.instantiate()
		physic_node.add_child(sync_row)
		sync_row.title.text = "Layer " + str(layer_id)
		sync_row.copy.pressed.connect(_on_layer_copy.bind(layer_id))
		sync_row.paste.pressed.connect(_on_physics_paste.bind(layer_id))
	physic_node.visible = physics_layers > 0
	
	var terrain_sets: int = tile_set.get_terrain_sets_count()
	for terrain_set in terrain_sets:
		var terrain_mode: TileSet.TerrainMode = tile_set.get_terrain_set_mode(terrain_set)
		var terrain_title: Label = Label.new()
		terrain_title.text = "Terrain Set " + str(terrain_set) + " - " + "Mode " + str(terrain_mode)
		terrain_node.add_child(terrain_title)
		var terrains: int = tile_set.get_terrains_count(terrain_set)
		for terrain_index: int in terrains:
			var sync_row: HBoxContainer = sync_row.instantiate()
			terrain_node.add_child(sync_row)
			sync_row.title.text = tile_set.get_terrain_name(terrain_set, terrain_index)
			sync_row.copy.pressed.connect(_on_terrain_copy.bind(terrain_mode))
			sync_row.paste.pressed.connect(_on_terrain_paste.bind(terrain_mode, terrain_set, terrain_index))
	terrain_node.visible = terrain_sets > 0
	
	var navigation_layer: int = tile_set.get_navigation_layers_count()
	for layer_id: int in navigation_layer:
		var sync_row: HBoxContainer = sync_row.instantiate()
		navigation_node.add_child(sync_row)
		sync_row.title.text = "Layer " + str(layer_id)
		sync_row.copy.pressed.connect(_on_layer_copy.bind(layer_id))
		sync_row.paste.pressed.connect(_on_navigation_paste.bind(layer_id))
	navigation_node.visible = navigation_layer > 0
	
	var custom_data_layers: int = tile_set.get_custom_data_layers_count()
	for layer_id: int in custom_data_layers:
		var sync_row: HBoxContainer = sync_row.instantiate()
		custom_data_node.add_child(sync_row)
		var custom_data_name: String = str(tile_set.get_custom_data_layer_name(layer_id))
		sync_row.title.text = "Custom Data - " + custom_data_name
		sync_row.copy.pressed.connect(_on_layer_copy.bind(layer_id))
		sync_row.copy.pressed.connect(_on_custom_data_copy.bind(custom_data_name))
		sync_row.paste.pressed.connect(_on_custom_data_paste.bind(layer_id))
	custom_data_node.visible = custom_data_layers > 0
	
	var occluder_layers: int = tile_set.get_occlusion_layers_count()
	for layer_id: int in occluder_layers:
		var sync_row: HBoxContainer = sync_row.instantiate()
		occluder_node.add_child(sync_row)
		sync_row.title.text = "Custom Data - " + str(layer_id)
		sync_row.copy.pressed.connect(_on_layer_copy.bind(layer_id))
		sync_row.paste.pressed.connect(_on_occluder_paste.bind(layer_id))
	occluder_node.visible = occluder_layers > 0
	
	var titles: Array[Node] = find_children("Title")
	for node: Button in titles:
		node.pressed.connect(_on_button_pressed.bind(node))
		var parent: Node = node.get_parent()
		if parent.visible == true:
			parent.add_sibling(HSeparator.new())

func count_tiles_data() -> void:
	for source_index: int in tile_set.get_source_count():
		var source_id: int = tile_set.get_source_id(source_index)
		var atlas_source: TileSetAtlasSource = tile_set.get_source(source_id)
		var tiles_count: int = atlas_source.get_tiles_count()
		for tile_index: int in tiles_count:
			var atlas_coords: Vector2i = atlas_source.get_tile_id(tile_index)
			var alternative_tiles_count = atlas_source.get_alternative_tiles_count(atlas_coords)
			for alternative_tile_index: int in alternative_tiles_count:
				var alternative_tile: int = atlas_source.get_alternative_tile_id(atlas_coords, alternative_tile_index)
				var tile_data: TileData = atlas_source.get_tile_data(atlas_coords, alternative_tile)
				tiles_data[{"source_id": source_id, "atlas_coords": atlas_coords, "alternative_tile": alternative_tile}] = tile_data

func get_current_source_tiles_data() -> Dictionary[Dictionary, TileData]:
	var source_tiles_data: Dictionary[Dictionary, TileData]
	for key in tiles_data:
		var source_id: int = key["source_id"]
		if current_source_id == source_id:
			var source_key = key.duplicate(true)
			source_key.erase("source_id")
			source_tiles_data[source_key] = tiles_data[key]
	return source_tiles_data

func _on_update_source_index(source_index: int):
	if current_source_index != source_index:
		current_source_index = source_index
		current_source_id = tile_set.get_source_id(source_index)
		paste_tiles_data = get_current_source_tiles_data()

func _on_layer_copy(layer_id: int):
	copy_tiles_data = get_current_source_tiles_data()
	copy_layer_id = layer_id

func _on_terrain_copy(terrain_mode: int):
	copy_tiles_data = get_current_source_tiles_data()
	copy_terrain_mode = terrain_mode

func _on_custom_data_copy(layer_name: String):
	copy_custom_data_layer_name = layer_name

func _on_physics_paste(layer_id: int):
	for key: Dictionary in paste_tiles_data:
		if copy_tiles_data.has(key) == false: continue
		var paste_tile_data: TileData = paste_tiles_data[key]
		var copy_tile_data: TileData = copy_tiles_data[key]
		paste_tile_data.set_constant_linear_velocity(layer_id, copy_tile_data.get_constant_linear_velocity(copy_layer_id))
		paste_tile_data.set_constant_angular_velocity(layer_id, copy_tile_data.get_constant_angular_velocity(copy_layer_id))
		var paste_polygons_count: int = paste_tile_data.get_collision_polygons_count(layer_id)
		var copy_polygons_count: int = copy_tile_data.get_collision_polygons_count(copy_layer_id)
		for polygon_index: int in paste_polygons_count:
			paste_tile_data.remove_collision_polygon(layer_id, 0)
		for polygon_index: int in copy_polygons_count:
			paste_tile_data.add_collision_polygon(layer_id)
			paste_tile_data.set_collision_polygon_points(layer_id, polygon_index, copy_tile_data.get_collision_polygon_points(copy_layer_id, polygon_index))
			paste_tile_data.set_collision_polygon_one_way(layer_id, polygon_index, copy_tile_data.is_collision_polygon_one_way(copy_layer_id, polygon_index))
			paste_tile_data.set_collision_polygon_one_way_margin(layer_id, polygon_index, copy_tile_data.get_collision_polygon_one_way_margin(copy_layer_id, polygon_index))

func _on_terrain_paste(terrain_mode: int, terrain_set: int, terrain: int):
	if terrain_mode != copy_terrain_mode: return
	for key: Dictionary in paste_tiles_data:
		if copy_tiles_data.has(key) == false: continue
		var paste_tile_data: TileData = paste_tiles_data[key]
		var copy_tile_data: TileData = copy_tiles_data[key]
		paste_tile_data.terrain_set = terrain_set
		paste_tile_data.terrain = terrain
		for peering_bit: int in 16:
			if copy_tile_data.is_valid_terrain_peering_bit(peering_bit) == true:
				var current_terrain = copy_tile_data.get_terrain_peering_bit(peering_bit)
				paste_tile_data.set_terrain_peering_bit(peering_bit, current_terrain)

func _on_navigation_paste(layer_id: int):
	for key: Dictionary in paste_tiles_data:
		if copy_tiles_data.has(key) == false: continue
		var paste_tile_data: TileData = paste_tiles_data[key]
		var copy_tile_data: TileData = copy_tiles_data[key]
		var paste_navigation_polygon: NavigationPolygon = paste_tile_data.get_navigation_polygon(layer_id)
		var copy_navigation_polygon: NavigationPolygon = copy_tile_data.get_navigation_polygon(copy_layer_id)
		paste_tile_data.set_navigation_polygon(layer_id, copy_navigation_polygon)

func _on_custom_data_paste(layer_id):
	if tile_set.has_custom_data_layer_by_name(copy_custom_data_layer_name) == false: return
	for key: Dictionary in paste_tiles_data:
		if copy_tiles_data.has(key) == false: continue
		var paste_tile_data: TileData = paste_tiles_data[key]
		var copy_tile_data: TileData = copy_tiles_data[key]
		var custom_data = copy_tile_data.get_custom_data(copy_custom_data_layer_name)
		paste_tile_data.set_custom_data(copy_custom_data_layer_name, custom_data)

func _on_occluder_paste(layer_id):
	for key: Dictionary in paste_tiles_data:
		if copy_tiles_data.has(key) == false: continue
		var paste_tile_data: TileData = paste_tiles_data[key]
		var copy_tile_data: TileData = copy_tiles_data[key]
		var paste_polygons_count: int = paste_tile_data.get_occluder_polygons_count(layer_id)
		var copy_polygons_count: int = copy_tile_data.get_occluder_polygons_count(copy_layer_id)
		for polygon_index: int in paste_polygons_count:
			paste_tile_data.remove_occluder_polygon(layer_id, 0)
		for polygon_index: int in copy_polygons_count:
			paste_tile_data.add_occluder_polygon(layer_id)
			paste_tile_data.set_occluder_polygon(layer_id, polygon_index, copy_tile_data.get_occluder_polygon(copy_layer_id, polygon_index))

func _on_visibility_changed() -> void:
	if visible == false:
		queue_free()

func _on_button_pressed(node: Node):
	var parent: Node = node.get_parent()
	for child: Node in parent.get_children():
		if child == node: continue
		child.visible = !child.visible
