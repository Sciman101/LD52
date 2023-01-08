extends Control

const VESSEL_PRESETS = [
	['This vessel lived a long, happy life','Joy','Comfort','Hope'],
	['This vessels time was short but joyous','Joy'],
	['This vessels death was sudden and unfortunate','Joy','Fear','Fear'],
	['Witnessing this vessel fills you with dread','Agony','Agony','Agony','Agony'],
	['This vessel died alone','Fear','Fear','Apathy','Anger'],
	['This vessel seems at peace','Comfort','Apathy','Hope'],
	['This vessel had nothing to lose','Anger','Fear','Comfort'],
	['The vessel feels like your favorite blanket','Comfort','Comfort'],
	['The vessel hovers in front of you, motionless','Agony','Fear','Agony'],
	['It looks like someone you saw the other day','Joy','Fear','Anger','Apathy'],
	['You wonder who this was','Apathy','Hope','Joy'],
	['The vessel is barely visible','Apathy','Apathy','Apathy'],
	['Your rusty shovel unturns another one','Agony','Agony','Agony','Hope','Hope','Hope'],
	['You can feel this vessel smiling','Joy','Joy'],
	['The vessel feels warm','Comfort'],
	['The vessel hovers above the floor','Hope','Fear'],
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

@onready var sfx_dig = $Sfx/Dig
@onready var sfx_plant = $Sfx/Plant
@onready var sfx_creepy = $Sfx/Creepy

var seeds := 3
var player_inventory = []
var selection := 0

var score := 0
var lost := 0
var round := 0

func _ready():
	narration_panel.visible = false
	garden.clear_tiles()
	update_inventory(false)
	
	await tutorial_1() # Planting
	await tutorial_2() # First vessel
	await tutorial_3() # Second vessel
	
	await gameloop()
	await present_narration("it appears your time here is up")
	await present_narration("i can handle things from here")
	await present_narration("in case you were curious how you performed,")
	if score == 0:
		await present_narration("you did not allow a single vessel to move on")
	else:
		await present_narration("you helped %d vessels move on" % score)
	await present_narration("additionally,")
	if lost == 0:
		await present_narration("no vessels were lost. good work")
	else:
		await present_narration("... %d vessels were lost" % lost)
	
	await present_narration("and so, the cycle continues")
	await present_narration("thank you for your time")


func gameloop():
	var vessels := 0
	while seeds > 0 or vessels > 0:
		inventory_label.visible = true
		
		selection = await garden.tile_clicked
		if garden.tile_empty(selection) and seeds > 0:
			garden.grow_all()
			garden.set_tile(selection,garden.CELL_PLANTED)
			seeds -= 1
			sfx_plant.play()
			update_inventory(false)
		elif garden.tile_grown(selection):
			garden.set_interactive(false)
			sfx_dig.play()
			var preset = VESSEL_PRESETS.pick_random()
			var broken = randi_range(1,10) == 10
			if round < 5 and seeds == 0: broken = false
			if broken:
				vessel_screen.setup_lists(player_inventory,[])
				vessel_screen.broken_vessel()
				preset = ["A broken vessel. Nothing can be done"]
			else:
				vessel_screen.setup_lists(player_inventory,preset.slice(1))
			
			vessel_screen.set_interactive(false)
			garden.set_tile(selection,garden.CELL_EMPTY)
			await vessel_screen.present_vessel()
			await present_narration("[%s]" % preset[0])
			await vessel_screen.present_interface()
			vessel_screen.set_interactive(true)
			await vessel_screen.done
			var score = vessel_screen.score_vessel()
			garden.grow_all()
			
			if broken or score < 0:
				sfx_creepy.pitch_scale = 0.4
				sfx_creepy.play()
				await present_narration("[This vessel was unable to move on]")
				if not broken and score <= -3:
					await present_narration("[Its suffering seeps out and rots the land around it]")
					garden.decay_adjacent(selection)
				if not broken: lost += 1
			elif score >= 3:
				await present_narration("[The vessel will move on peacefully. You receive 2 seeds]")
				score += 1
				seeds += 2
			elif score >= 0:
				await present_narration("[This vessel is contented and will move on. You receive a seed]")
				score += 1
				seeds += 1
				
			update_inventory()
			await vessel_screen.hide_screen()
		vessels = garden.count_graves()
		round += 1


func tutorial_1():
	seeds = 2
	update_inventory(false)
	await present_narration("welcome to the garden")
	await present_narration("im so glad you offered to help")
	await present_narration("please, choose a plot to plant your seed")
	selection = await garden.tile_clicked
	garden.set_tile(selection,garden.CELL_PLANTED)
	sfx_plant.play()
	seeds -= 1
	update_inventory(false)
	await present_narration("good")
	await present_narration("these can take some time to grow")
	await present_narration("in the meantime, plant another")
	while not garden.tile_empty(selection):
		selection = await garden.tile_clicked
	sfx_plant.play()
	garden.grow_all()
	seeds -= 1
	update_inventory(false)
	garden.set_tile(selection,garden.CELL_PLANTED)
	await wait(1)
	await present_narration("there it is, the first of the harvest")
	await present_narration("go on, dig it up. let us see the fruits of your labor")
	
	selection = await garden.tile_clicked
	var wrong_count := 0
	while not garden.tile_grown(selection):
		wrong_count += 1
		if wrong_count == 5:
			await present_narration("i appreciate your enthusiasm for digging")
			await present_narration("but now is not the time")
		selection = await garden.tile_clicked

func tutorial_2():
	sfx_dig.play()
	vessel_screen.setup_lists(["Joy"],["Apathy"])
	vessel_screen.set_interactive(false)
	garden.set_tile(selection,garden.CELL_EMPTY)
	await vessel_screen.present_vessel()
	sfx_creepy.play()
	
	await present_narration("very good")
	await present_narration("your seed has summoned a vessel")
	await present_narration("a being on the edge of oblivion")
	await present_narration("this vessel lived a short, unhappy life")
	await vessel_screen.present_interface()
	await present_narration("in this state, the vessel cannot pass on")
	await present_narration("a vessel must have at least as many positive memories")
	await present_narration("as it does negative, to move on successfully")
	await present_narration("i have given you Joy. use it to help this one pass peacefully")
	vessel_screen.set_interactive(true)
	await vessel_screen.done
	
	var count = vessel_screen.get_their_inventory().size()
	var score = vessel_screen.score_vessel()
	var saved = true
	if count == 2:
		await present_narration("good")
		await present_narration("now in balance, the vessel may pass on in peace")
		await present_narration("this is our goal")
	elif count == 0: # Stealy
		await present_narration("you have taken the vessels Apathy")
		await present_narration("while i commend your willingness to take on the burden of others")
		await present_narration("this vessel is now empty. it will not be able to pass on")
		await present_narration("at times this will be a necessary evil")
		await present_narration("this was not one of those times")
		saved = false
	else:
		if score == 1:
			await present_narration("how noble")
			await present_narration("you have taken the vessels suffering, and given it Joy")
			await present_narration("it will pass on peacefully. you were lucky in this case")
			await present_narration("not every one will be so easy")
		else:
			await present_narration("you did nothing?")
			await present_narration("sometimes this is preferred")
			await present_narration("we must save our resources for those in need")
			await present_narration("rather than waste them on a vessel beyond salvation")
			await present_narration("i trust you will use better judgment in the future")
			saved = false
	
	garden.grow_all()
	await vessel_screen.hide_screen()
	
	await present_narration("when a vessel is able to move on, it leaves behind a seed")
	await present_narration("and so the cycle continues")
	if not saved:
		await present_narration("you did not save the vessel")
		await present_narration("for the sake of your learning, i will give you a seed")
		await present_narration("do not expect me to exstend this hospitality again")
	seeds = 1
	update_inventory(false)

func tutorial_3():
	await present_narration("while you were correcting that vessel, your other seed grew")
	await present_narration("time passes strangely here. if you are unable to plant another seed,")
	await present_narration("or encounter a vessel, your time here will end")
	await present_narration("plant your remaining seed, and let us encounter the next vessel")
	selection = -1
	while not garden.tile_empty(selection) or selection == -1:
		selection = await garden.tile_clicked
	sfx_plant.play()
	garden.grow_all()
	seeds -= 1
	update_inventory(false)
	garden.set_tile(selection,garden.CELL_PLANTED)
	while not garden.tile_grown(selection):
		selection = await garden.tile_clicked
	sfx_dig.play()
	vessel_screen.setup_lists([],["Agony","Agony","Agony","Agony"])
	vessel_screen.set_interactive(false)
	garden.set_tile(selection,garden.CELL_EMPTY)
	await vessel_screen.present_vessel()
	sfx_creepy.play()
	await vessel_screen.present_interface()
	await present_narration("this vessel suffered for a long while")


func update_inventory(update:bool=true):
	if update: player_inventory = vessel_screen.get_your_inventory()
	inventory_label.text = ("Seeds: %d" % seeds)
	if player_inventory.size() > 0:
		inventory_label.text += "\nYou:\n" + "\n".join(player_inventory)

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
