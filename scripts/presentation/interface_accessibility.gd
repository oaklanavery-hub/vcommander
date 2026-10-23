class_name InterfaceAccessibility
extends RefCounted
## Text changes only: preserve the arena and pixel artwork's geometry.

static func apply_node(node: Node, scale: float) -> void:
    if not is_instance_valid(node) or not node is Control:
        return
    if not (node is Label or node is RichTextLabel or node is BaseButton or node is LineEdit):
        return
    var roles := ["font_size"]
    if node is RichTextLabel:
        roles = ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"]
    var original: Dictionary = node.get_meta("vc_original_font_sizes", {})
    for role in roles:
        if not original.has(role):
            original[role] = node.get_theme_font_size(role)
        var base := int(original[role])
        # Display titles are already large; enlarge body/control text instead.
        node.add_theme_font_size_override(role, roundi(base * scale) if base <= 24 else base)
    node.set_meta("vc_original_font_sizes", original)
    if bool(node.get_meta("vc_card_caption", false)):
        node.offset_top = -43.0 * scale
        var portrait := node.get_parent().get_node_or_null("PortraitArt") as Control
        if portrait != null:
            portrait.offset_bottom = -47.0 - (scale - 1.0) * 45.0
    if node is OptionButton:
        var popup: PopupMenu = node.get_popup()
        var base := int(popup.get_meta("vc_original_font_size", popup.get_theme_font_size("font_size")))
        popup.set_meta("vc_original_font_size", base)
        popup.add_theme_font_size_override("font_size", roundi(base * scale))

static func apply_tree(node: Node, scale: float) -> void:
    apply_node(node, scale)
    for child in node.get_children():
        apply_tree(child, scale)
