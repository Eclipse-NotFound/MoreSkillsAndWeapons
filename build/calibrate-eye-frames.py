"""Offline native-sprite eye audit. Never run image matching in the game.

Seeds are manually read from native PNGs, independent of MSWLaserEyes.
The generated review sheets must be inspected before emitting production data.
"""
from pathlib import Path
import argparse
import json
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
SEEDS = {
    'raider1':(86,47),'raider2':(88,47),'raider3':(92,50),'raider4':(90,51),
    'raider5':(88,44),'raider6':(88,46),'raider7':(90,50),'raider8':(89,49),'raider9':(88,48),
    'slaver1':(86,49),'slaver2':(90,49),'slaver3':(88,52),'slaver4':(92,51),'slaver5':(90,50),'slaver6':(91,50),
    'zebra1':(88,55),'zebra2':(89,56),'zebra3':(89,57),'zebra4':(90,55),'zebra5':(89,55),
    'ranger1':(94,62),'ranger2':(94,62),'ranger3':(94,62),
    'encl1':(91,51),'encl2':(91,50),'encl3':(91,51),'encl4':(91,50),'bossencl':(93,53),
    'alicorn1':(114,46),'alicorn2':(113,45),'alicorn3':(113,45),'bossalicorn':(125,64),
    'hellhound1':(128,62),'zombie0':(88,45),'zombie1':(88,46),'zombie2':(86,45),'zombie3':(87,46),
    'zombie4':(90,49),'zombie5':(88,52),'zombie6':(86,45),'zombie7':(86,45),'zombie8':(89,51),'zombie9':(89,57),
    'tarakan':(43,16),'rat':(59,12),'molerat':(70,24),'scorp1':(53,40),'scorp2':(54,41),'scorp3':(63,53),
    'ant1':(48,12),'ant2':(47,9),'ant3':(47,11),'protect':(84,39),'gutsy':(66,41),'eqd':(87,47),
    'protect1':(88,51),'gutsy1':(66,41),
}

def match(frame, templates, region):
    """RGB normalized correlation, rotations; no resolver coordinates as oracle."""
    x0,y0,x1,y1=map(int,region)
    x0=max(0,x0); y0=max(0,y0); x1=min(frame.width,x1); y1=min(frame.height,y1)
    radius=templates[0].shape[0]//2
    src=np.asarray(frame.convert('RGB'),dtype=np.float32)/255
    src=np.pad(src,((radius,radius),(radius,radius),(0,0)))
    src=src[y0:y1+radius*2,x0:x1+radius*2]
    windows=np.lib.stride_tricks.sliding_window_view(src,(2*radius+1,2*radius+1),axis=(0,1))
    sums=np.sum(windows,axis=(2,3,4)); sq=np.sum(windows*windows,axis=(2,3,4))
    n=3*(2*radius+1)**2; denom=np.sqrt(np.maximum(sq-sums*sums/n,1e-9))
    best=(-1,None)
    for template in templates:
        t=template.transpose(2,0,1); t=t-t.mean(); norm=np.sqrt(np.sum(t*t))
        if norm<1e-5:continue
        scores=np.einsum('ijcuv,cuv->ij',windows,t,optimize=False)/(denom*norm)
        y,x=np.unravel_index(np.argmax(scores),scores.shape);score=float(scores[y,x])
        if score>best[0]:best=(score,(int(x+x0),int(y+y0)))
    return best

def templates(frame, point, radius=7, rotation=60):
    x,y=point; patch=frame.crop((x-radius,y-radius,x+radius+1,y+radius+1)).convert('RGB')
    return [np.asarray(patch.rotate(a,Image.Resampling.BILINEAR),dtype=np.float32)/255 for a in range(-rotation,rotation+1,10)]

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--catalog',default='out/eye-audit-20260927/baseline');ap.add_argument('--only',default='');ap.add_argument('--retry-low',action='store_true');args=ap.parse_args()
    src=ROOT/args.catalog;out=src.parent/'calibration';out.mkdir(exist_ok=True)
    assets=json.loads((src/'assets.json').read_text(encoding='utf-8-sig'))
    catalog={a['id']:a for a in json.loads((src/'catalog.json').read_text(encoding='utf-8-sig'))}
    result=json.loads((out/'matches.json').read_text()) if (args.only or args.retry_low) and (out/'matches.json').exists() else {};low=[]
    for spec in assets:
        key=spec['id']
        if key not in SEEDS or (args.only and key not in args.only.split(',')):continue
        img=Image.open(src/(spec['asset']+'.png')).convert('RGBA'); w,h=spec['width'],spec['height']
        first=img.crop((0,0,w,h));seed=SEEDS[key];ts=templates(first,seed,rotation=180 if args.retry_low else 60)
        rows={}
        for a in spec['anims']:
            if a['state'] not in ('die','death','fall'):rows[a['row']]=max(rows.get(a['row'],0),a['length'])
        points={};tiles=[]
        for row,count in sorted(rows.items()):
            poses=[]
            for f in range(count):
                frame=img.crop((f*w,row*h,(f+1)*w,(row+1)*h))
                if frame.getbbox() is None:poses.append(None);continue
                # Head may dive or emerge from the floor; use the whole height.
                previous=result.get(key,{}).get('rows',{}).get(str(row),[])
                old=previous[f] if f<len(previous) else None
                if args.retry_low and old is not None and old[2]>=.70:point=old[:2];score=old[2]
                else:score,point=match(frame,ts,(max(0,seed[0]-45),0,min(w,seed[0]+40),h))
                if row==0 and f==0:point=seed;score=1
                poses.append([*point,round(score,4)])
                if score<.70:low.append([key,row,f,point,round(score,3)])
                scale=2;t=Image.new('RGB',(w*scale,h*scale+18),'#33404c');scaled=frame.resize((w*scale,h*scale),Image.Resampling.NEAREST);t.paste(scaled,(0,0),scaled)
                d=ImageDraw.Draw(t);x,y=point;d.ellipse((x*scale-3,y*scale-3,x*scale+3,y*scale+3),outline='#00FFFF');d.text((3,h*scale),f'r{row} f{f} {score:.2f}',fill='white');tiles.append(t)
            points[row]=poses
        result[key]={'asset':spec['asset'],'rows':points}
        cols=8;tw,th=w*2,h*2+18;sheet=Image.new('RGB',(cols*tw,((len(tiles)+cols-1)//cols)*th),'#33404c')
        for i,t in enumerate(tiles):sheet.paste(t,(i%cols*tw,i//cols*th))
        sheet.save(out/(key+'.png'));print(key,sum(len(v) for v in points.values()),flush=True)
    (out/'matches.json').write_text(json.dumps(result,separators=(',',':')),encoding='utf-8')
    (out/'low-confidence.json').write_text(json.dumps(low,indent=2),encoding='utf-8');print('low confidence',len(low))

if __name__=='__main__':main()
