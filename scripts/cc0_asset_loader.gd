extends Node
class_name CC0AssetLoader

signal player_model_ready(scene: PackedScene)
signal enemy_model_ready(scene: PackedScene)
signal status_changed(message: String)

const PLAYER_LOCAL := "res://assets/cc0/Knight.glb"
const ENEMY_LOCAL := "res://assets/cc0/Skeleton_Minion.glb"
const PLAYER_CACHE := "user://cc0/Knight.glb"
const ENEMY_CACHE := "user://cc0/Skeleton_Minion.glb"
const PLAYER_URL := "https://cdn.jsdelivr.net/gh/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0@main/addons/kaykit_character_pack_adventures/Characters/gltf/Knight.glb"
const ENEMY_URL := "https://cdn.jsdelivr.net/gh/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0@main/addons/kaykit_character_pack_skeletons/Characters/gltf/Skeleton_Minion.glb"

var pending_downloads: Array[Dictionary] = []
var active_request: HTTPRequest

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://cc0"))
	_load_or_queue("player", PLAYER_LOCAL, PLAYER_CACHE, PLAYER_URL)
	_load_or_queue("enemy", ENEMY_LOCAL, ENEMY_CACHE, ENEMY_URL)
	_start_next_download()

func _load_or_queue(kind: String, local_path: String, cache_path: String, url: String) -> void:
	if ResourceLoader.exists(local_path):
		var packed := load(local_path) as PackedScene
		if packed != null:
			_emit_model(kind, packed)
			return
	if FileAccess.file_exists(cache_path):
		var cached := _import_runtime_glb(cache_path)
		if cached != null:
			_emit_model(kind, cached)
			return
	pending_downloads.append({"kind": kind, "path": cache_path, "url": url})

func _start_next_download() -> void:
	if active_request != null or pending_downloads.is_empty():
		if active_request == null and pending_downloads.is_empty():
			status_changed.emit("CC0 assets ready")
		return
	var item: Dictionary = pending_downloads.pop_front()
	active_request = HTTPRequest.new()
	add_child(active_request)
	active_request.request_completed.connect(_on_request_completed.bind(item))
	status_changed.emit("Loading free CC0 art…")
	var error := active_request.request(String(item.url))
	if error != OK:
		active_request.queue_free()
		active_request = null
		_start_next_download()

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, item: Dictionary) -> void:
	var request_to_free := active_request
	active_request = null
	if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300 and body.size() > 1000:
		var file := FileAccess.open(String(item.path), FileAccess.WRITE)
		if file != null:
			file.store_buffer(body)
			file.close()
			var packed := _import_runtime_glb(String(item.path))
			if packed != null:
				_emit_model(String(item.kind), packed)
	if request_to_free != null:
		request_to_free.queue_free()
	_start_next_download()

func _import_runtime_glb(path: String) -> PackedScene:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_file(path, state)
	if error != OK:
		return null
	var generated := document.generate_scene(state)
	if generated == null:
		return null
	var packed := PackedScene.new()
	if packed.pack(generated) != OK:
		generated.free()
		return null
	generated.free()
	return packed

func _emit_model(kind: String, packed: PackedScene) -> void:
	if kind == "player":
		player_model_ready.emit(packed)
	else:
		enemy_model_ready.emit(packed)
