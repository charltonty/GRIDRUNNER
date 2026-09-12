"""Kenney CC0 foley + original layers. Run with the extracted Kenney Audio folder."""
from pathlib import Path
import sys, subprocess, wave
import numpy as np
from scipy.signal import butter, sosfilt
OUT=Path(__file__).resolve().parents[1]/'assets/audio/polish'
OUT.mkdir(parents=True,exist_ok=True)
SOURCE=Path(sys.argv[1]); RATE=24000; rng=np.random.default_rng(92026)
def decoded(name):
    b=subprocess.check_output(['ffmpeg','-v','error','-i',str(SOURCE/name),'-f','f32le','-ac','1','-ar',str(RATE),'-'])
    a=np.frombuffer(b,dtype='<f4').copy();return a/max(.01,np.max(np.abs(a)))
def filtered(a,cutoff):return sosfilt(butter(2,cutoff,fs=RATE,output='sos'),a)
def save(name,a,peak=.5):
    a=a-np.mean(a);a*=peak/max(.001,np.max(np.abs(a)));edge=min(120,len(a)//10)
    a[:edge]*=np.linspace(0,1,edge);a[-edge:]*=np.linspace(1,0,edge)
    with wave.open(str(OUT/(name+'.wav')),'wb') as w:
        w.setparams((1,2,RATE,0,'NONE','not compressed'));w.writeframes((np.clip(a,-1,1)*32767).astype('<i2').tobytes())
banks={'dirt':('grass',1800),'dry_soil':('grass',2400),'grass':('grass',3200),'leaves':('grass',6500),'gravel':('snow',5500),'rock':('concrete',3500),'concrete':('concrete',5000),'asphalt':('concrete',2300),'wood':('wood',4000),'metal':('concrete',5500),'mud':('snow',1100),'water':('snow',4500),'interior':('carpet',3200)}
for surface,(base,cutoff) in banks.items():
    for i in range(5):
        a=filtered(decoded(f'footstep_{base}_{i:03d}.ogg'),cutoff);t=np.arange(len(a))/RATE
        if base=='carpet':
            # Some upstream carpet filenames share bytes; a restrained original fabric tail
            # makes each delivered bank entry distinct rather than only renaming samples.
            a+=filtered(rng.normal(0,.006,len(a)),1000)*np.exp(-t*12)
        if surface=='metal':
            impact=decoded(f'impactMetal_light_{i:03d}.ogg');a=np.pad(a,(0,max(0,len(impact)-len(a))));a[:len(impact)]+=.16*impact
        if surface in ('gravel','leaves','water','mud'):
            noise=rng.normal(0,.1,len(a));envelope=np.exp(-t*12)*(1-np.exp(-t*60));a[:len(t)]+=filtered(noise,1200 if surface=='mud' else 4500)*envelope*2
        save(f'{surface}_{i}',a,.48)
        body=decoded(f'impactSoft_heavy_{i:03d}.ogg');land=np.zeros(max(len(a),len(body)));land[:len(a)]+=.55*a;land[:len(body)]+=.32*filtered(body,1400)
        save(f'land_{surface}_{i}',land,.58)
for name,duration in [('creek',14),('leaves_wind',18),('insects',19),('electrical',13),('tire',8),('freewheel',6)]:
    t=np.arange(int(duration*RATE))/RATE;noise=rng.normal(0,1,len(t))
    if name=='creek':a=filtered(noise,2600)*(.6+.12*np.sin(t*1.4))
    elif name=='leaves_wind':a=filtered(noise,900)*(.5+.15*np.sin(t*.7)+.1*np.sin(t*1.9))
    elif name=='insects':a=np.sin(t*2*np.pi*3600)*np.maximum(0,np.sin(t*2.1))**16*.15+filtered(noise,5000)*.012
    elif name=='electrical':a=np.sin(t*2*np.pi*120)*.09+filtered(noise,600)*.08
    elif name=='tire':a=filtered(noise,1300)*(.5+.2*np.sin(t*17))
    else:a=filtered(noise,4000)*np.maximum(0,np.sin(t*2*np.pi*14))**22
    fade=RATE//2;a[:fade]*=np.linspace(0,1,fade);a[-fade:]*=np.linspace(1,0,fade);save(name,a,.35)
for i in range(5):
    a=filtered(decoded(f'footstep_carpet_{i:03d}.ogg'),1800)
    a+=filtered(rng.normal(0,.005,len(a)),1100)*np.exp(-np.arange(len(a))/RATE*12)
    save(f'equipment_{i}',a,.18)
print('Built',len(list(OUT.glob('*.wav'))),'WAV assets')
