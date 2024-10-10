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

# Called when the node enters the scene tree for the first time.
func _ready():
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
	
func get_block(pos : Vector3i):
	# rendering edges
	# any positions outside the world are treated as air
	#if pos.x < 0 or pos.y < 0 or pos.z < 0 or pos.x >= world_size.x * chunk_size or pos.y >= world_size.y * chunk_size or pos.z >= world_size.z * chunk_size:
	#	return Block.BlockType.Air
	
	var n = (noise.get_noise_2d(pos.x, pos.z) + 1) * chunk_size
	# if noise level is greater than the y position
	if n > pos.y:
		return Block.BlockType.Dirt
	else:
		return Block.BlockType.Air
		
func clearing_chunks():
	var children = get_children()
	for child in children:
		child.free()
