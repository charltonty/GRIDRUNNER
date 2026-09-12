"""Extract CC0 MakeHuman base-mesh head; omit body, proxy and joint-helper geometry."""
from pathlib import Path
import sys
source=Path(sys.argv[1]);vertices=[];faces=[];group=''
for line in source.read_text().splitlines():
    p=line.split()
    if not p:continue
    if p[0]=='v':vertices.append(tuple(map(float,p[1:4])))
    if p[0]=='g':group=p[1]
    if p[0]=='f' and group=='body':
        ids=[int(v.split('/')[0])-1 for v in p[1:]]
        if min(vertices[i][1] for i in ids)>6.05:faces.append(ids)
used=sorted({i for f in faces for i in f});mapping={old:new+1 for new,old in enumerate(used)}
out=Path(__file__).resolve().parents[1]/'assets/humans';out.mkdir(exist_ok=True)
lines=['# Derived from MakeHuman base.obj, CC0. Head only; mirrored to Godot -Z forward.','o FieldHumanHead','s 1']
for i in used:
    x,y,z=vertices[i];lines.append(f'v {x*.105:.6f} {(y-6.05)*.105:.6f} {-z*.105:.6f}')
for face in faces:lines.append('f '+' '.join(str(mapping[i]) for i in reversed(face)))
(out/'field_head.obj').write_text('\n'.join(lines)+'\n')
print('Head:',len(used),'vertices,',sum(len(f)-2 for f in faces),'triangles')
