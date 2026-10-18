extends Control

@onready var status_label: Label = $Center/Panel/Status

func _ready() -> void:
    var summary := ContentDatabase.get_summary()
    if summary.get("ok", false):
        status_label.text = "Foundation OK\nCommanders: %d   Cards: %d   Sets: %d\nFire • Water • Earth • Slime" % [
            summary.get("commanders", 0),
            summary.get("cards", 0),
            summary.get("sets", 0)
        ]
    else:
        status_label.text = "Data load failed. Check the Godot output log."
