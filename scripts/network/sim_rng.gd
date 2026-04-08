extends Node
## Phase 7: server-owned RNG for simulation. Single-player uses randomize(); server can call set_seed() for reproducibility.

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


func set_sim_seed(seed: int) -> void:
	rng.seed = seed


func sim_randf() -> float:
	return rng.randf()


func sim_randf_range(from: float, to: float) -> float:
	return rng.randf_range(from, to)


func sim_randi_range(from: int, to: int) -> int:
	return rng.randi_range(from, to)
