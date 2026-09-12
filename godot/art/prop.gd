extends Node3D
@export_enum("bike","drone","trailer","crate","generator","solar","cabinet","workbench","npc") var kind: String="crate"
func _ready() -> void:
    match kind:
        "bike": FieldKit.bike(self)
        "drone": FieldKit.drone(self)
        "trailer": FieldKit.trailer(self)
        "crate": FieldKit.crate(self)
        "generator": FieldKit.generator(self,Vector3.ZERO)
        "solar": FieldKit.solar(self,Vector3.ZERO)
        "cabinet": FieldKit.cabinet(self,Vector3.ZERO)
        "workbench": FieldKit.workbench(self,Vector3.ZERO)
        "npc": FieldKit.npc(self,Vector3.ZERO,true)
