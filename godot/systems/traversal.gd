class_name FieldTraversal
extends RefCounted
var coyote:=0.0
var buffer:=0.0
var was_pressed:=false
var crouched:=false
var landings:=0
var peak:=0.0
var impact:=0.0

func update(body: CharacterBody3D,delta: float,direction: Vector3,sprint: bool,jump: bool,crouch: bool,load_ratio: float) -> Dictionary:
    var floor_before:=body.is_on_floor()
    coyote=0.12 if floor_before else maxf(0,coyote-delta)
    buffer=maxf(0,buffer-delta)
    if jump and not was_pressed:buffer=0.14
    was_pressed=jump
    var shape: BoxShape3D=body.get_child(0).shape
    if crouch and not crouched:
        shape.size.y=1.05;body.position.y-=0.325;crouched=true
    elif not crouch and crouched:
        var query:=PhysicsShapeQueryParameters3D.new()
        var full:=BoxShape3D.new();full.size=Vector3(0.58,1.69,0.58)
        query.shape=full;query.transform=body.global_transform;query.transform.origin.y+=0.325;query.collision_mask=1
        if body.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():
            shape.size.y=1.7;body.position.y+=0.325;crouched=false
    var speed:=2.6 if crouched else 8.5 if sprint else 5.5
    speed*=lerpf(1,0.8,clampf(load_ratio,0,1))
    var accel:=24.0 if floor_before else 7.0
    body.velocity.x=move_toward(body.velocity.x,direction.x*speed,accel*delta)
    body.velocity.z=move_toward(body.velocity.z,direction.z*speed,accel*delta)
    body.velocity.y=-0.5 if floor_before else maxf(-35,body.velocity.y-20*delta)
    var jumped:=false
    if buffer>0 and coyote>0 and not crouched:
        body.velocity.y=6.2;buffer=0;coyote=0;jumped=true
    # Small steps: sweep up, forward and down before committing any lift.
    var horizontal:=Vector3(body.velocity.x,0,body.velocity.z)*delta
    if floor_before and not jumped and horizontal.length()>0.001 and body.test_move(body.global_transform,horizontal):
        var raised:=body.global_transform
        if not body.test_move(raised,Vector3.UP*0.3):
            raised.origin.y+=0.3
            if not body.test_move(raised,horizontal):
                raised.origin+=horizontal
                var result:=KinematicCollision3D.new()
                if body.test_move(raised,Vector3.DOWN*0.34,result) and result.get_normal().y>0.7:
                    body.position.y+=maxf(0,0.3-result.get_travel().length())
    impact=body.velocity.y
    body.move_and_slide()
    var landed:=not floor_before and body.is_on_floor() and impact < -2
    if landed:landings+=1
    peak=maxf(peak,body.position.y)
    return {"jumped":jumped,"landed":landed,"damage":maxf(0,(-impact-11)*3) if landed else 0.0}
