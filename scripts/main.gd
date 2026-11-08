extends Node3D
## GodotFoundation demo world.
##
## Builds a streaming blocky voxel terrain at runtime with Voxel Tools
## (godot_voxel): a VoxelLodTerrain fed by a custom rolling-hills generator
## (scripts/terrain_generator.gd) and a blocky mesher with four voxel types
## (air, grass, stone, dirt). Everything is created in code so the whole
## project stays plain text and CI-friendly — there are no hand-authored
## binary resources to drift out of sync. The camera slowly orbits the
## terrain so the streaming and meshing are visible in motion.

const GRASS_TYPE := 1
const STONE_TYPE := 2
const DIRT_TYPE := 3

var terrain: VoxelLodTerrain
var _camera_pivot: Node3D


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
	# Depth fog in the horizon color softens the edge where streaming stops.
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.75, 0.85, 0.95)
	environment.fog_density = 0.004
	environment.fog_sky_affect = 0.5
	world_environment.environment = environment
	add_child(world_environment)


func _build_terrain() -> VoxelLodTerrain:
	# Block library: index 0 must be the empty (air) model.
	var library := VoxelBlockyLibrary.new()
	library.add_model(VoxelBlockyModelEmpty.new())
	var grass := VoxelBlockyModelCube.new()
	grass.color = Color(0.30, 0.60, 0.25)
	library.add_model(grass)
	var stone := VoxelBlockyModelCube.new()
	stone.color = Color(0.55, 0.55, 0.58)
	library.add_model(stone)
	var dirt := VoxelBlockyModelCube.new()
	dirt.color = Color(0.45, 0.32, 0.20)
	library.add_model(dirt)
	library.bake()

	var generator: VoxelGenerator = preload("res://scripts/terrain_generator.gd").new()
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
	# The camera rides a slowly rotating pivot so the demo is in motion and
	# the terrain visibly streams as the viewpoint travels.
	_camera_pivot = Node3D.new()
	_camera_pivot.position = Vector3(0.0, 4.0, 0.0)
	add_child(_camera_pivot)
	var camera := Camera3D.new()
	camera.position = Vector3(30.0, 20.0, 38.0)
	_camera_pivot.add_child(camera)
	camera.look_at(Vector3(0.0, 2.0, 0.0), Vector3.UP)
	camera.current = true
	# The viewer tells the terrain where to stream blocks around.
	var viewer := VoxelViewer.new()
	viewer.view_distance = 96
	camera.add_child(viewer)


func _process(delta: float) -> void:
	if _camera_pivot != null:
		_camera_pivot.rotate_y(delta * 0.08)
