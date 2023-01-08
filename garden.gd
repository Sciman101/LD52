extends GridContainer

enum {
	CELL_EMPTY,
	CELL_PLANTED,
	CELL_GRAVE,
	CELL_ROTTEN
}

@onready var tiles = get_children()

var cells = []

signal tile_clicked(tile, index)

func _ready():
	var i = 0
	for tile in tiles:
		tile.focus_mode = Control.FOCUS_NONE
		tile.button_up.connect(_tile_clicked.bind(tile,i))
		cells.append(CELL_EMPTY)
		i += 1 

func clear_tiles():
	for i in range(cells.size()):
		cells[i] = CELL_EMPTY
		tiles[i].text = ""

func grow_all():
	for i in range(cells.size()):
		if cells[i] == CELL_PLANTED:
			set_tile(i,CELL_GRAVE)
		elif cells[i] == CELL_ROTTEN:
			set_tile(i,CELL_EMPTY)

func set_tile(index:int,cell:int):
	if index < 0 or index >= cells.size(): return
	cells[index] = cell
	if cell == CELL_PLANTED:
		tiles[index].text = "Planted"
	elif cell == CELL_GRAVE:
		tiles[index].text = "Grave"
	elif cell == CELL_ROTTEN:
		tiles[index].text = "Rotted"
	else:
		tiles[index].text = ""

func tile_empty(index:int):
	if index < 0 or index >= cells.size(): return true
	return cells[index] == CELL_EMPTY

func decay_adjacent(index:int):
	if index < 0 or index >= cells.size(): return true
	
	set_tile(index,CELL_ROTTEN)
	if index > 0: set_tile(index-1,CELL_ROTTEN)
	if index <= cells.size()-1: set_tile(index+1,CELL_ROTTEN)
	if index > 4: set_tile(index-4,CELL_ROTTEN)
	if index < 12: set_tile(index+4,CELL_ROTTEN)

func tile_grown(index:int):
	if index < 0 or index >= cells.size(): return true
	return cells[index] == CELL_GRAVE

func count_graves():
	return cells.reduce(func(accum,cell):
		if cell == CELL_GRAVE: accum += 1
		return accum
		,0)

func set_interactive(interactive:bool):
	for tile in tiles:
		tile.disabled = !interactive

func _tile_clicked(tile,index):
	tile_clicked.emit(index)
