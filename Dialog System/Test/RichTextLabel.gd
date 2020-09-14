extends RichTextLabel

export (Texture) var tab_icon

func _ready():
	var _parrent : TabContainer = get_parent()
	_parrent.set_tab_icon(self.get_index(), tab_icon)
