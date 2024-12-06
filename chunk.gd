@tool # Helps with iteration
extends MeshInstance3D

var chunk_size : int = 16

# Creating the cub faces
var a_mesh = ArrayMesh.new()
var vertices = PackedVector3Array()
var normals = PackedVector3Array()
var indices = PackedInt32Array()
var uvs = PackedVector2Array()

var tex_div = 0.25
var face_count

var blocks = []

var first_load = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Creates a 3D array where each index is a cube
func init_blocks(_chunk_size : int, pos : Vector3i):
	chunk_size = _chunk_size
	blocks.resize(chunk_size)
	# Local position
	for x in range(chunk_size):
		blocks[x] = []
		for y in range(chunk_size):
			blocks[x].append([])
			for z in range(chunk_size):
				# High level position
				blocks[x][y].append(get_parent().get_block(Vector3i(pos.x + x, pos.y + y, pos.z + z), first_load))
	
	first_load = false
				
func set_block_chunk(local_pos : Vector3i, block_type : Block.BlockType):
	blocks[local_pos.x][local_pos.y][local_pos.z] = block_type
	
func get_block_chunk(local_pos : Vector3i):
	return blocks[local_pos.x][local_pos.y][local_pos.z]
	
# Draws one cube face with uv texture
func add_uvs(x, y):
	uvs.append(Vector2(tex_div * x, tex_div * y))
	uvs.append(Vector2(tex_div * x + tex_div, tex_div * y))
	uvs.append(Vector2(tex_div * x + tex_div, tex_div * y + tex_div))
	uvs.append(Vector2(tex_div * x, tex_div * y + tex_div))
	
func add_uvs_by_block_type(block_type: Block.BlockType, is_top_block, is_top_face):
	match block_type:
		Block.BlockType.Dirt:
			if is_top_block and is_top_face:
				add_uvs(0, 2) # Top Face
			elif is_top_block:
				add_uvs(1, 2) # Side grass
			else:
				add_uvs(0, 3) # Dirt
		Block.BlockType.Stone:
			add_uvs(3, 0)  # UV for Stone
	
func add_triangles():
	indices.append(face_count * 4 + 0)
	indices.append(face_count * 4 + 1)
	indices.append(face_count * 4 + 2)
	indices.append(face_count * 4 + 0)
	indices.append(face_count * 4 + 2)
	indices.append(face_count * 4 + 3)
	face_count += 1 # goes to next face
	
func add_normals(count : int, vector : Vector3):
	for i in range(count):
		normals.append(vector)
	
	
