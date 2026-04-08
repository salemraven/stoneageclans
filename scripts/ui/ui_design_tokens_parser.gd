extends RefCounted
class_name UIDesignTokensParser

## Parses design_tokens.json into a Dictionary. No dependency on UITheme (avoids autoload cycles).

const DEFAULT_PATH: String = "res://ui/design_tokens/design_tokens.json"


static func load_file(path: String = DEFAULT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var data: Variant = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	var root: Dictionary = data as Dictionary
	if int(root.get("version", 0)) < 1:
		return {}
	return root


static func parse_color(v: Variant) -> Color:
	match typeof(v):
		TYPE_STRING:
			var s: String = str(v).strip_edges()
			if s.is_empty():
				return Color.WHITE
			return Color.html(s)
		TYPE_ARRAY:
			var a: Array = v as Array
			if a.size() == 3:
				return Color(float(a[0]), float(a[1]), float(a[2]), 1.0)
			if a.size() >= 4:
				return Color(float(a[0]), float(a[1]), float(a[2]), float(a[3]))
	return Color.MAGENTA
