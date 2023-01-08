extends Control

const VESSEL_PRESETS = [
	['this vessel lived a long, happy life','Joy','Comfort','Hope'],
	['this vessels time was short but joyous','Joy'],
	['this vessels death was sudden and unfortunate','Joy','Fear','Fear'],
	['witnessing this vessel fills you with dread','Agony','Agony','Agony','Agony'],
]

# Narration stuff
@onready
var narration_panel = $NarratonPanel
@onready
var narration_label = $NarratonPanel/Narration
var narration_tween

@onready var garden = $Garden
@onready var inventory_label = $Inventory
@onready var vessel_screen = $Vessel_Screen

var seeds := 3
var player_inventory = []
var selection := 0

var score := 0

func _ready():
	narration_panel.visible = false
	inventory_label.visible = false
	garden.clear_tiles()
	
#	await tutorial_1() # Planting
#	await tutorial_2() # Digging
#	await tutorial_3() # Vessel
#	await tutorial_4() # Vessel 2
#	await tutorial_5() # Broken Vessel
#	await tutorial_6() # Re-seeding
	
	await gameloop()


func gameloop():
	while seeds > 0:
		inventory_label.visible = true
		var vessels := 0
		# Plant seeds
		garden.clear_tiles()
		while seeds > 0:
			selection = await garden.tile_clicked
			if garden.tile_empty(selection):
				garden.set_tile(selection,garden.CELL_PLANTED)
				seeds -= 1
				vessels += 1
				update_inventory(false)
		selection = -1
		
		# Grow
		await wait(0.5)
		garden.grow_all()
		await wait(0.5)
		
		# Vessel
		while vessels > 0:
			while garden.tile_empty(selection):
				selection = await garden.tile_clicked
			
			garden.set_interactive(false)
			var preset = VESSEL_PRESETS.pick_random()
			if randi_range(1,10) == 10:
				vessel_screen.setup_lists(player_inventory,[])
				vessel_screen.broken_vessel()
				preset = ["a broken vessel. nothing can be done"]
			else:
				vessel_screen.setup_lists(player_inventory,preset.slice(1))
			
			vessel_screen.set_interactive(false)
			garden.set_tile(selection,garden.CELL_EMPTY)
			await vessel_screen.present_vessel()
			await present_narration("[%s]" % preset[0])
			await vessel_screen.present_interface()
			vessel_screen.set_interactive(true)
			await vessel_screen.done
			update_inventory()
			var score = vessel_screen.score_vessel()
			if preset.size() > 1 and score >= 0:
				await present_narration("[this vessel will move on peacefully]")
				score += 1
			else:
				await present_narration("[this vessel was unable to move on]")
			
			await vessel_screen.hide_screen()
			vessels -= 1
		
		var seed_count = count_positive_items()
		if seed_count != 0:
			seeds = seed_count
			player_inventory = []
			update_inventory()


func tutorial_1():
	seeds = 0
	await present_narration("welcome to the garden")
	await present_narration("im so glad you offered to help")
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

func tutorial_2():
	await present_narration("excellent")
	await present_narration("now, we await the fruits of your labor")
	garden.set_interactive(false)

	await wait(0.5)
	garden.grow_all()
	await wait(0.5)

	await present_narration("a bountiful harvest, well done")
	await present_narration("go on, choose one to dig up")
	
	selection = await garden.tile_clicked
	var wrong_count := 0
	while garden.tile_empty(selection):
		wrong_count += 1
		if wrong_count == 10:
			await present_narration("i appreciate your enthusiasm for digging")
			await present_narration("but now is not the time")
		selection = await garden.tile_clicked

func tutorial_3():
	garden.set_interactive(false)
	vessel_screen.setup_lists(["Joy"],["Apathy"])
	vessel_screen.set_interactive(false)
	garden.set_tile(selection,garden.CELL_EMPTY)
	await vessel_screen.present_vessel()
	
	await present_narration("very good")
	await present_narration("your seed has summoned a vessel")
	await present_narration("a being on the edge of oblivion")
	await present_narration("this vessel lived a short, unhappy life")
	await vessel_screen.present_interface()
	await present_narration("in this state, the vessel cannot pass on")
	await present_narration("you may choose to give it something to ease the pain")
	await present_narration("or take their burden as your own")
	await present_narration("the choice is yours")
	vessel_screen.set_interactive(true)
	await vessel_screen.done
	var count = vessel_screen.their_list.get_children().size()
	if count == 2:
		await present_narration("the vessel, content, will be able to move on")
		score += 1
	elif count == 0:
		await present_narration("the vessel, empty, will now be able to move on")
		score += 1
	elif count == 1:
		score += 1
		if vessel_screen.their_list.get_children()[0].text == 'Apathy':
			await present_narration("you chose to do nothing?")
			await present_narration("the vessel will be unable to pass on, condemned to haunt the earth")
			await present_narration("at times, there is nothing we can do, and this outcome is inevitable")
			await present_narration("this was not one of those times")
		else:
			await present_narration("how generous")
			await present_narration("you have given the vessel joy, and taken its burden")
			await present_narration("it will move on without issue")
			await present_narration("we were lucky, here - not every encounter may be so fortunate")
			score += 1
	await vessel_screen.hide_screen()
	update_inventory()
	
	await present_narration("2 more to go")

