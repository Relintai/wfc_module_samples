extends TextureRect

export(Image) var img : Image

func _ready():
	var indexer : ImageIndexer = ImageIndexer.new()
	
	indexer.index_image(img)
	
	var indices : PoolIntArray = indexer.get_color_indices()
	
	#<overlapping name="Mazelike" N="3" periodic="True"/>
	
	var wfc : OverlappingWaveFormCollapse = OverlappingWaveFormCollapse.new()
	wfc.periodic_input = true
	wfc.out_height = 300
	wfc.out_width = 300
	wfc.pattern_size = 3
	wfc.set_input(indices, img.get_width(), img.get_height())
	wfc.initialize()
	var res : PoolIntArray = wfc.generate_image_index_data()
	
	var data : PoolByteArray = indexer.indices_to_argb8_data(res)
	
	var res_img : Image = Image.new()
	res_img.create_from_data(300, 300, false, Image.FORMAT_RGBA8, data)
	
	var res_tex : ImageTexture = ImageTexture.new();
	res_tex.create_from_image(res_img, 0)
	
	texture = res_tex

	
	


