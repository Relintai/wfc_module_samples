extends Control

export(int, "Overlapping,Tiled") var rect_type : int

export(NodePath) var source_image_rect_path : NodePath
export(NodePath) var result_image_rect_path : NodePath
export(NodePath) var settings_label_path : NodePath

var _current_data_index : int = -1

enum SampleDataType {
	SAMPLE_DATA_TYPE_OVERLAPPING = 0,
	SAMPLE_DATA_TYPE_TILED = 1,
};

class SampleData:
	var type : int = 0
	var image_name : String = ""
	var pattern_size : int = 3
	var periodic : bool = false
	var width : int = 0
	var height : int = 0
	var symmetry : int = 8
	var ground : bool = false
	var limit : int = 0
	var screenshots : int = 0
	var periodic_input : int = true
	
	func _to_string():
		return "SampleData\ntype: " + str(type) + \
			"\nimage_name: " + image_name + \
			"\npattern_size: " + str(pattern_size) + \
			"\nperiodic: " + str(periodic) + \
			"\nwidth: " + str(width) + \
			"\nheight: " + str(height) + \
			"\nsymmetry: " + str(symmetry) + \
			"\nground: " + str(ground) + \
			"\nlimit: " + str(limit) + \
			"\nscreenshots: " + str(screenshots) + \
			"\nperiodic_input: " + str(periodic_input)
			

var data : Array

func _init():
	load_data()
	
func load_data():
	var a = ResourceLoader.load("res://samples/samples.xml")
	
	data.clear()
	
	var xmlp : XMLParser = XMLParser.new()
	xmlp.open("res://samples/samples.xml")
	
	while xmlp.read() == OK:
		if xmlp.get_node_type() == XMLParser.NODE_ELEMENT:
			if xmlp.get_node_name() == "overlapping" || xmlp.get_node_name() == "simpletiled":
				var entry : SampleData = SampleData.new()
				
				if xmlp.get_node_name() == "overlapping":
					entry.type = SampleDataType.SAMPLE_DATA_TYPE_OVERLAPPING
				else:
					entry.type = SampleDataType.SAMPLE_DATA_TYPE_TILED
				
				for i in range(xmlp.get_attribute_count()):
					var attrib_name : String = xmlp.get_attribute_name(i)
					var attrib_value : String = xmlp.get_attribute_value(i)
					
					if attrib_name == "name":
						entry.image_name = attrib_value
					elif attrib_name == "N":
						entry.pattern_size = int(attrib_value)
					elif attrib_name == "periodic":
						if attrib_value == "True":
							entry.periodic = true
						else:
							entry.periodic = false
					elif attrib_name == "width":
						entry.width = int(attrib_value)
					elif attrib_name == "height":
						entry.height = int(attrib_value)
					elif attrib_name == "symmetry":
						entry.symmetry = int(attrib_value)
					elif attrib_name == "ground":
						entry.ground = int(attrib_value)
					elif attrib_name == "limit":
						entry.limit = int(attrib_value)
					elif attrib_name == "screenshots":
						entry.screenshots = int(attrib_value)
					elif attrib_name == "periodic_input":
						entry.periodic_input = int(attrib_value)
						
				data.push_back(entry)

func _enter_tree():
	_on_next_pressed()

func generate_image():
	if (rect_type == SampleDataType.SAMPLE_DATA_TYPE_OVERLAPPING):
		generate_image_overlapping()
	else:
		generate_image_tiled()

func generate_image_overlapping():
	get_node(source_image_rect_path).texture = null
	get_node(result_image_rect_path).texture = null
	
	var sd : SampleData = data[_current_data_index]
	
	get_node(settings_label_path).text = sd.to_string()
	
	var indexer : ImageIndexer = ImageIndexer.new()
	
	var img : Image = ResourceLoader.load("res://samples/" + sd.image_name + ".png")
	var source_tex : ImageTexture = ImageTexture.new();
	source_tex.create_from_image(img, 0)
	get_node(source_image_rect_path).texture = source_tex
	
	indexer.index_image(img)
	var indices : PoolIntArray = indexer.get_color_indices()
	
	var wfc : OverlappingWaveFormCollapse = OverlappingWaveFormCollapse.new()
	wfc.pattern_size = sd.pattern_size
	wfc.periodic_output = sd.periodic
	wfc.symmetry = sd.symmetry
	wfc.ground = sd.ground

	wfc.periodic_input = sd.periodic_input

	wfc.out_height = img.get_height()
	wfc.out_width = img.get_width()
	
	wfc.set_input(indices, img.get_width(), img.get_height())
	
	#todo
	#if sd.width > 0 && sd.height > 0:
	#	wfc.set_input(indices, sd.width, sd.height)
	#else:
	#	wfc.set_input(indices, img.get_width(), img.get_height())
	
	randomize()
	wfc.set_seed(randi())
	
	wfc.initialize()
	
	var res : PoolIntArray = wfc.generate_image_index_data()
	
	if (res.size() == 0):
		print("(res.size() == 0)")
		return
	
	var data : PoolByteArray = indexer.indices_to_argb8_data(res)
	
	var res_img : Image = Image.new()
	res_img.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, data)
	
	var res_tex : ImageTexture = ImageTexture.new();
	res_tex.create_from_image(res_img, 0)
	
	get_node(result_image_rect_path).texture = res_tex

func generate_image_tiled():
	pass

func _on_prev_pressed():
	while true:
		_current_data_index -= 1
		
		if _current_data_index < 0:
			_current_data_index = data.size() - 1
			
		if data[_current_data_index].type == rect_type:
			break
			
	generate_image()

func _on_next_pressed():
	while true:
		_current_data_index += 1
		
		if _current_data_index >= data.size():
			_current_data_index = 0
			
		if data[_current_data_index].type == rect_type:
			break
		
	generate_image()

func _on_tiled_toggled(on : bool):
	if !on:
		return
	
	rect_type = 1
	
	_current_data_index = -1
	
	_on_next_pressed()
	
func _on_overlapping_toggled(on : bool):
	if !on:
		return
		
	rect_type = 0
	
	_current_data_index = -1
	
	_on_next_pressed()

func _on_randomize_pressed():
	generate_image()
