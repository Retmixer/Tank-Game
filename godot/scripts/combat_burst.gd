extends Node3D
## Shared, bounded one-shot effect; components are editable in combat_burst.tscn.
@export_enum("muzzle","penetration","ricochet","blocked","ground") var kind := "ground"
var age := 0.0
var duration := 1.4

func configure(type: String, direction: Vector3, winter := false) -> void:
	kind=type
	var sparks := $Sparks as GPUParticles3D
	var smoke := $Smoke as GPUParticles3D
	var spark_process := sparks.process_material as ParticleProcessMaterial
	var smoke_process := smoke.process_material as ParticleProcessMaterial
	var normal := direction.normalized() if direction.length_squared()>.001 else Vector3.UP
	spark_process.direction=normal
	smoke_process.direction=normal
	match kind:
		"muzzle":
			sparks.amount=7
			sparks.lifetime=.15
			spark_process.spread=12
			spark_process.initial_velocity_min=14
			spark_process.initial_velocity_max=24
			smoke.amount=9
			smoke_process.color=Color(.42,.4,.36,.3)
			smoke_process.initial_velocity_min=2
			smoke_process.initial_velocity_max=5
			$Flash.omni_range=8
		"ricochet":
			sparks.amount=30
			spark_process.spread=16
			spark_process.initial_velocity_min=10
			spark_process.initial_velocity_max=22
			smoke.amount=4
			$Flash.omni_range=3
		"penetration":
			sparks.amount=24
			smoke.amount=12
			smoke_process.color=Color(.23,.24,.25,.65)
			$Flash.omni_range=5
		"blocked":
			sparks.amount=18
			smoke.amount=5
			$Flash.omni_range=3
		"ground":
			var debris := StandardMaterial3D.new()
			debris.albedo_color=Color(.8,.86,.9) if winter else Color(.35,.26,.15)
			debris.roughness=1
			sparks.material_override=debris
			sparks.amount=12
			spark_process.color=Color(.6,.5,.35)
			spark_process.initial_velocity_min=2
			spark_process.initial_velocity_max=7
			smoke.amount=16
			smoke_process.color=Color(.85,.89,.93,.65) if winter else Color(.51,.42,.29,.6)
			$Flash.omni_range=2
	$Flash.light_energy=2.5 if kind=="muzzle" else 1.2
	$FlashSprite.scale=Vector3.ONE*(1.15 if kind=="muzzle" else .55)
	$Sparks.emitting=true
	$Smoke.emitting=true

func _process(delta: float) -> void:
	age+=delta
	$Flash.light_energy=maxf(0,$Flash.light_energy-delta*30)
	$FlashSprite.transparency=clampf(age/.11,0,1)
	$FlashSprite.visible=age<.11
	if age>duration:
		queue_free()
