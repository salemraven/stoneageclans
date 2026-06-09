extends Node
## Authoritative-ish world deltas per chunk (clan deaths, etc.) for streaming + future save/MP.

var _chunks: Dictionary = {}


func chunk_key(c: Vector2i) -> String:
	return "%d,%d" % [c.x, c.y]


func get_chunk_record(chunk: Vector2i) -> Dictionary:
	var k := chunk_key(chunk)
	if not _chunks.has(k):
		_chunks[k] = {"clan_deaths": 0}
	return _chunks[k]


func get_clan_deaths_in_chunk(chunk: Vector2i) -> int:
	return int(get_chunk_record(chunk).get("clan_deaths", 0))


func record_clan_death(chunk: Vector2i) -> void:
	var rec := get_chunk_record(chunk)
	rec["clan_deaths"] = int(rec.get("clan_deaths", 0)) + 1
	_chunks[chunk_key(chunk)] = rec


func reset_chunk(chunk: Vector2i) -> void:
	_chunks.erase(chunk_key(chunk))


func to_dict() -> Dictionary:
	return _chunks.duplicate(true)


func load_from_dict(data: Dictionary) -> void:
	_chunks = data.duplicate(true)
