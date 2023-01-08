extends Control

const PLAYER_INVENTORY_LIMIT := 4
const POSITIVES = ['Hope','Joy','Comfort']

@onready var ItemButton = preload("res://item_button.tscn")

@onready var vessel_textures = [
	preload("res://textures/vessels/vessel1.png"),
	preload("res://textures/vessels/vessel2.png"),
	preload("res://textures/vessels/vessel3.png"),
]
@onready var broken_vessel_texture = preload("res://textures/vessels/broken.png")

const PRONOUNS = ["Him","Her","Them","It"]

# HUD
@onready var vessel_container = $VesselContainer
@onready var vessel_rect = $VesselContainer/Vessel
@onready var vessel_title = $Hud/VesselPane/Title
@onready var animation = $VesselContainer/AnimationPlayer

@onready var container = $Hud
@onready var arrow = $Hud/Arrow
@onready var player_title = $Hud/PlayerPane/Title
@onready var complete_button = $Hud/CompleteButton

@onready var sfx_clink = $Clink

@onready var your_list = $Hud/PlayerPane/List
@onready var their_list = $Hud/VesselPane/List

signal done

func present_vessel():
	container.visible = false
	arrow.visible = false
	visible = true
	modulate = Color(1,1,1,0)
	var tween = get_tree().create_tween().set_parallel(true).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self,'modulate',Color.WHITE,1)
	tween.tween_property(vessel_container,'position',Vector2(300,220),1).from(Vector2(300,500))
	await tween.finished

func present_interface():
	var tween = get_tree().create_tween().set_parallel(true).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	container.visible = true
	tween.tween_property(container,'modulate',Color.WHITE,1).from(Color(1,1,1,0))
	tween.tween_property(vessel_container,'position',Vector2(455,220),1)
	await tween.finished

func hide_interface():
	var tween = get_tree().create_tween().set_parallel(true).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	container.visible = true
	tween.tween_property(container,'modulate',Color(0,0,0,0),1).from(Color.WHITE)
	tween.tween_property(vessel_container,'position',Vector2(300,220),1)
	await tween.finished
	container.visible = false

func hide_screen():
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self,'modulate',Color(0,0,0,0),1)
	await tween.finished
	visible = false

func setup_lists(yours:Array,theirs:Array):
	randomize_vessel()
	for child in your_list.get_children(): child.queue_free()
	for child in their_list.get_children(): child.queue_free()
	
	for text in yours:
		var btn = ItemButton.instantiate()
		btn.text = text
		if text in POSITIVES:
			btn.modulate = Color.WHITE
		else:
			btn.modulate = Color.RED
		your_list.add_child(btn)
		btn.button_up.connect(_item_clicked.bind(btn))
		btn.mouse_entered.connect(_item_hovered.bind(btn))
		btn.mouse_exited.connect(_item_unhovered.bind(btn))
	
	for text in theirs:
		var btn = ItemButton.instantiate()
		btn.text = text
		if text in POSITIVES:
			btn.modulate = Color.WHITE
		else:
			btn.modulate = Color.RED
		their_list.add_child(btn)
		btn.button_up.connect(_item_clicked.bind(btn))
		btn.mouse_entered.connect(_item_hovered.bind(btn))
		btn.mouse_exited.connect(_item_unhovered.bind(btn))

# Will this vessel pass on successfully?
func score_vessel():
	
	var score = 0
	
	for button in their_list.get_children():
		var text = button.text.to_lower()
		match text:
			'angry': score -= 1
			'apathy': score -= 1
			'agony': score -= 1
			'fear': score -= 1
			
			'joy': score += 1
			'comfort': score += 1
			'hope': score += 1
	if their_list.get_children().is_empty():
		score -= 1
	
	return score # more is better

func get_their_inventory():
	var list = []
	for button in their_list.get_children():
		list.append(button.text)
	return list

func get_your_inventory():
	var list = []
	for button in your_list.get_children():
		list.append(button.text)
	return list

func randomize_vessel():
	animation.play('Idle')
	vessel_rect.self_modulate = Color.WHITE
	vessel_title.text = PRONOUNS.pick_random()
	vessel_rect.texture = vessel_textures.pick_random()

func broken_vessel():
	animation.play('Broken')
	vessel_title.text = ""
	vessel_rect.texture = broken_vessel_texture

func set_interactive(interactive:bool):
	for button in your_list.get_children():
		button.disabled = not interactive
	for button in their_list.get_children():
		button.disabled = not interactive
	complete_button.disabled = not interactive

func _item_clicked(item):
	var count = your_list.get_children().size()
	if item in your_list.get_children():
		your_list.remove_child(item)
		their_list.add_child(item)
		arrow.visible = false
		count -= 1
		sfx_clink.play()
	else:
		if count < PLAYER_INVENTORY_LIMIT:
			their_list.remove_child(item)
			your_list.add_child(item)
			count += 1
			sfx_clink.play()
		arrow.visible = false
	
	player_title.text = "You (%d/%d)" % [count,PLAYER_INVENTORY_LIMIT]
	

func _item_hovered(item):
	if not item.disabled:
		arrow.visible = true
		arrow.flip_h = not item in your_list.get_children()

func _item_unhovered(item):
	arrow.visible = false

func _on_complete_button_pressed():
	set_interactive(false)
	await hide_interface()
	done.emit()
