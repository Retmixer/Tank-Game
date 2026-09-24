extends RefCounted
## Individual tactical state. Only visible enemies and recent last-seen positions are used.
var game: Node
var tank: BattleTank
var role := "assault"
var goal := "advance"
var objective := Vector3.ZERO
var target: BattleTank
var last_seen := Vector3.ZERO
var memory_left := 0.0
var reaction_left := 0.0
var decision_left := 0.0
var wait := 0.0
var elapsed := 0.0
var aggression := .6
var courage := .3
var reaction := .5
var preferred_range := 65.0
var flank := 1.0
var previous_position := Vector3.ZERO
var stuck_time := 0.0
var recovery_left := 0.0
var last_hp := 0.0
var recent_damage := 0.0
var seen: Dictionary={}
var formation_offset := Vector3.ZERO
var path := PackedVector3Array()
var path_index := 0
var path_goal := Vector3.INF
var path_left := 0.0
var rng := RandomNumberGenerator.new()

func setup(owner_game: Node, vehicle: BattleTank, slot: int) -> void:
	game=owner_game
	tank=vehicle
	rng.seed=int(vehicle.get_instance_id())+slot*7919
	role=["scout","flanker","assault","support"][clampi(int(tank.spec.c),0,3)]
	var profiles: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/ai/profiles.json"))
	var profile: Dictionary=profiles[role]
	aggression=clampf(float(profile.aggression)+rng.randf_range(-.12,.12),.1,.95)
	courage=clampf(float(profile.retreat_hp)+rng.randf_range(-.07,.07),.15,.5)
	preferred_range=float(profile.distance)*rng.randf_range(.85,1.15)
	reaction=float(profile.reaction)*rng.randf_range(.8,1.3)
	flank=-1.0 if slot%2==0 else 1.0
	formation_offset=Vector3(rng.randf_range(-3,3),0,rng.randf_range(-3,3))
	previous_position=tank.global_position
	last_hp=tank.hp
	wait=slot*.035
	publish()

func publish() -> void:
	tank.set_meta("ai_role",role)
	tank.set_meta("ai_goal",goal)
	tank.set_meta("ai_objective",objective)

func ray(from: Vector3,to: Vector3) -> Dictionary:
	return tank.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1,[tank.get_rid()]))

func can_see(enemy: BattleTank) -> bool:
	if tank.global_position.distance_to(enemy.global_position)>float(tank.spec.view):
		return false
	var hit := ray(tank.global_position+Vector3.UP*1.7,enemy.global_position+Vector3.UP*1.2)
	return hit.is_empty() or hit.collider==enemy

func perceive() -> void:
	var best: BattleTank
	var score := -INF
	for enemy in game.tanks:
		if not is_instance_valid(enemy) or enemy.destroyed or enemy.team==tank.team:
			continue
		if not can_see(enemy):
			continue
		var distance: float=tank.global_position.distance_to(enemy.global_position)
		var value: float=160-distance+(1-enemy.hp/enemy.max_hp)*45
		if enemy==target:
			value+=25 # Retain targets instead of flickering between opponents.
		if enemy.tracks_broken:
			value+=15
		if value>score:
			score=value
			best=enemy
		if not seen.has(enemy.get_instance_id()):
			seen[enemy.get_instance_id()]=true
			tank.spotted+=1
	if best!=target and best!=null:
		reaction_left=reaction*({"easy":1.6,"normal":1.0,"hard":.7}.get(game.runtime_settings.get("difficulty","normal"),1.0))
	target=best
	if is_instance_valid(target):
		last_seen=target.global_position
		memory_left=5.0

func think(dt: float) -> void:
	if tank.destroyed:
		return
	memory_left=maxf(0,memory_left-dt)
	reaction_left=maxf(0,reaction_left-dt)
	decision_left-=dt
	recent_damage=maxf(0,recent_damage-dt)
	if tank.hp<last_hp:
		recent_damage=4
		decision_left=0
	last_hp=tank.hp
	perceive()
	if decision_left<=0:
		choose_goal()
		var limit: float=game.arena.world_size*.44
		objective.x=clampf(objective.x,-limit,limit)
		objective.z=clampf(objective.z,-limit,limit)
		decision_left=rng.randf_range(1.8,3.2)
	var aiming := objective+Vector3.UP
	var shoot := false
	if is_instance_valid(target):
		var distance := tank.global_position.distance_to(target.global_position)
		var flight := distance/285.0
		aiming=target.global_position+Vector3.UP*1.2+target.velocity*flight*.85
		shoot=ready_to_fire(aiming)
	elif memory_left>0:
		aiming=last_seen+Vector3.UP*1.2
	var move := steer(dt)
	if tank.tracks_broken:
		move=Vector2.ZERO
	# Reloading support vehicles withdraw rather than stand exchanging shots.
	if is_instance_valid(target) and goal=="engage" and tank.global_position.distance_to(objective)<8:
		move=Vector2.ZERO
	tank.set_controls(move,aiming,shoot)
	publish()

