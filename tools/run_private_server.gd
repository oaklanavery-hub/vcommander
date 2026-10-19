extends SceneTree

var server := PrivateRoomServer.new()

func _init() -> void:
    call_deferred("start_server")

func start_server() -> void:
    Engine.max_fps = 30
    var port := 8080
    var address := "127.0.0.1"
    if not OS.get_environment("PORT").is_empty():
        port = OS.get_environment("PORT").to_int()
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--port="):
            port = argument.trim_prefix("--port=").to_int()
        elif argument.begins_with("--listen="):
            address = argument.trim_prefix("--listen=")
    if port < 1 or port > 65535:
        printerr("Private server requires a port from 1 to 65535.")
        quit(1)
        return
    var content := root.get_node("ContentDatabase")
    if not content.load_errors.is_empty():
        printerr("Private server content validation failed.")
        quit(1)
        return
    var error := server.start(content, port, address)
    if error != OK:
        printerr("Private server could not listen: ", error_string(error))
        quit(1)
        return
    print("Private room server listening on ", address, ":", port,
        "; protocol ", PrivateProtocol.VERSION, "; content ", server.service.fingerprint)
    print("Unranked friend playtest. Reserved reconnect seats; no account persistence or ranked rewards.")

func _process(_delta: float) -> bool:
    server.poll()
    return false

func _finalize() -> void:
    server.stop()
