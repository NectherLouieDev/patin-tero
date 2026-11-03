extends SceneTree

const Shop = preload("res://scripts/economy/shop_model.gd")
var failures := 0

func _initialize() -> void:
	var shop = Shop.new()
	check("load config and roster", shop.load_data() == "")
	shop.reset(42)
	var initial_offers: Array[int] = shop.offers.duplicate()
	check("five offers", initial_offers.size() == 5)
	var first: int = initial_offers[0]
	var initial_coins: int = shop.coins
	check("purchase charges once and adds one", shop.buy(0).begins_with("Purchased") and shop.coins == initial_coins - int(shop.config.prices[first]) and shop.bench.size() == 1 and shop.offers[0] == -1)
	var before: Dictionary = snapshot(shop)
	check("sold offer has no side effects", shop.buy(0) == "Invalid or empty offer" and snapshot(shop) == before)
	shop.reset(42)
	check("same seed restores offers", shop.offers == initial_offers)
	var reroll_coins: int = shop.coins
	check("reroll costs exactly two", shop.reroll() == "Rerolled for 2 coins" and shop.coins == reroll_coins - 2 and shop.offers.size() == 5)
	shop.reset(42)
	shop.setup_zero_coins()
	before = snapshot(shop)
	check("insufficient purchase rolls back", shop.buy(0) == "Insufficient coins" and snapshot(shop) == before)
	check("insufficient reroll rolls back", shop.reroll() == "Insufficient coins for reroll" and snapshot(shop) == before)
	shop.reset(42)
	shop.setup_full_bench()
	before = snapshot(shop)
	check("full bench rejects without change", shop.buy(0) == "Bench is full" and snapshot(shop) == before)
	shop.reset(42)
	shop.setup_merge_bench(shop.offers[0])
	var merge_id: int = shop.bench[0].instance_id
	check("full bench purchase can merge", shop.buy(0).begins_with("Purchased") and shop.bench.size() == 8 and shop.bench[0].star == 2 and shop.bench[0].instance_id == merge_id)
	shop.reset(42)
	shop.planning_open = false
	before = snapshot(shop)
	check("closed shop rejects transaction", shop.buy(0) == "Shop is closed" and shop.reroll() == "Shop is closed" and snapshot(shop) == before)
	print("RESULT: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)

func snapshot(shop) -> Dictionary:
	return {"coins": shop.coins, "bench": shop.bench.duplicate(true), "offers": shop.offers.duplicate(), "next_id": shop.next_instance_id}

func check(label: String, ok: bool) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures += 1