func gen_cube_mesh(pos : Vector3):
	var is_top_block = false
	var block_type = blocks[pos.x][pos.y][pos.z]
	
	# if air above a cube
	if block_is_air(pos + Vector3(0, 1, 0)):
		var top_face = true
		# TOP FACE (y is always positive)
		vertices.append(pos + Vector3(-0.5,  0.5, -0.5))
		vertices.append(pos + Vector3( 0.5,  0.5, -0.5))
		vertices.append(pos + Vector3( 0.5,  0.5,  0.5))
		vertices.append(pos + Vector3(-0.5,  0.5,  0.5))
		
		add_normals(4, Vector3(0, 1, 0))
		add_triangles()
		is_top_block = true
		add_uvs_by_block_type(block_type, is_top_block, top_face)
		#add_uvs(0, 2)
	
	# if air right of a cube
	if block_is_air(pos + Vector3(1, 0, 0)):
		# EAST FACE (x is always positive)
		vertices.append(pos + Vector3( 0.5,  0.5,  0.5))
		vertices.append(pos + Vector3( 0.5,  0.5, -0.5))
		vertices.append(pos + Vector3( 0.5, -0.5, -0.5))
		vertices.append(pos + Vector3( 0.5, -0.5,  0.5))
		
		add_normals(4, Vector3(1, 0, 0))
		add_triangles()
		add_uvs_by_block_type(block_type, is_top_block, false)
		#if is_top_block:
		#	add_uvs(1, 2)
		#else:
		#	add_uvs(0, 3)
	
	# if air behind a cube
	if block_is_air(pos + Vector3(0, 0, 1)):
		# SOUTH FACE (z is always positive)
		vertices.append(pos + Vector3( -0.5,  0.5,  0.5))
		vertices.append(pos + Vector3(  0.5,  0.5,  0.5))
		vertices.append(pos + Vector3(  0.5, -0.5,  0.5))
		vertices.append(pos + Vector3( -0.5, -0.5,  0.5))
		
		add_normals(4, Vector3(0, 0, 1))
		add_triangles()
		add_uvs_by_block_type(block_type, is_top_block, false)
		#if is_top_block:
		#	add_uvs(1, 2)
		#else:
		#	add_uvs(0, 3)
	
	# if air left to a cube
	if block_is_air(pos + Vector3(-1, 0, 0)):
		# WEST FACE (x is always negative)
		vertices.append(pos + Vector3( -0.5,  0.5, -0.5))
		vertices.append(pos + Vector3( -0.5,  0.5,  0.5))
		vertices.append(pos + Vector3( -0.5, -0.5,  0.5))
		vertices.append(pos + Vector3( -0.5, -0.5, -0.5))
		
		add_normals(4, Vector3(-1, 0, 0))
		add_triangles()
		add_uvs_by_block_type(block_type, is_top_block, false)
		#if is_top_block:
		#	add_uvs(1, 2)
		#else:
		#	add_uvs(0, 3)
	
	# if air in front of a cube
	if block_is_air(pos + Vector3(0, 0, -1)):
		# NORTH FACE (z is always negative)
		vertices.append(pos + Vector3(  0.5,  0.5, -0.5))
		vertices.append(pos + Vector3( -0.5,  0.5, -0.5))
		vertices.append(pos + Vector3( -0.5, -0.5, -0.5))
		vertices.append(pos + Vector3(  0.5, -0.5, -0.5))
		
		add_normals(4, Vector3(0, 0, -1))
		add_triangles()
		add_uvs_by_block_type(block_type, is_top_block, false)
		#if is_top_block:
		#	add_uvs(1, 2)
		#else:
		#	add_uvs(0, 3)
	
	# if air below a cube
	if block_is_air(pos + Vector3(0, -1, 0)):
		# BOTTOM FACE (y is always negative)
		vertices.append(pos + Vector3( -0.5, -0.5,  0.5))
		vertices.append(pos + Vector3(  0.5, -0.5,  0.5))
		vertices.append(pos + Vector3(  0.5, -0.5, -0.5))
		vertices.append(pos + Vector3( -0.5, -0.5, -0.5))
		
		add_normals(4, Vector3(0, -1, 0))
		add_triangles()
		is_top_block = true
		add_uvs_by_block_type(block_type, is_top_block, false)
		#add_uvs(0, 3)
	
# Generates a single chunk
func gen_chunk():
	a_mesh = ArrayMesh.new()
	vertices = PackedVector3Array()
	normals = PackedVector3Array()
	indices = PackedInt32Array()
	uvs = PackedVector2Array()
	face_count = 0
	
	for x in range(chunk_size):
		for y in range(chunk_size):
			for z in range(chunk_size):
				if (blocks[x][y][z] == Block.BlockType.Air):
					pass
				else:
					gen_cube_mesh(Vector3(x, y, z))
	
	if face_count > 0:
		var array = []
		array.resize(Mesh.ARRAY_MAX)
		array[Mesh.ARRAY_VERTEX] = vertices
		array[Mesh.ARRAY_NORMAL] = normals
		array[Mesh.ARRAY_INDEX] = indices
		array[Mesh.ARRAY_TEX_UV] = uvs
		a_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
		
		var trimesh_collisions = a_mesh.create_trimesh_shape()
		var collisionshape3d : CollisionShape3D = find_child("StaticBody3D").find_child("CollisionShape3D")
		collisionshape3d.set_shape(trimesh_collisions)
	mesh = a_mesh
	
func block_is_air(pos : Vector3):
	# Checking whether a neighboring block is air
	var block
	if pos.x < 0 or pos.y < 0 or pos.z < 0:
		# pos : local position
		# position : world chunk position
		block = get_parent().get_block(pos + position)
		return block == Block.BlockType.Air
	elif pos.x >= chunk_size or pos.y >= chunk_size or pos.z >= chunk_size:
		block = get_parent().get_block(pos + position)
		return block == Block.BlockType.Air
	elif blocks[pos.x][pos.y][pos.z] == Block.BlockType.Air:
		return true
	else:
		return false
