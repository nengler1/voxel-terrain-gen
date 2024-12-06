@tool
extends Node3D

@export var clear_chunks : bool
@export var generate_chunks : bool
@export var chunk_size : int
@export var world_size : Vector3i

# chunk referenced by a vector3i (to find a block, first get to the chunk then the block) 
var chunks = {}

@export var seed : int
@export var noise_frequency : float
var noise

var chunk_prototype = preload("res://chunk.tscn")

var chunks_tagged_for_regen = []

# Called when the node enters the scene tree for the first time.
func _ready():
	generate_chunks = true
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if clear_chunks:
		clear_chunks = false
		clearing_chunks()
		
	if generate_chunks:
		noise = FastNoiseLite.new()
		noise.seed = seed
		noise.frequency = noise_frequency
		generate_chunks = false
		generating_chunks()
		
	for chunk in chunks_tagged_for_regen:
		chunk.gen_chunk()
	chunks_tagged_for_regen.clear()
		
func generating_chunks(): # using 3D array to map each chunk
	clearing_chunks()
	for x in range(world_size.x):
		for y in range(world_size.y):
			for z in range(world_size.z):
				# getting chunks through IDs
				generate_a_chunk(Vector3i(x * chunk_size, y * chunk_size, z * chunk_size))
				
				# optimizing rendering by waiting a frame to render each chunk
				await Engine.get_main_loop().process_frame 
				
func generate_a_chunk(pos : Vector3i):
	var chunk = chunk_prototype.instantiate()
	chunk.position = pos
	add_child(chunk)
	chunks[pos] = chunk
	chunk.init_blocks(chunk_size, pos)
	chunk.gen_chunk()
	
func set_block_by_world_position(pos : Vector3i, block_type : Block.BlockType):
	var chunk_pos = world_pos_to_chunk_pos(pos)
	var local_pos = pos - chunk_pos
	if chunks.has(chunk_pos):
		chunks[chunk_pos].set_block_chunk(local_pos, block_type)
		chunks_tagged_for_regen.append(chunks[chunk_pos])
		
	var adjacent_chunks = block_is_on_edge(local_pos)
	for adjacent_chunk in adjacent_chunks:
		var adjacent_chunk_pos = chunk_pos + adjacent_chunk * chunk_size
		if chunks.has(adjacent_chunk_pos):
			chunks_tagged_for_regen.append(chunks[adjacent_chunk_pos])
		
func block_is_on_edge(pos : Vector3i):
	var edges = []
	if pos.x == 0:
		edges.append(Vector3i(-1, 0, 0))
	if pos.y == 0:
		edges.append(Vector3i(0, -1, 0))
	if pos.z == 0:
		edges.append(Vector3i(0, 0, -1))
	if pos.x >= chunk_size-1:
		edges.append(Vector3i(1, 0, 0))
	if pos.y >= chunk_size-1:
		edges.append(Vector3i(0, 1, 0))
	if pos.z >= chunk_size-1:
		edges.append(Vector3i(0, 0, 1))
	return edges
	
func world_pos_to_chunk_pos(pos : Vector3i):
	return (pos / chunk_size) * chunk_size

func get_block(pos : Vector3i, from_noise = false):
	# rendering edges
	# any positions outside the world are treated as air
	if pos.x < 0 or pos.y < 0 or pos.z < 0 or pos.x >= world_size.x * chunk_size or pos.y >= world_size.y * chunk_size or pos.z >= world_size.z * chunk_size:
		return Block.BlockType.Air
	
	# Breaking a block refreshes the block if on edge of chunk
	if not from_noise:
		var chunk_pos = world_pos_to_chunk_pos(pos)
		var local_pos = pos - chunk_pos
		if chunks.has(chunk_pos):
			return chunks[chunk_pos].get_block_chunk(local_pos)
	
	var n = (noise.get_noise_2d(pos.x, pos.z) + 1) * chunk_size
	# if noise level is greater than the y position
	if n > pos.y:
		if pos.y > chunk_size * 1.2: # Upper height
			return Block.BlockType.Stone
		else:
			return Block.BlockType.Dirt
	else:
		return Block.BlockType.Air
		
func clearing_chunks():
	var children = get_children()
	for child in children:
		child.free()
