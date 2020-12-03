extends Tree


func _ready():
	pass 

func _recieve_block_metadeta (data):
	print ("recived block metadata" + data)


func _on_GraphNode_graph_node_meta(meta):
	print ("meta sent", meta)