func choose_goal() -> void:
	var position := tank.global_position
	var enemy_capture: float=game.capture_progress*(-1 if tank.team==0 else 1)
	if tank.hp/tank.max_hp<courage or (role=="support" and recent_damage>0 and tank.reload_left>2):
		goal="retreat"
		objective=cover_position(last_seen if memory_left>0 else Vector3.ZERO)
		return
	if enemy_capture>25:
		goal="defend"
		objective=Vector3(flank*6,0,0)
		return
	if is_instance_valid(target):
		var enemy_position := target.global_position
		var away := (position-enemy_position).normalized()
		if role=="flanker" and tank.hp/tank.max_hp>.5:
			goal="flank"
			objective=enemy_position+away*preferred_range+Vector3(-away.z,0,away.x)*flank*30
		elif tank.reload_left>2.5 and recent_damage>0:
			goal="reload_cover"
			objective=cover_position(enemy_position)
		else:
			goal="engage"
			objective=enemy_position+away*minf(preferred_range,float(tank.spec.view)*.65)
		return
	if memory_left>0:
		goal="search"
		objective=last_seen
		return
	var home: Vector3=game.arena.spawn_transform(tank.team,0).origin
	var outward := Vector3(home.x,0,home.z).normalized()
	var lateral := Vector3(-outward.z,0,outward.x)
	var capturers := 0
	for ally in game.ai_tanks:
		if is_instance_valid(ally) and not ally.destroyed and ally!=tank and ally.team==tank.team and ally.get_meta("ai_goal","")=="capture":
			capturers+=1
	if role=="support":
		goal="overwatch"
		objective=outward*65+lateral*flank*35
	elif capturers<2 and (role=="assault" or position.length()<75 or game.duration_left<100):
		goal="capture"
		objective=outward*4+lateral*flank*4+formation_offset
	else:
		goal="scout" if role=="scout" else "advance"
		objective=outward*30+lateral*flank*(55 if role=="scout" else 35)
		if position.distance_to(objective)<12:
			goal="capture" if capturers<2 else "guard"
			objective=outward*(5 if capturers<2 else 30)+lateral*flank*8

func cover_position(threat: Vector3) -> Vector3:
	var away := tank.global_position-threat
	away.y=0
	away=away.normalized() if away.length()>1 else Vector3.FORWARD
	var best := tank.global_position+away*22
	var best_score := -INF
	for i in 7:
		var direction := away.rotated(Vector3.UP,(i-3)*.35)
		var candidate := tank.global_position+direction*(18+i*2)
		candidate.y=game.arena.height_at(candidate.x,candidate.z)
		var block := ray(threat+Vector3.UP*1.5,candidate+Vector3.UP*1.2)
		var score := candidate.distance_to(threat)*.1
		if not block.is_empty() and not block.collider is BattleTank:
			score+=40
		if absf(candidate.y-tank.global_position.y)>8:
			score-=70
		if score>best_score:
			best_score=score
			best=candidate
	return best

func ready_to_fire(aim: Vector3) -> bool:
	if reaction_left>0 or tank.reload_left>0 or not is_instance_valid(target):
		return false
	var muzzle := tank.muzzle_transform().origin
	var direction := (aim-muzzle).normalized()
	if tank.cannon.global_basis.z.normalized().dot(direction)<.992:
		return false
	if tank.aim_spread>(.65+aggression*.25):
		return false
	var hit := ray(muzzle,aim)
	if not hit.is_empty() and hit.collider!=target:
		return false
	for ally in game.tanks:
		if not is_instance_valid(ally) or ally==tank or ally.destroyed or ally.team!=tank.team:
			continue
		var offset: Vector3=ally.global_position+Vector3.UP-muzzle
		var along := offset.dot(direction)
		if along>0 and along<muzzle.distance_to(aim) and (offset-direction*along).length()<2.3:
			return false
	return true

func steer(dt: float) -> Vector2:
	path_left-=dt
	var waypoint := objective
	if game.ai_navigation!=null and game.ai_navigation.ready:
		if path_left<=0 or objective.distance_to(path_goal)>18:
			path=game.ai_navigation.route(tank.global_position,objective)
			path_index=0
			path_goal=objective
			path_left=4.0+rng.randf()
		while path_index<path.size() and Vector2(path[path_index].x-tank.position.x,path[path_index].z-tank.position.z).length()<5:
			path_index+=1
		if path_index<path.size():
			waypoint=path[path_index]
	recovery_left=maxf(0,recovery_left-dt)
	var displacement := tank.global_position.distance_to(previous_position)
	previous_position=tank.global_position
	if tank.drive_input.y>.3 and displacement<.12 and not tank.tracks_broken:
		stuck_time+=dt
	else:
		stuck_time=0
	if stuck_time>2:
		recovery_left=1.6
		path_left=0
		stuck_time=0
		flank=-flank
	if recovery_left>0:
		return Vector2(flank*.7,-.75)
	var desired := waypoint-tank.global_position
	desired.y=0
	if desired.length()<5:
		return Vector2.ZERO
	var forward := -tank.global_basis.z
	var angle := atan2(forward.cross(desired.normalized()).y,forward.dot(desired.normalized()))
	var turn := clampf(angle*1.8,-1,1)
	var throttle := 1.0 if absf(angle)<.9 else .25 if absf(angle)<1.5 else 0.0
	var origin := tank.global_position+Vector3.UP
	var length := 7.0+absf(tank.move_speed)*1.3
	var block := ray(origin,origin+forward*length)
	var ground := ray(origin+forward*7+Vector3.UP*3,origin+forward*7-Vector3.UP*5)
	if ground.is_empty() or ground.normal.y<.6:
		return Vector2(flank,.0)
	if not block.is_empty() and absf(block.normal.y)<.7:
		var left := forward.rotated(Vector3.UP,.65)
		var right := forward.rotated(Vector3.UP,-.65)
		var left_hit := ray(origin,origin+left*length)
		var right_hit := ray(origin,origin+right*length)
		var left_space := length if left_hit.is_empty() else origin.distance_to(left_hit.position)
		var right_space := length if right_hit.is_empty() else origin.distance_to(right_hit.position)
		turn=1.0 if left_space>right_space else -1.0
		throttle=.2 if origin.distance_to(block.position)>4 else 0.0
		if maxf(left_space,right_space)<4:
			recovery_left=1.4
	return Vector2(turn,throttle)
