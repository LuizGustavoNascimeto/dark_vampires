class_name ItemData
extends Resource

enum ITEM_TYPE{CHARM, OTHER}
@export var name: String = ""
@export var type: ITEM_TYPE = ITEM_TYPE.OTHER 
# code_name is used by the code to know if a item is the one expected.
@export var name_code: String = ""
@export_multiline var description: String = ""
@export var numeric_buff: float = 0
@export var icon: Texture2D
