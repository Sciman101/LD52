extends Control

# Narration stuff
@onready
var narration_panel = $NarratonPanel
@onready
var narration_label = $NarratonPanel/Narration
var narration_tween

@onready var garden = $Garden
@onready var inventory_label = $Inventory

var seeds := 0
var player_inventory = []

func _ready():
	narration_panel.visible = false
	inventory_label.visible = false
	garden.clear_tiles()
	
	await tutorial()


func tutorial():
	await present_narration("welcome to my garden")
	await present_narration("please, choose a plot to plant your seed")
	var selection = await garden.tile_clicked
	garden.set_tile(selection,garden.CELL_PLANTED)
	await present_narration("good")
	await present_narration("repeat until you are out of seeds")
	
	seeds = 2
	update_inventory()
	inventory_label.visible = true
	while seeds > 0:
		selection = await garden.tile_clicked
		if garden.tile_empty(selection):
			garden.set_tile(selection,garden.CELL_PLANTED)
			seeds -= 1
			update_inventory()
	
	await present_narration("excellent")
	await present_narration("now, we await the fruits of your labor")
	garden.set_interactive(false)
	
	await wait(0.5)
	garden.grow_all()
	await wait(0.5)
	
	await present_narration("a bountiful harvest, well done")
	await present_narration("go on, choose one to dig up")
	
	selection = await garden.tile_clicked
	garden.set_interactive(false)


func update_inventory():
	if player_inventory.size() > 0:
		inventory_label.text = "You:\n" + "\n".join(player_inventory)
	else:
		inventory_label.text = "Seeds: " + str(seeds)

func present_narration(text:String,block_tiles:bool=true):
	narration_panel.visible = true
	narration_label.text = text
	var tree = get_tree()
	
	if block_tiles: garden.set_interactive(false)
	
	if narration_tween:
		narration_tween.kill()
	narration_tween = tree.create_tween()
	narration_tween.tween_property(narration_panel,'modulate',Color.WHITE,0.75).from(Color(1,1,1,0))
	await narration_tween.finished
	while true:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			break
		await tree.process_frame
	narration_tween = tree.create_tween()
	narration_tween.tween_property(narration_panel,'modulate',Color(1,1,1,0),0.5)
	await narration_tween.finished
	narration_tween = null
	narration_panel.visible = false
	garden.set_interactive(true)

func wait(seconds:float):
	var timer = get_tree().create_timer(seconds)
	await timer.timeout
