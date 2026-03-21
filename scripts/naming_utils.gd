# Utility functions for generating names according to naming conventions
# Cavemen: CvCv or CvvC (consonant-vowel pattern)
# Landclaims: Cv CvCv or Cv CvvC (2-letter prefix + 4-letter name)
class_name NamingUtils

const CONSONANTS: String = "BCDFGHJKLMNPQRSTVWXYZ"
const VOWELS: String = "AEIOU"

static func generate_caveman_name() -> String:
	# Generate a name in CvCv or CvvC format
	# C = consonant, v = vowel
	var pattern: int = randi() % 2  # 0 = CvCv, 1 = CvvC
	
	if pattern == 0:
		# CvCv format
		var c1: String = CONSONANTS[randi() % CONSONANTS.length()]
		var v1: String = VOWELS[randi() % VOWELS.length()]
		var c2: String = CONSONANTS[randi() % CONSONANTS.length()]
		var v2: String = VOWELS[randi() % VOWELS.length()]
		return c1 + v1 + c2 + v2
	else:
		# CvvC format
		var c1: String = CONSONANTS[randi() % CONSONANTS.length()]
		var v1: String = VOWELS[randi() % VOWELS.length()]
		var v2: String = VOWELS[randi() % VOWELS.length()]
		var c2: String = CONSONANTS[randi() % CONSONANTS.length()]
		return c1 + v1 + v2 + c2

static func generate_landclaim_name() -> String:
	# Generate a name in "Cv CvCv" or "Cv CvvC" format
	# First part: 2-letter prefix (Cv)
	# Second part: 4-letter name (CvCv or CvvC)
	var prefix_c: String = CONSONANTS[randi() % CONSONANTS.length()]
	var prefix_v: String = VOWELS[randi() % VOWELS.length()]
	var prefix: String = prefix_c + prefix_v
	
	# Generate 4-letter name (CvCv or CvvC)
	var pattern: int = randi() % 2  # 0 = CvCv, 1 = CvvC
	
	if pattern == 0:
		# CvCv format
		var c1: String = CONSONANTS[randi() % CONSONANTS.length()]
		var v1: String = VOWELS[randi() % VOWELS.length()]
		var c2: String = CONSONANTS[randi() % CONSONANTS.length()]
		var v2: String = VOWELS[randi() % VOWELS.length()]
		return prefix + " " + c1 + v1 + c2 + v2
	else:
		# CvvC format
		var c1: String = CONSONANTS[randi() % CONSONANTS.length()]
		var v1: String = VOWELS[randi() % VOWELS.length()]
		var v2: String = VOWELS[randi() % VOWELS.length()]
		var c2: String = CONSONANTS[randi() % CONSONANTS.length()]
		return prefix + " " + c1 + v1 + v2 + c2

