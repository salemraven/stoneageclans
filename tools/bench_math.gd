extends RefCounted

## Shared bin / compare math for the NPC tick bench. Used by bench_npc_tick.gd
## and test_bench_bins.gd so the gate cannot drift from the test.

const BIN_WIDTH := 5
const REGRESS_FRAC := 0.05
const MIN_SAMPLES := 3


static func awake_bin(awake: int) -> int:
	return int(floor(float(maxi(0, awake)) / float(BIN_WIDTH))) * BIN_WIDTH


static func bin_rows(rows: Array) -> Dictionary:
	var bins: Dictionary = {}
	for item in rows:
		if not (item is Dictionary):
			continue
		var row: Dictionary = item
		var awake: int = int(row.get("npcs_physics_process", 0))
		if awake <= 0:
			continue
		var key: int = awake_bin(awake)
		if not bins.has(key):
			bins[key] = {"sum": 0.0, "n": 0}
		var bag: Dictionary = bins[key]
		bag["sum"] = float(bag["sum"]) + float(row.get("npc_usec_per_tick", 0.0))
		bag["n"] = int(bag["n"]) + 1
	var out: Dictionary = {}
	for key in bins.keys():
		var bag2: Dictionary = bins[key]
		var n: int = int(bag2["n"])
		out[key] = {
			"mean": float(bag2["sum"]) / float(maxi(n, 1)),
			"n": n,
		}
	return out


static func compare_bins(before: Dictionary, after: Dictionary) -> Dictionary:
	var details: Array = []
	var failed := false
	var shared: Array = []
	for key in after.keys():
		if before.has(key):
			shared.append(int(key))
	shared.sort()
	for key in shared:
		var b: Dictionary = before[key]
		var a: Dictionary = after[key]
		var nb: int = int(b.get("n", 0))
		var na: int = int(a.get("n", 0))
		if nb < MIN_SAMPLES or na < MIN_SAMPLES:
			continue
		var mb: float = float(b.get("mean", 0.0))
		var ma: float = float(a.get("mean", 0.0))
		var frac: float = 0.0 if mb <= 0.0 else (ma / mb) - 1.0
		var row := {
			"bin": key,
			"before": mb,
			"after": ma,
			"frac": frac,
			"n_before": nb,
			"n_after": na,
		}
		if frac > REGRESS_FRAC:
			failed = true
			row["fail"] = true
		details.append(row)
	return {"ok": not failed, "bins": details}


static func validate_run(rows: Array, peak_fighters: int, births: int, combat_entries: int, requested_seconds: float, warmup: float) -> Dictionary:
	var reasons: Array[String] = []
	if peak_fighters <= 0:
		reasons.append("peak_fighters=0")
	if births <= 0:
		reasons.append("births=0")
	if combat_entries <= 0:
		reasons.append("combat_entries=0")
	var needed: float = maxf(1.0, requested_seconds - warmup - 2.0)
	if rows.size() < int(needed * 0.5):
		reasons.append("short_capture samples=%d needed~%.0f" % [rows.size(), needed])
	return {"ok": reasons.is_empty(), "reasons": reasons}