func tutorial_4():
	while garden.tile_empty(selection):
		selection = await garden.tile_clicked
	
	garden.set_interactive(false)
	vessel_screen.setup_lists(player_inventory,["Joy","Comfort","Hope"])
	vessel_screen.set_interactive(false)
	garden.set_tile(selection,garden.CELL_EMPTY)
	await vessel_screen.present_vessel()
	await vessel_screen.present_interface()
	await present_narration("this vessel lead a fulfilling existence")
	await present_narration("it will move on without issue")
	await present_narration("you may wish to take something, before sending it off")
	await present_narration("it may be useful, later")
	vessel_screen.set_interactive(true)
	await vessel_screen.done
	var score = vessel_screen.score_vessel()
	var count = vessel_screen.get_their_inventory().size()
	print(score," ",count)
	if count == 0: # Rob em blind
		await present_narration("you took everything it had")
		await present_narration("you may find it difficult to carry much more")
		await present_narration("the living can only experience so much")
		score += 1
	elif score < 0: # Bad person
		await present_narration("TODO put dialogue here lmao")
	elif score == 3: # Leave everything
		await present_narration("taking nothing?")
		await present_narration("very noble of you")
		await present_narration("this vessel will move on")
		score += 1
	elif count >= 3: # We rearranged something
		if score < 3:
			await present_narration("leaving some baggage with it?")
			await present_narration("do not worry, it will still move on")
			await present_narration("you may find this to be a necessary evil, at times")
			score += 1
		else:
			await present_narration("this vessel will move on")
			score += 1
	elif count < 3:
		await present_narration("good")
		await present_narration("it will never know, but what you have taken may help another vessel move on")
	update_inventory()
	await vessel_screen.hide_screen()

func tutorial_5():
	await present_narration("last one")
	while garden.tile_empty(selection):
		selection = await garden.tile_clicked
	
	garden.set_interactive(false)
	vessel_screen.setup_lists(player_inventory,[])
	vessel_screen.broken_vessel()
	vessel_screen.set_interactive(false)
	garden.set_tile(selection,garden.CELL_EMPTY)
	await vessel_screen.present_vessel()
	await vessel_screen.present_interface()
	await present_narration("oh")
	await present_narration("this vessel is broken")
	await present_narration("nothing can be done, i'm sorry")
	vessel_screen.set_interactive(true)
	await vessel_screen.done
	var score = vessel_screen.score_vessel()
	update_inventory()
	if score != 0:
		await present_narration("please, do not waste your resources on them")
		await present_narration("these vessels were destroyed long before they arrived here")
		await present_narration("i have tried. there is no saving them")
	await vessel_screen.hide_screen()

func tutorial_6():
	await present_narration("hope, joy, comfort...")
	await present_narration("any positive feeling you have left, at this point, are turned into seeds")
	await present_narration("and so the cycle begins anew")
	var count = count_positive_items()
	if count == 0:
		await present_narration("... oh, you don't have anything good left?")
		await present_narration("just this once, i will help and restore what you gave")
		await present_narration("but i will not extend this hospitality again")
		seeds = 2
	else:
		seeds = count
	player_inventory = []
	update_inventory(false)
	await present_narration("you now have seeds to continue on your own")
	await present_narration("if you are ever unable to gain new seeds, your time here will end")
	await present_narration("use what you have wisely")
	await present_narration("i trust you can take it from here. good luck")

func update_inventory(update:bool=true):
	if update: player_inventory = vessel_screen.get_your_inventory()
	if player_inventory.size() > 0:
		inventory_label.text = "You:\n" + "\n".join(player_inventory)
	else:
		inventory_label.text = "Seeds: " + str(seeds)

func count_positive_items():
	return player_inventory.reduce(func(accum, item):
		if item == 'Joy' or item == 'Hope' or item == 'Comfort': accum += 1
		return accum
	,0)

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

func _input(event):
	if event is InputEventKey:
		Engine.time_scale = 10 if Input.is_key_pressed(KEY_SPACE) else 1
