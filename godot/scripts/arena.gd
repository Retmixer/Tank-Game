extends Node3D
class_name BattleArena
## Authored level adapter: never generates geometry or overrides editor placement.
@export var map_id := "training"
@export var world_size := 560.0

func spawn_transform(team: int, slot: int) -> Transform3D:
	var group := get_node("Spawns/TeamA" if team == 0 else "Spawns/TeamB")
	var marker := group.get_child(posmod(slot,group.get_child_count())) as Marker3D
	return marker.global_transform

func height_at(x: float, z: float) -> float:
	if not is_inside_tree():
		return 0.0
	var query := PhysicsRayQueryParameters3D.create(Vector3(x,200,z),Vector3(x,-200,z),1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return float(hit.position.y) if not hit.is_empty() else 0.0
