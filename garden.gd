extends GridContainer

enum {
	CELL_EMPTY,
	CELL_PLANTED,
	CELL_GRAVE
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

func set_tile(index:int,cell:int):
	cells[index] = cell
	if cell == CELL_PLANTED:
		tiles[index].text = "Planted"
	elif cell == CELL_GRAVE:
		tiles[index].text = "Grave"
	else:
		tiles[index].text = ""

func tile_empty(index:int):
	return cells[index] == CELL_EMPTY

func set_interactive(interactive:bool):
	for tile in tiles:
		tile.disabled = !interactive

func _tile_clicked(tile,index):
	tile_clicked.emit(index)
