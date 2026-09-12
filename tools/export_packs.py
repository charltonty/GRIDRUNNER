"""Blender 4.4: --python export_packs.py -- source.blend output_dir.
Preserves architecture's tiled PBR maps; bakes procedural prop color/roughness/metal.
"""
import bpy,json,sys,math
from pathlib import Path
from mathutils import Matrix,Vector
src,out=map(Path,sys.argv[sys.argv.index('--')+1:]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src));scene=bpy.context.scene
for o in list(bpy.data.objects):
 if o.name not in scene.objects:bpy.data.objects.remove(o,do_unlink=True)
roots=[o for o in bpy.data.objects if o.get('asset_id') and (not o.name.startswith('GR05') or o.get('asset_type')=='building')]
for o in bpy.data.objects:o.hide_render=True
scene.render.engine='CYCLES';scene.cycles.samples=1;scene.render.bake.margin=4;scene.render.bake.use_clear=False
records=[]
def xyz(v):return [round(v.x,5),round(v.z,5),round(-v.y,5)]
for root in roots:
 aid=root['asset_id'];arch=aid.startswith('GR05');print('START',aid,flush=True)
 bpy.context.view_layer.update();inv=root.matrix_world.inverted();deps=bpy.context.evaluated_depsgraph_get();parts={};cols={};doors=[];dm={};points=[];floor_boxes=[]
 for o in root.children_recursive:
  if o.get('door'):
   key='Door_%02d'%len(doors);dm[o]=key
   doors.append({'name':key,'pivot':xyz((inv@o.matrix_world).translation),'locked':bool(o.get('locked',False)),'motion':o.get('motion','rotate_z'),'angle':float(o.rotation_euler.z),'open':float(o.get('open_angle_degrees',100)),'walk_door':'DOOR_HINGE' in o.name})
 for o in root.children_recursive:
  if o.type not in {'MESH','CURVE','FONT'}:continue
  par=o.parent;key='Static'
  while par and par!=root:
   if par in dm:key=dm[par];break
   par=par.parent
  me=bpy.data.meshes.new_from_object(o.evaluated_get(deps),depsgraph=deps)
  if not me.vertices:continue
  if not arch:
   vs=[v.co.copy() for v in me.vertices];lo=[min(v[k] for v in vs) for k in range(3)];hi=[max(v[k] for v in vs) for k in range(3)]
   att=me.attributes.new('gr_generated','FLOAT_VECTOR','POINT');raw=me.attributes.new('gr_object','FLOAT_VECTOR','POINT')
   for i,v in enumerate(vs):att.data[i].vector=[(v[k]-lo[k])/max(hi[k]-lo[k],1e-6) for k in range(3)];raw.data[i].vector=v
  me.transform(inv@o.matrix_world);points.extend([v.co.copy() for v in me.vertices])
  floor=arch and any(label in o.name for label in ('Floor_slab','Upper_floor','Upper_landing','Stair_arrival_landing'))
  if floor:
   floor_boxes.append({'center':xyz((inv@o.matrix_world).translation),'size':[float(o.dimensions[k]) for k in (0,2,1)]})
  if arch and not floor and (o.get('collision_candidate') or 'Entrance_ramp' in o.name) and 'Stair_tread' not in o.name:
   cm=o.data.copy() if o.type=='MESH' else me.copy()
   if o.type=='MESH':cm.transform(inv@o.matrix_world)
   cm.calc_loop_triangles();col=cols.setdefault(key,[])
   for t in cm.loop_triangles:
    for vi in reversed(t.vertices):col.extend(xyz(cm.vertices[vi].co))
   bpy.data.meshes.remove(cm)
  n=bpy.data.objects.new('Export',me);scene.collection.objects.link(n);parts.setdefault(key,[]).append(n)
 meshes=[]
 for key,objects in parts.items():
  bpy.ops.object.select_all(action='DESELECT')
  for n in objects:n.select_set(True)
  bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();n=bpy.context.object;n.name=key;meshes.append(n)
 if not arch:
  bpy.ops.object.select_all(action='DESELECT')
  for n in meshes:n.select_set(True)
  bpy.context.view_layer.objects.active=meshes[0];bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.008);bpy.ops.object.mode_set(mode='OBJECT')
  originals={m for n in meshes for m in n.data.materials if m and m.use_nodes};copies={}
  for m in originals:
   c=m.copy();copies[m]=c;ns=c.node_tree.nodes;ls=c.node_tree.links
   for node in list(ns):
    if node.type=='TEX_COORD':
     for socket,attr in [('Generated','gr_generated'),('Object','gr_object')]:
      a=ns.new('ShaderNodeAttribute');a.attribute_name=attr
      for l in list(node.outputs[socket].links):ls.new(a.outputs['Vector'],l.to_socket)
  for n in meshes:
   for slot in n.material_slots:
    if slot.material in copies:slot.material=copies[slot.material]
  images={}
  for channel in ['color','orm']:
   im=bpy.data.images.new(aid+'_'+channel,width=512,height=512,alpha=False)
   if channel=='orm':im.colorspace_settings.name='Non-Color'
   for c in copies.values():
    ns=c.node_tree.nodes;ls=c.node_tree.links;p=next(n for n in ns if n.type=='BSDF_PRINCIPLED');output=next(n for n in ns if n.type=='OUTPUT_MATERIAL');em=ns.new('ShaderNodeEmission')
    def wire(s,t):
     if s.is_linked:ls.new(s.links[0].from_socket,t)
     else:t.default_value=s.default_value
    if channel=='color':wire(p.inputs['Base Color'],em.inputs['Color'])
    else:
     combine=ns.new('ShaderNodeCombineXYZ');combine.inputs[0].default_value=1;wire(p.inputs['Roughness'],combine.inputs[1]);wire(p.inputs['Metallic'],combine.inputs[2]);ls.new(combine.outputs[0],em.inputs['Color'])
    ls.new(em.outputs[0],output.inputs['Surface']);t=ns.new('ShaderNodeTexImage');t.image=im;ns.active=t
   bpy.ops.object.bake(type='EMIT');images[channel]=im
  mat=bpy.data.materials.new(aid+'_Atlas');mat.use_nodes=True;ns=mat.node_tree.nodes;ls=mat.node_tree.links;p=ns.get('Principled BSDF')
  t=ns.new('ShaderNodeTexImage');t.image=images['color'];ls.new(t.outputs['Color'],p.inputs['Base Color'])
  t=ns.new('ShaderNodeTexImage');t.image=images['orm'];sep=ns.new('ShaderNodeSeparateColor');ls.new(t.outputs[0],sep.inputs[0]);ls.new(sep.outputs['Green'],p.inputs['Roughness']);ls.new(sep.outputs['Blue'],p.inputs['Metallic'])
  special={}
  for original,copy in copies.items():
   p0=next(n for n in original.node_tree.nodes if n.type=='BSDF_PRINCIPLED');glow=p0.inputs['Emission Strength'].default_value
   if glow:
    m=mat.copy();p1=m.node_tree.nodes.get('Principled BSDF');p1.inputs['Emission Strength'].default_value=min(glow,3);p1.inputs['Emission Color'].default_value=p0.inputs['Emission Color'].default_value;special[copy]=m
  for n in meshes:
   for slot in n.material_slots:slot.material=special.get(slot.material,mat)
 else:
  for m in {m for n in meshes for m in n.data.materials if m and m.use_nodes}:
   if 'glass' in m.name:
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Alpha'].default_value=.25;p.inputs['Transmission Weight'].default_value=0;m.surface_render_method='DITHERED'
 for n in meshes:
  old=list(n.data.materials);unique=[];indices=[]
  for m in old:
   if m not in unique:unique.append(m)
   indices.append(unique.index(m))
  pi=[indices[p.material_index] for p in n.data.polygons];n.data.materials.clear()
  for m in unique:n.data.materials.append(m)
  for p,i in zip(n.data.polygons,pi):p.material_index=i
 for d in doors:
  n=next((n for n in meshes if n.name==d['name']),None)
  if n:
   pv=d['pivot'];v=Vector((pv[0],-pv[2],pv[1]));n.data.transform(Matrix.Translation(-v));n.location=v
   arr=cols.get(d['name'],[])
   for i in range(0,len(arr),3):
    for k in range(3):arr[i+k]-=pv[k]
 bpy.ops.object.select_all(action='DESELECT')
 for n in meshes:n.select_set(True)
 bpy.context.view_layer.objects.active=meshes[0]
 bpy.ops.export_scene.gltf(filepath=str(out/(aid+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_extras=False)
 rec={'id':aid,'source':src.name,'doors':doors,'dimensions':[round(max(v[k] for v in points)-min(v[k] for v in points),4) for k in [0,2,1]]}
 (out/(aid+'.json')).write_text(json.dumps({'asset':rec,'collision':cols,'floor_boxes':floor_boxes},separators=(',',':')));records.append(rec)
 for n in meshes:bpy.data.objects.remove(n,do_unlink=True)
 print('DONE',aid,flush=True)
(out/(src.stem+'_manifest.json')).write_text(json.dumps(records,indent=2))
