import * as T from './three.js';
import {experienceState,selectedProfile,cameraPose,clipCamera} from './experience.js';
export class CameraManager{
 constructor(){this.position=new T.Vector3();this.identity='';this.transition=0;}
 update(camera,s,screen,settings,solids,ground,dt){const state=experienceState(s,screen),p=selectedProfile(s.experience,state),identity=state+':'+p.id+':'+s.mode;const changed=identity!==this.identity;if(changed){this.identity=identity;this.transition=settings.reduceMotion?0:1;}
 const anchor=s.pos.toArray(),desired=cameraPose(s,p,{distance:settings.chaseDistance,height:settings.chaseHeight});
 if(p.distance){desired[1]=Math.max(ground(desired[0],desired[2])+.4,desired[1]);const safe=clipCamera(anchor,desired,solids);if(changed||settings.reduceMotion)this.position.fromArray(safe);else this.position.lerp(new T.Vector3().fromArray(safe),1-Math.exp(-dt*settings.cameraSmoothing));this.position.fromArray(clipCamera(anchor,this.position.toArray(),solids));camera.position.copy(this.position);const aim=new T.Vector3(s.pos.x-Math.sin(s.yaw)*12,s.pos.y+Math.sin(s.pitch)*12,s.pos.z-Math.cos(s.yaw)*12);if(p.id==='overhead')aim.copy(s.pos);camera.lookAt(aim);
 }else{const bikeLean=camera.rotation.z,bikePitch=camera.rotation.x;if(state==='bike'&&p.id==='helmet'){/* Existing suspension feedback already applied. */}else camera.position.fromArray(clipCamera(anchor,desired,solids));camera.rotation.set(s.pitch,s.yaw,0,'YXZ');if(state==='drone'&&p.id==='fpv'&&!settings.reduceMotion){camera.rotation.z=-Math.max(-.12,Math.min(.12,s.droneSystem.velocity[0]*.004))*settings.leanInfluence;camera.rotation.x+=Math.max(-.06,Math.min(.06,s.droneSystem.velocity[2]*.002))*settings.leanInfluence;}else if(state==='bike'&&!settings.reduceMotion){camera.rotation.z=bikeLean*settings.leanInfluence;camera.rotation.x=bikePitch;}}
 const dynamic=state==='bike'?Math.min(Math.abs(s.speed)/30,1)*8*settings.speedFov:0,target=Math.max(45,Math.min(105,settings.fov+p.fov+dynamic));camera.fov+=(target-camera.fov)*(settings.reduceMotion?1:1-Math.exp(-dt*8));camera.updateProjectionMatrix();this.transition=settings.reduceMotion?0:Math.max(0,this.transition-dt*3);
 return {state,profile:p,changed,transition:this.transition};
 }
}
