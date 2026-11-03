extends Control

const Shop = preload("res://scripts/economy/shop_model.gd")

@onready var seed_input: SpinBox = $Margin/Rows/Seed
@onready var balance: Label = $Margin/Rows/Balance
@onready var offers_list: ItemList = $Margin/Rows/Offers
@onready var bench_list: ItemList = $Margin/Rows/Bench
@onready var feedback: Label = $Margin/Rows/Feedback
var shop = Shop.new()

func _ready() -> void:
	var error: String = shop.load_data()
	if error != "":
		feedback.text = error
		return
	shop.reset(int(seed_input.value))
	$Margin/Rows/ShopActions/Buy.pressed.connect(_buy)
	$Margin/Rows/ShopActions/Reroll.pressed.connect(_reroll)
	$Margin/Rows/SetupActions/Reset.pressed.connect(_reset)
	$Margin/Rows/SetupActions/Zero.pressed.connect(func() -> void: shop.setup_zero_coins(); _show("TEST balance set to zero"))
	$Margin/Rows/SetupActions/Full.pressed.connect(func() -> void: shop.setup_full_bench(); _show("TEST bench filled with nine distinct characters"))
	$Margin/Rows/SetupActions/Merge.pressed.connect(_prepare_merge)
	_show("TEST economy values are provisional")

func _buy() -> void:
	var selected: PackedInt32Array = offers_list.get_selected_items()
	_show(shop.buy(selected[0] if not selected.is_empty() else -1))

func _reroll() -> void:
	_show(shop.reroll())

func _reset() -> void:
	shop.reset(int(seed_input.value))
	_show("Reset with seed %d" % shop.seed_value)

func _prepare_merge() -> void:
	var selected: PackedInt32Array = offers_list.get_selected_items()
	if selected.is_empty() or shop.offers[selected[0]] < 0:
		_show("Select a valid offer first")
		return
	shop.setup_merge_bench(shop.offers[selected[0]])
	_show("TEST full bench prepared with two matching copies; buy selected offer")

func _show(message: String) -> void:
	feedback.text = message
	_refresh()

func _refresh() -> void:
	if shop.definitions.is_empty():
		return
	balance.text = "Coins: %d | Reroll: 2 | Seed: %d | PROVISIONAL prices and starting balance" % [shop.coins, shop.seed_value]
	offers_list.clear()
	for index in shop.offers.size():
		var definition_index: int = shop.offers[index]
		var label: String = "SOLD" if definition_index < 0 else "%s — %d coins" % [shop.definitions[definition_index].name, int(shop.config.prices[definition_index])]
		offers_list.add_item("Offer %d: %s" % [index + 1, label])
	bench_list.clear()
	for item in shop.bench:
		bench_list.add_item("#%d %s | %d star" % [item.instance_id, shop.definitions[item.definition_index].name, item.star])
	while bench_list.item_count < int(shop.config.bench_capacity):
		bench_list.add_item("Empty slot")
