extends Node3D
## GodotFoundation demo world.
##
## Builds a streaming blocky voxel terrain at runtime with Voxel Tools
## (godot_voxel): a VoxelLodTerrain fed by a flat generator and a blocky
## mesher with three voxel types (air, grass, stone). Everything is created
## in code so the whole project stays plain text and CI-friendly — there are
## no hand-authored binary resources to drift out of sync.

const GRASS_TYPE := 1
const STONE_TYPE := 2

var terrain: VoxelLodTerrain


func _ready() -> void:
	_build_environment()
	terrain = _build_terrain()
	_build_camera()


func _build_environment() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	light.shadow_enabled = true
	add_child(light)

	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.35, 0.55, 0.85)
	sky_material.sky_horizon_color = Color(0.75, 0.85, 0.95)
	sky_material.ground_bottom_color = Color(0.2, 0.2, 0.25)
	sky_material.ground_horizon_color = Color(0.75, 0.85, 0.95)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	world_environment.environment = environment
	add_child(world_environment)


func _build_terrain() -> VoxelLodTerrain:
	# Block library: index 0 must be the empty (air) model.
	var library := VoxelBlockyLibrary.new()
	library.add_model(VoxelBlockyModelEmpty.new())
	var grass := VoxelBlockyModelCube.new()
	grass.color = Color(0.36, 0.72, 0.30)
	library.add_model(grass)
	var stone := VoxelBlockyModelCube.new()
	stone.color = Color(0.55, 0.55, 0.58)
	library.add_model(stone)
	library.bake()

	var generator := VoxelGeneratorFlat.new()
	generator.channel = VoxelBuffer.CHANNEL_TYPE
	generator.height = 0.0
	generator.voxel_type = GRASS_TYPE

	var mesher := VoxelMesherBlocky.new()
	mesher.library = library

	# The blocky mesher writes the model colors as vertex colors.
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0

	var lod_terrain := VoxelLodTerrain.new()
	lod_terrain.name = "VoxelTerrain"
	lod_terrain.generator = generator
	lod_terrain.mesher = mesher
	lod_terrain.material = material
	lod_terrain.view_distance = 96
	lod_terrain.lod_count = 3
	lod_terrain.voxel_bounds = AABB(Vector3(-512, -64, -512), Vector3(1024, 128, 1024))
	lod_terrain.generate_collisions = true
	add_child(lod_terrain)
	return lod_terrain


func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(28.0, 20.0, 42.0)
	add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.current = true
	# The viewer tells the terrain where to stream blocks around.
	var viewer := VoxelViewer.new()
	viewer.view_distance = 96
	camera.add_child(viewer)
