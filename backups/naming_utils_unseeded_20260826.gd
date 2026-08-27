# Archived 2026-08-26 — unseeded naming helpers removed from naming_utils.gd
# Use NamingUtils.generate_caveman_name_seeded() / generate_landclaim_name_seeded() instead.

const CONSONANTS: String = "BCDFGHJKLMNPQRSTVWXYZ"
const VOWELS: String = "AEIOU"

static func generate_caveman_name() -> String:
	var pattern: int = randi() % 2
	if pattern == 0:
		var c1: String = CONSONANTS[randi() % CONSONANTS.length()]
		var v1: String = VOWELS[randi() % VOWELS.length()]
		var c2: String = CONSONANTS[randi() % CONSONANTS.length()]
		var v2: String = VOWELS[randi() % VOWELS.length()]
		return c1 + v1 + c2 + v2
	var c1: String = CONSONANTS[randi() % CONSONANTS.length()]
	var v1: String = VOWELS[randi() % VOWELS.length()]
	var v2: String = VOWELS[randi() % VOWELS.length()]
	var c2: String = CONSONANTS[randi() % CONSONANTS.length()]
	return c1 + v1 + v2 + c2

static func generate_landclaim_name() -> String:
	var prefix_c: String = CONSONANTS[randi() % CONSONANTS.length()]
	var prefix_v: String = VOWELS[randi() % VOWELS.length()]
	var prefix: String = prefix_c + prefix_v
	var pattern: int = randi() % 2
	if pattern == 0:
		var c1: String = CONSONANTS[randi() % CONSONANTS.length()]
		var v1: String = VOWELS[randi() % VOWELS.length()]
		var c2: String = CONSONANTS[randi() % CONSONANTS.length()]
		var v2: String = VOWELS[randi() % VOWELS.length()]
		return prefix + " " + c1 + v1 + c2 + v2
	var c1: String = CONSONANTS[randi() % CONSONANTS.length()]
	var v1: String = VOWELS[randi() % VOWELS.length()]
	var v2: String = VOWELS[randi() % VOWELS.length()]
	var c2: String = CONSONANTS[randi() % CONSONANTS.length()]
	return prefix + " " + c1 + v1 + v2 + c2
