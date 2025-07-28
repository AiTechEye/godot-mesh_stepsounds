extends Node3D

var sounds = {
	"grass":load("res://res/grass.ogg"),
	"stone":load("res://res/stone.ogg"),
	"wood":load("res://res/wood.ogg"),
	"sand":load("res://res/sand.ogg"),
}

@onready var player = $player
@onready var cam = $player/head
@onready var speaker = $player/speaker

var stepsound_timer = 0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	
# Player ===============
	var direction = Vector3()
	var aim = cam.get_global_transform().basis
	if Input.is_key_pressed(KEY_W):
		direction -= aim.z
	if Input.is_key_pressed(KEY_S):
		direction += aim.z
	if Input.is_key_pressed(KEY_A):
		direction -= aim.x
	if Input.is_key_pressed(KEY_D):
		direction += aim.x
	if Input.is_key_pressed(KEY_SPACE) and player.is_on_floor():
		player.velocity.y += 5
	elif player.is_on_floor():
		player.velocity.y = 0
		if direction != Vector3() or stepsound_timer == 1:
			stepsound_timer += delta
			if stepsound_timer > 0.3:
				stepsound_timer = 0
				mesh_stepsound()
	else:
		stepsound_timer = 1
		player.velocity.y -= 9*delta
		if player.global_position.y < -2:
			player.global_position = Vector3(0,2,0)
	var tv = player.velocity.lerp(direction * 5,5 * delta)
	player.velocity.x = tv.x
	player.velocity.z = tv.z
	player.set_velocity(player.velocity)
	player.set_up_direction(Vector3(0,1,0))
	player.move_and_slide()

# Player cam ===============
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		cam.rotate_y(deg_to_rad(-event.relative.x * 0.3))
	else:
		if Input.is_key_pressed(KEY_ESCAPE) or Input.is_key_pressed(KEY_ENTER):
			get_tree().quit()


func mesh_stepsound():
	var pos = player.global_position
	var mat = get_mesh_surface_material_pos(pos,pos+Vector3(0,-1,0))
	var sound
#mesh with surfaces
	if mat != null and mat.albedo_texture != null:
		var s = mat.albedo_texture.get_path().get_file().get_slice(".",0)
		if sounds.has(s):
			sound = s
	else:
#mesh without surfaces/ built-in meches
		mat = get_mesh_material_pos(pos,pos+Vector3(0,-1,0))
		if mat != null and mat.albedo_texture != null:
			var s = mat.albedo_texture.get_path().get_file().get_slice(".",0)
			if sounds.has(s):
				sound = s

	if sound:
		$label.text = sound
		$textu.texture = mat.albedo_texture
		speaker.stream = sounds[sound]
		speaker.pitch_scale = randf_range(0.9,1.1)
		speaker.playing = true
	else:
		$label.text = ""
		$textu.texture = null

#check for meshes with materials, built-in meshes doen't work with it

func get_mesh_surface_material_pos(pos1:Vector3,pos2:Vector3):
	var ss = get_world_3d().direct_space_state
	var q = PhysicsRayQueryParameters3D.new()
	q.from = pos1
	q.to = pos2
	var result = ss.intersect_ray(q)
	if result and result.collider is StaticBody3D:
		var collider = result.collider
		var face_index = result.get("face_index",-1)
		var meshi
		if collider.get_parent() == MeshInstance3D:
			meshi = collider.get_parent()
		else:
			for i in result.collider.get_children():
				if i is MeshInstance3D:
					meshi = i
					break
		if meshi and meshi.mesh and face_index != -1:
			var mesh = meshi.mesh
			var curr_face_count = 0
			for inx in range(mesh.get_surface_count()):
				var s_arrays = mesh.surface_get_arrays(inx)
				var index = s_arrays[Mesh.ARRAY_INDEX]
				var s_triangle_count = index.size() / 3
				if face_index >= curr_face_count and face_index < curr_face_count + s_triangle_count:
					var mat = meshi.get_surface_override_material(inx)
					if mat == null:
						return mesh.surface_get_material(inx)
					return mat
				curr_face_count += s_triangle_count

func get_mesh_material_pos(pos1:Vector3,pos2:Vector3):
	var ss = get_world_3d().direct_space_state
	var q = PhysicsRayQueryParameters3D.new()
	q.from = pos1
	q.to = pos2
	var result = ss.intersect_ray(q)
	if result and result.collider is StaticBody3D:
		for node in result.collider.get_children():
			if node is MeshInstance3D:
				return node.get_surface_override_material(0)
