/* Original procedural assets. Shared PBR materials and batched detail geometry. */
(() => {
 'use strict';
 const T=THREE,V=T.Vector3,cache=new Map(),textures=new Map();
 function texture(kind){
  if(textures.has(kind))return textures.get(kind);
  const c=document.createElement('canvas');c.width=c.height=512;const x=c.getContext('2d'),r=GameData.rng(928+kind.length*37);
  x.fillStyle=kind==='brick'?'#d3c9bc':kind==='wood'?'#b5a591':kind==='rubber'?'#858b87':kind==='paint'?'#c5c9c0':'#d7dad4';x.fillRect(0,0,512,512);
  for(let i=0;i<14000;i++){const v=40+Math.floor(r()*200);x.fillStyle=`rgba(${v},${v},${v},${.035+r()*(kind==='paint'?.1:.18)})`;x.fillRect(r()*512,r()*512,1+r()*3,kind==='wood'?3+r()*35:1+r()*3);}
  if(kind==='paint'||kind==='steel'){
   for(let i=0;i<115;i++){const px=r()*512,py=r()*512,len=6+r()*48;x.strokeStyle=`rgba(${kind==='paint'?'55,48,39':'235,238,231'},${.12+r()*.34})`;x.lineWidth=.45+r()*1.25;x.beginPath();x.moveTo(px,py);x.lineTo(px+len,py+(r()-.5)*5);x.stroke();if(i%9===0){x.fillStyle='rgba(76,58,39,.25)';x.beginPath();x.arc(px,py,1+r()*3,0,Math.PI*2);x.fill();}}
   x.strokeStyle='rgba(36,42,39,.18)';x.lineWidth=2;for(let y=0;y<512;y+=128){x.beginPath();x.moveTo(0,y);x.lineTo(512,y);x.stroke();}
  }
  if(kind==='brick'){x.strokeStyle='#4b514c';x.lineWidth=3;for(let y=0;y<512;y+=32){x.beginPath();x.moveTo(0,y);x.lineTo(512,y);x.stroke();for(let a=(y%64?32:0);a<512;a+=64){x.beginPath();x.moveTo(a,y);x.lineTo(a,y+32);x.stroke();}}}
  if(kind==='steel'){for(let i=0;i<95;i++){x.strokeStyle=`rgba(35,30,22,${.15+r()*.25})`;x.lineWidth=1;x.beginPath();const a=r()*512,b=r()*512;x.moveTo(a,b);x.lineTo(a+r()*28,b+r()*4);x.stroke();}}
  if(kind==='rock'){
   for(let y=-16;y<530;y+=17){x.strokeStyle='rgba(65,58,47,.27)';x.lineWidth=2+r()*4;x.beginPath();for(let a=0;a<=512;a+=8){const b=y+Math.sin(a*.025+y)*5;a?x.lineTo(a,b):x.moveTo(a,b);}x.stroke();}
   for(let i=0;i<70;i++){const a=r()*512,b=r()*512;x.strokeStyle='rgba(43,40,35,.2)';x.lineWidth=1;x.beginPath();x.moveTo(a,b);x.lineTo(a+8,b+24);x.lineTo(a+4,b+44);x.stroke();}
  }
  if(kind==='road'){
   for(let i=0;i<4500;i++){x.fillStyle=i%2?'rgba(35,32,27,.18)':'rgba(250,241,220,.22)';x.beginPath();x.arc(r()*512,r()*512,1+r()*2,0,Math.PI*2);x.fill();}
  }
  if(kind==='ice'){
   x.fillStyle='rgba(112,156,177,.3)';x.fillRect(0,0,512,512);
   for(let i=0;i<24;i++){let a=r()*512,b=r()*512;x.strokeStyle='rgba(246,253,255,.55)';x.lineWidth=1+r();x.beginPath();x.moveTo(a,b);for(let j=0;j<5;j++){a+=(r()-.45)*70;b+=(r()-.35)*70;x.lineTo(a,b);}x.stroke();}
  }
  // Broad wear under the fine grain keeps materials legible at gameplay distance.
  for(let i=0;i<90;i++){const px=r()*512,py=r()*512,radius=8+r()*55;x.fillStyle=`rgba(${kind==='paint'?'64,57,40':'55,54,46'},${.02+r()*.07})`;x.beginPath();x.ellipse(px,py,radius,radius*.45,r()*6,0,Math.PI*2);x.fill();}
  if(kind==='wood'){for(let i=0;i<130;i++){const px=r()*512;x.strokeStyle=`rgba(42,35,26,${.1+r()*.3})`;x.lineWidth=.6+r()*3;x.beginPath();x.moveTo(px,0);x.bezierCurveTo(px+14,170,px-12,330,px,512);x.stroke();}}
  if(kind==='rock'){for(let i=0;i<45;i++){x.strokeStyle='rgba(44,43,37,.22)';x.lineWidth=.7+r()*2;x.beginPath();const a=r()*512,b=r()*512;x.moveTo(a,b);x.lineTo(a+18+r()*70,b+20);x.lineTo(a+60,b+70+r()*50);x.stroke();}}
  if(kind==='rubber'){x.strokeStyle='#3e423c';x.lineWidth=3;for(let y=0;y<512;y+=18){x.beginPath();x.moveTo(0,y);x.lineTo(512,y+7);x.stroke();}}
  const t=new T.CanvasTexture(c);t.wrapS=t.wrapT=T.RepeatWrapping;t.colorSpace=T.SRGBColorSpace;t.anisotropy=8;textures.set(kind,t);return t;
 }
 function material(color,kind='steel'){
  const key=color+kind;if(cache.has(key))return cache.get(key);
  const map=texture(kind),relief=map.clone();relief.colorSpace=T.NoColorSpace;
  const m=new T.MeshStandardMaterial({color,map,bumpMap:relief,roughnessMap:relief,bumpScale:kind==='brick'?.09:kind==='rock'?.2:kind==='wood'?.09:kind==='paint'?.018:.026,roughness:kind==='rubber'?1:kind==='steel'?.72:kind==='paint'?.92:1,metalness:kind==='steel'?.65:kind==='paint'?.08:.01,envMapIntensity:.55,transparent:false,opacity:1,depthWrite:true,depthTest:true});cache.set(key,m);return m;
 }
 const cube=new T.BoxGeometry(1,1,1),boltGeo=new T.CylinderGeometry(.035,.035,.025,6);
 function mesh(g,m,p,x=0,y=0,z=0){const o=new T.Mesh(g,m);o.position.set(x,y,z);o.castShadow=o.receiveShadow=true;p.add(o);return o;}
 function box(p,w,h,d,x,y,z,m){const o=mesh(cube,m,p,x,y,z);o.scale.set(w,h,d);return o;}
 function cylinder(p,a,b,h,x,y,z,m,n=32){return mesh(new T.CylinderGeometry(a,b,h,n),m,p,x,y,z);}
 function plate(p,w,h,d,x,y,z,m,bevel=.08){const shape=new T.Shape(),a=w/2,b=d/2,k=Math.min(bevel,w/5,d/5);shape.moveTo(-a+k,-b);shape.lineTo(a-k,-b);shape.lineTo(a,-b+k);shape.lineTo(a,b-k);shape.lineTo(a-k,b);shape.lineTo(-a+k,b);shape.lineTo(-a,b-k);shape.lineTo(-a,-b+k);shape.closePath();const g=new T.ExtrudeGeometry(shape,{depth:h,bevelEnabled:true,bevelSize:k*.4,bevelThickness:k*.4,bevelSegments:2,steps:1});g.rotateX(-Math.PI/2);g.translate(0,-h/2,0);return mesh(g,m,p,x,y,z);}
 function batch(parent,exclude=[],recursive=false){parent.updateMatrixWorld(true);const groups=new Map(),inv=parent.matrixWorld.clone().invert(),objects=[];if(recursive)parent.traverse(o=>{if(o.isMesh)objects.push(o);});else objects.push(...parent.children);for(const o of objects){if(!o.isMesh||exclude.includes(o)||o.material.transparent||o.material.opacity<1||o.material.customProgramCacheKey?.().startsWith('terrain'))continue;const key=o.material.uuid+'|'+(o.userData.zone||'')+'|'+o.castShadow;if(!groups.has(key))groups.set(key,[]);groups.get(key).push(o);}for(const list of groups.values()){if(list.length<2)continue;const arrays={position:[],normal:[],uv:[]};for(const o of list){const g=o.geometry.index?o.geometry.toNonIndexed():o.geometry.clone();g.applyMatrix4(new T.Matrix4().multiplyMatrices(inv,o.matrixWorld));for(const k of Object.keys(arrays))if(g.attributes[k])g.attributes[k].array.forEach(value=>arrays[k].push(value));else if(k==='uv')for(let j=0;j<g.attributes.position.count*2;j++)arrays.uv.push(0);g.dispose();}const g=new T.BufferGeometry();for(const k of Object.keys(arrays))g.setAttribute(k,new T.Float32BufferAttribute(arrays[k],k==='uv'?2:3));const o=mesh(g,list[0].material,parent);o.userData={...list[0].userData};o.castShadow=list[0].castShadow;list.forEach(v=>v.parent.remove(v));}}
 // Each vehicle has its own proportions, turret construction and running gear.
 const designs={
  '0-0':{w:2.45,l:4.3,h:.38,slope:.3,wheels:5,skirts:0,gun:2.35,z:.38,shape:'scout'},
  // Fictional vehicles, with readable engineering cues from the T-34-85,
  // IS-3, Panther and production-turret Tiger II rather than copied assets.
  '0-1':{w:2.95,l:5.45,h:.46,slope:.34,wheels:5,skirts:0,gun:3.45,z:.25,shape:'cast'},
  '0-2':{w:3.48,l:6.7,h:.58,slope:.4,wheels:6,skirts:4,gun:4.55,z:.08,shape:'pike'},
  '1-0':{w:2.6,l:4.65,h:.58,slope:.06,wheels:6,skirts:0,gun:2.7,z:.2,shape:'polygon'},
  '1-1':{w:3.2,l:6.25,h:.58,slope:.38,wheels:6,skirts:5,gun:4.25,z:-.18,shape:'wedge'},
  '1-2':{w:3.76,l:7.25,h:.78,slope:.29,wheels:9,skirts:6,gun:4.9,z:.12,shape:'box'},
  '2-0':{w:2.35,l:4.5,h:.35,slope:.25,wheels:4,skirts:0,gun:3.1,z:-.35,shape:'oscillating'},
  '2-1':{w:2.95,l:5.65,h:.46,slope:.22,wheels:6,skirts:2,gun:3.9,z:-.25,shape:'bustle'},
  '2-2':{w:3.45,l:6.9,h:.7,slope:.09,wheels:8,skirts:6,gun:3.45,z:.48,shape:'fortress'}
 };
 Object.assign(designs,{
  '0-3':{w:3.2,l:6.5,h:.5,slope:.3,wheels:6,skirts:0,gun:4.8,z:.3,shape:'assault'},
  '1-3':{w:3.05,l:6.2,h:.48,slope:.2,wheels:8,skirts:3,gun:5.2,z:-.3,shape:'howitzer'},
  '2-3':{w:2.9,l:5.9,h:.4,slope:.35,wheels:5,skirts:0,gun:4.6,z:-.6,shape:'artillery'}
 });
 function tank(spec,team=0){
  const group=new T.Group(),turret=new T.Group(),gunPivot=new T.Group(),wheels=[],hitMeshes=[],trackBelts=[];
  const design=designs[spec.id]||designs[`${spec.n}-${spec.c}`],width=design.w,length=design.l,paint=material(spec.color,'paint'),dark=material(0x303839),steel=material(0x69716a),rubber=material(0x252927,'rubber'),rust=material(0x70614a,'paint'),glass=new T.MeshStandardMaterial({color:0x284650,metalness:.75,roughness:.13});
  const hull=plate(group,width,.69,length,0,1.01,0,paint,.24);hull.userData.zone='hull';
  const upper=plate(group,width*.91,design.h,length*.69,0,1.43,-length*.08,paint,design.shape==='box'?.06:.27);upper.userData.zone='hull';
  // Only the glacis is inclined. Rotating the entire four-to-five metre upper
  // hull created the giant rectangular slab that used to cover the turret.
  const nose=box(group,width*.9,.14,1.58,0,1.5,length*.32,paint);nose.rotation.x=.38+design.slope*.22;nose.userData.zone='hull';
  const belly=box(group,width*.88,.35,.16,0,.85,length*.5,paint);belly.rotation.x=-.32;belly.userData.zone='hull';
  for(const s of [-1,1]){
   const sx=s*width*.5;
   for(let j=0;j<design.wheels;j++){const z=-length*.39+j*length*.78/(design.wheels-1),wheel=new T.Group();wheel.position.set(s*(width*.5+.05),.64,z);group.add(wheel);const radius=design.wheels<=5?.49:design.wheels>=8?.38:.44;wheel.userData.radius=radius;const tyre=cylinder(wheel,radius,radius,.49,0,0,0,rubber);tyre.rotation.z=Math.PI/2;const rim=cylinder(wheel,radius*.75,radius*.75,.52,0,0,0,paint);rim.rotation.z=Math.PI/2;const hub=cylinder(wheel,.105,.105,.57,0,0,0,steel);hub.rotation.z=Math.PI/2;for(let n=0;n<6;n++){const a=n*Math.PI/3,b=mesh(boltGeo,steel,wheel,s*.29,Math.sin(a)*.23,Math.cos(a)*.23);b.rotation.z=Math.PI/2;}batch(wheel);wheels.push(wheel);}
   const beltGroup=new T.Group();group.add(beltGroup);
   const links=new T.InstancedMesh(new T.BoxGeometry(.68,.095,.22),dark,72),cleats=new T.InstancedMesh(new T.BoxGeometry(.53,.03,.06),steel,72);
   for(const o of [links,cleats]){o.castShadow=o.receiveShadow=true;o.frustumCulled=false;o.userData.zone='tracks';beltGroup.add(o);}
   trackBelts.push({side:s,x:sx,phase:0,links,cleats});
   plate(group,.87,.1,length+.42,sx,1.3,0,paint,.06);
   for(let j=0;j<design.skirts;j++){const z=-length*.4+(j+.5)*length*.8/design.skirts,skirt=plate(group,.08,design.shape==='fortress'?.85:.48,length*.76/design.skirts,s*(width*.5+.43),1.08,z,paint,.015);skirt.userData.zone='tracks';for(let k of [-.28,.28]){const b=mesh(boltGeo,steel,group,s*(width*.5+.49),1.25,z+k);b.rotation.z=Math.PI/2;}}
   for(let j=0;j<3;j++)plate(group,.5,.28,.63,sx,1.5,-length*.26+j*.72,paint,.035);
   const tow=new T.Mesh(new T.TorusGeometry(.13,.04,8,20),steel);tow.position.set(s*width*.33,.95,length*.51);group.add(tow);
   const lamp=cylinder(group,.125,.125,.14,s*width*.34,1.54,length*.4,steel);lamp.rotation.x=Math.PI/2;const lens=cylinder(group,.095,.095,.015,s*width*.34,1.54,length*.4+.08,new T.MeshStandardMaterial({color:0xf8deb0,emissive:0xd9b36b,emissiveIntensity:.6}));lens.rotation.x=Math.PI/2;
  }
  for(let j=0;j<14;j++)box(group,width*.48,.035,.04,0,1.79,-length*.36+j*.065,dark);
  for(let j=0;j<2;j++){const pipe=cylinder(group,.105,.105,.9,(j?1:-1)*width*.3,1.36,-length*.5,steel);pipe.rotation.x=Math.PI/2;const cap=cylinder(group,.08,.08,.01,(j?1:-1)*width*.3,1.36,-length*.58,rubber);cap.rotation.x=Math.PI/2;}
  const cableCurve=new T.CatmullRomCurve3([new V(-width*.34,1.83,-length*.25),new V(-width*.42,1.86,-length*.36),new V(0,1.85,-length*.4),new V(width*.4,1.82,-length*.28)]);mesh(new T.TubeGeometry(cableCurve,32,.026,6,false),steel,group);
  const shovel=box(group,.1,.065,1.3,width*.32,1.86,-.75,rust);const spade=plate(group,.25,.04,.35,width*.32,1.87,-1.47,dark,.04);
  turret.position.set(0,1.77,design.z);group.add(turret);cylinder(turret,width*.32,width*.33,.16,0,0,0,dark,48);
  let shell;
  switch(design.shape){
   case 'assault': shell=plate(turret,2.65,1.1,3.1,0,.42,-.25,paint,.35);shell.rotation.x=-.08;for(const s of [-1,1]){plate(turret,.12,.8,2.4,s*1.3,.35,-.25,paint,.06);const drum=cylinder(group,.3,.3,1.4,s*1.35,1.75,-2.3,rust);drum.rotation.x=Math.PI/2;}break;
   case 'howitzer': shell=plate(turret,2.35,1.35,2.3,0,.5,-.7,paint,.12);for(const s of [-1,1]){plate(turret,.12,1.3,2.5,s*1.2,.55,-.7,paint,.06);for(let j=0;j<5;j++){cylinder(turret,.08,.09,.65,s*.9,.9,-1.4+j*.22,rust,12);}}break;
   case 'artillery': shell=plate(turret,2.2,1.05,2.8,0,.52,-.65,paint,.4);for(const s of [-1,1]){const recoil=cylinder(turret,.11,.11,1.7,s*.35,.5,1.2,steel,16);recoil.rotation.x=Math.PI/2;plate(group,.6,.16,1.4,s*1.1,1.5,-2.5,steel,.04);}break;
   case 'scout': shell=cylinder(turret,.61,.85,.82,0,.4,0,paint,12);break;
   case 'cast': shell=mesh(new T.SphereGeometry(1,40,22),paint,turret,0,.35,-.12);shell.scale.set(width*.37,.55,1.25);break;
   case 'pike': shell=mesh(new T.SphereGeometry(1,40,22),paint,turret,0,.27,-.18);shell.scale.set(1.46,.58,1.34);for(const s of [-1,1]){const cheek=plate(group,width*.45,.14,1.55,s*width*.225,1.54,length*.335,paint,.08);cheek.rotation.set(.27,s*.2,s*.04);cheek.userData.zone='hull';}break;
   case 'polygon': shell=cylinder(turret,.82,1,.9,0,.43,-.1,paint,6);break;
   case 'wedge': shell=plate(turret,2.25,.85,2.7,0,.4,-.25,paint,.42);shell.rotation.x=-.2;break;
   case 'box': shell=plate(turret,2.75,1.05,2.8,0,.48,-.2,paint,.05);break;
   case 'oscillating': shell=plate(turret,1.45,.48,1.9,0,.63,-.12,paint,.3);shell.rotation.x=-.16;for(const s of [-1,1]){const pivot=cylinder(turret,.27,.27,.18,s*.75,.5,0,steel,24);pivot.rotation.z=Math.PI/2;}break;
   case 'bustle': shell=plate(turret,2.05,.72,2.2,0,.44,.02,paint,.35);plate(turret,1.85,.68,1.45,0,.52,-1.35,paint,.16).userData.zone='turret';break;
   case 'fortress': shell=cylinder(turret,1.1,1.4,1.05,0,.5,-.1,paint,10);plate(turret,2.25,.5,1.1,0,.37,-1.25,paint,.12).userData.zone='turret';break;
  }shell.userData.zone='turret';
  if(spec.c===3){
   const roofY=design.shape==='howitzer'?1.23:1.03;
   cylinder(turret,.32,.35,.1,-.48,roofY,-.65,paint,32);
   box(turret,.23,.08,.07,-.48,roofY+.09,-.65,steel);
   for(const side of [-1,1]){
    for(let j=0;j<7;j++){const bolt=mesh(boltGeo,steel,turret,side*1.12,.85,-1.45+j*.35);bolt.rotation.z=Math.PI/2;}
    const rail=new T.Mesh(new T.TubeGeometry(new T.CatmullRomCurve3([new V(side*1.16,.72,-1.2),new V(side*1.28,.85,-.9),new V(side*1.28,.85,.3),new V(side*1.16,.72,.55)]),16,.025,6,false),steel);turret.add(rail);
    for(let j=0;j<3;j++)box(turret,.14,.3,.23,side*1.19,.3,-1+j*.29,dark);
   }
   const collar=cylinder(turret,.33,.4,.35,0,.45,1.35,steel,32);collar.rotation.x=Math.PI/2;
  }
  const roof=plate(turret,width*.49,.08,length*.26,0,.84,-.14,paint,.14);roof.userData.zone='roof';
  cylinder(turret,.31,.34,.13,-.35,.93,-.29,paint,40);cylinder(turret,.23,.23,.07,-.35,1.03,-.29,steel,32);box(turret,.21,.04,.035,-.35,1.09,-.29,dark);
  for(let j=0;j<5;j++){const a=j*Math.PI*2/5;box(turret,.1,.06,.07,-.35+Math.sin(a)*.25,1.04,-.29+Math.cos(a)*.25,glass);}
  for(let s of [-1,1]){for(let j=0;j<4;j++){const tube=cylinder(turret,.063,.063,.28,s*width*.34,.52,-.3+j*.16,dark,16);tube.rotation.z=s*.55;}const rail=new T.Mesh(new T.TorusGeometry(.13,.015,6,16,Math.PI),steel);rail.rotation.y=Math.PI/2;rail.position.set(s*width*.37,.51,.05);turret.add(rail);for(let j=0;j<4;j++){const b=mesh(boltGeo,steel,turret,s*width*.29,.81,-.52+j*.29);}}
  const antenna=cylinder(turret,.009,.018,1.55,width*.22,1.38,-.62,dark,8);antenna.rotation.z=-.1;cylinder(turret,.05,.07,.18,width*.22,.83,-.62,rubber,12);
  const coax=cylinder(turret,.035,.045,.4,.43,.43,.87,dark,16);coax.rotation.x=Math.PI/2;
  gunPivot.position.set(0,.37,.63);turret.add(gunPivot);let mantle;
  if(design.shape==='cast'||design.shape==='pike'){
   mantle=cylinder(gunPivot,.42+spec.c*.05,.5+spec.c*.05,.24,0,0,.14,paint,40);mantle.rotation.x=Math.PI/2;mantle.scale.y=.82;
  }else if(design.shape==='wedge'){
   mantle=cylinder(gunPivot,.4,.55,.22,0,0,.14,paint,28);mantle.rotation.x=Math.PI/2;mantle.scale.x=1.28;
  }else{
   mantle=plate(gunPivot,.72+spec.c*.08,.42+spec.c*.04,.24,0,0,.14,paint,.055);
  }
  mantle.userData.zone='turret';
  const barrelLength=design.gun;for(let j=0;j<3;j++){const len=barrelLength/3,r=.112+spec.c*.023+(2-j)*.015,barrel=cylinder(gunPivot,r,r+.012,len,0,0,.37+len*(j+.5),steel,32);barrel.rotation.x=Math.PI/2;}
  for(let z of [.6,barrelLength*.55,barrelLength*.8]){const collar=cylinder(gunPivot,.165+spec.c*.018,.165+spec.c*.018,.09,0,0,z,dark,32);collar.rotation.x=Math.PI/2;}
  let muzzleEnd=barrelLength+.42;
  if(spec.c===2){const brake=cylinder(gunPivot,.19,.19,.48,0,0,barrelLength+.27,dark,28);brake.rotation.x=Math.PI/2;for(const x of [-.12,.12])box(gunPivot,.11,.13,.16,x,0,barrelLength+.27,rubber);muzzleEnd=barrelLength+.52;}
  else{const endCollar=cylinder(gunPivot,.13,.145,.12,0,0,barrelLength+.38,dark,28);endCollar.rotation.x=Math.PI/2;}
  const bore=cylinder(gunPivot,.092+spec.c*.02,.092+spec.c*.02,.012,0,0,muzzleEnd,rubber,24);bore.rotation.x=Math.PI/2;
  const decal=document.createElement('canvas');decal.width=256;decal.height=128;const dc=decal.getContext('2d');dc.fillStyle='#e5e3d1';dc.font='bold 72px sans-serif';dc.textAlign='center';dc.fillText(`${spec.n+1}${spec.c+1}7`,128,87);const dt=new T.CanvasTexture(decal),dm=new T.MeshBasicMaterial({map:dt,transparent:true,depthWrite:false,polygonOffset:true,polygonOffsetFactor:-2});for(let side of [-1,1]){const marking=mesh(new T.PlaneGeometry(.69,.34),dm,turret,side*width*.365,.46,-.18);marking.rotation.y=side*Math.PI/2;marking.castShadow=false;}
  // Signature equipment remains attached to the appropriate rotating assembly.
  if(design.shape==='scout'){box(group,1.2,.3,.6,0,1.9,-1.45,rust);}
  if(design.shape==='cast'||design.shape==='pike')for(const s of [-1,1]){const drum=cylinder(group,.27,.27,1.3,s*width*.4,1.75,-length*.34,rust);drum.rotation.x=Math.PI/2;}
  if(design.shape==='polygon'){const frame=new T.Mesh(new T.TorusGeometry(.95,.025,6,24),steel);frame.rotation.x=Math.PI/2;frame.position.y=1.35;turret.add(frame);for(const s of [-1,1])box(turret,.035,.5,.035,s*.8,1.1,0,steel);}
  if(design.shape==='wedge')for(const s of [-1,1])for(let j=0;j<5;j++)box(turret,.12,.26,.24,s*1.12,.63,-.6+j*.28,dark);
  if(design.shape==='box'){for(const s of [-1,1]){cylinder(group,.17,.2,1.25,s*.8,1.8,-length*.48,rust);box(turret,.15,.65,1.45,s*1.42,.45,-.25,dark);}}
  if(design.shape==='oscillating'){for(const s of [-1,1])plate(turret,.46,.48,1.25,s*.52,.66,-1.12,paint,.18);}
  if(design.shape==='bustle'){for(let j=0;j<6;j++)box(turret,.045,.5,.04,-.88+j*.35,.78,-2.08,steel);box(turret,1.85,.04,.55,0,.52,-1.85,steel);}
  if(design.shape==='fortress'){plate(group,1.55,.5,1.2,0,2,-length*.33,paint,.2);for(const s of [-1,1])box(group,.32,.35,length*.65,s*width*.45,1.74,0,steel);}
  // Национальные силуэты для средних и тяжёлых машин: они намеренно не
  // используют один набор декора, чтобы танки читались даже издалека.
  if(spec.id==='0-1'){
   const cupola=cylinder(turret,.31,.4,.27,-.42,1.03,-.34,paint,36);for(let i=0;i<6;i++){const a=i*Math.PI/3;box(turret,.1,.09,.035,-.42+Math.sin(a)*.33,1.1,-.34+Math.cos(a)*.33,glass);}
   for(const s of [-1,1]){const drum=cylinder(group,.3,.3,1.45,s*width*.38,1.55,-length*.43,rust,24);drum.rotation.x=Math.PI/2;for(const z of [-.42,.42]){const band=mesh(new T.TorusGeometry(.305,.025,6,24),steel,group,s*width*.38,1.55,-length*.43+z);band.rotation.x=Math.PI/2;}}
   const log=cylinder(group,.12,.16,2.4,-width*.46,1.35,-.35,material(0x5b4634,'wood'),14);log.rotation.z=Math.PI/2;
  }
  if(spec.id==='0-2'){
   const collar=cylinder(gunPivot,.42,.5,.5,0,0,.18,paint,40);collar.rotation.x=Math.PI/2;const search=cylinder(turret,.26,.26,.24,.78,.68,.55,dark,24);search.rotation.x=Math.PI/2;const lens=cylinder(turret,.22,.22,.03,.78,.68,.69,new T.MeshStandardMaterial({color:0xffe1a4,emissive:0xd5a95d,emissiveIntensity:.45,roughness:.25}),24);lens.rotation.x=Math.PI/2;
   plate(group,width*.42,.18,1.5,0,1.82,length*.27,paint,.03);for(let j=0;j<5;j++)box(group,.42,.1,.22,(j-2)*.46,1.93,length*.27,dark);
   for(const s of [-1,1]){const eye=mesh(new T.TorusGeometry(.21,.05,8,20),steel,group,s*width*.3,1.2,length*.52);eye.rotation.x=Math.PI/2;}
  }
  if(spec.id==='1-1'){
   const bin=plate(turret,2.15,.58,.82,0,.48,-1.72,paint,.08);bin.userData.zone='turretRear';for(let j=0;j<5;j++)box(turret,.04,.46,.06,-.84+j*.42,.5,-2.16,steel);
   cylinder(turret,.36,.43,.32,.48,1.08,-.32,paint,16);for(let i=0;i<7;i++){const a=i*Math.PI*2/7;box(turret,.09,.11,.03,.48+Math.sin(a)*.37,1.16,-.32+Math.cos(a)*.37,glass);}
   for(const s of [-1,1])for(let j=0;j<3;j++){const plateZ=-length*.25+j*length*.25;plate(group,.1,.7,length*.2,s*(width*.5+.49),1.03,plateZ,paint,.02);}
   // Panther-like interleaved running gear: the inner row fills the large
   // gaps without multiplying track-link draw calls.
   for(const s of [-1,1])for(let j=0;j<5;j++){const z=-length*.31+j*length*.62/4,wheel=cylinder(group,.35,.35,.15,s*(width*.5+.2),.68,z,paint,20);wheel.rotation.z=Math.PI/2;}
  }
  if(spec.id==='1-2'){
   plate(turret,2.9,.74,.34,0,.46,1.24,paint,.025).userData.zone='turret';cylinder(turret,.43,.5,.42,.62,1.2,-.35,paint,12);cylinder(turret,.3,.34,.08,.62,1.46,-.35,steel,24);
   for(const s of [-1,1]){const exhaust=cylinder(group,.16,.2,1.55,s*.78,2,-length*.45,rust,16);exhaust.rotation.x=.08;box(turret,.28,.72,1.65,s*1.5,.48,-.28,dark);for(let j=0;j<4;j++)box(group,.5,.12,.28,s*(width*.5+.48),1.25,-1.7+j*1.08,dark);}
   const rearRack=box(group,2.5,.08,.72,0,2,-length*.5,steel);for(let j=-2;j<=2;j++)box(group,.04,.48,.7,j*.58,2.18,-length*.5,steel);
  }
  // Service fittings, suspension and armor seams, batched with the main model.
  for(const s of [-1,1]){
   for(let j=0;j<design.wheels;j++){
    const z=-length*.39+j*length*.78/(design.wheels-1);
    const arm=box(group,.1,.14,.54,s*width*.47,.65,z,steel);arm.rotation.x=s*.42;
    const spring=cylinder(group,.085,.085,.48,s*width*.45,.94,z,dark,10);spring.rotation.x=.35;
   }
   for(let j=0;j<3;j++){
    const z=-length*.25+j*.52;
    box(group,.035,.025,.4,s*width*.455,1.8,z,steel);
    box(group,.16,.055,.055,s*width*.37,1.85,z,rust);
   }
   // Lifting eyes and front towing shackles.
   for(const z of [-.65,.55]){const eye=mesh(new T.TorusGeometry(.09,.022,6,12),steel,turret,s*width*.24,.88,z);eye.rotation.x=Math.PI/2;}
   const shackle=mesh(new T.TorusGeometry(.15,.045,8,16),rust,group,s*width*.32,.7,length*.51);shackle.rotation.y=.2*s;
   const guard=box(group,.04,.27,.3,s*width*.34,1.67,length*.4,steel);
   box(group,.25,.035,.3,guard.position.x,1.81,guard.position.z,steel);
  }
  const deckY=1.5+design.h/2;
  for(const s of [-1,1]){
   plate(group,width*.25,.04,.85,s*width*.17,deckY+.05,-length*.29,paint,.03);
   for(let j=0;j<8;j++)box(group,width*.22,.035,.035,s*width*.17,deckY+.085,-length*.35+j*.095,dark);
  }
  // Spare track links and their mounting clamps vary with the vehicle.
  for(let j=0;j<3+spec.c;j++){
   const x=(j-(2+spec.c)/2)*.31;
   box(group,.27,.09,.42,x,1.65,length*.3,dark);
   box(group,.21,.04,.07,x,1.71,length*.3,steel);
  }
  const hatch=plate(turret,.55,.055,.5,.38,.94,-.22,paint,.07);hatch.userData.zone='roof';
  for(const x of [.2,.55])box(turret,.12,.06,.07,x,1,-.45,steel);
  box(turret,.22,.065,.05,.38,1.01,-.12,steel);
  const sight=plate(turret,.27,.14,.18,.36,1.03,.37,dark,.025);sight.userData.zone='roof';
  box(turret,.19,.07,.012,.36,1.06,.465,glass);
  if(spec.c===2){const mount=cylinder(turret,.055,.09,.4,.62,1.2,-.3,steel,12);const mg=box(turret,.13,.15,.42,.62,1.43,-.23,dark);const tube=cylinder(turret,.025,.035,.75,.62,1.45,.33,steel,12);tube.rotation.x=Math.PI/2;box(turret,.25,.2,.2,.82,1.42,-.25,rust);}
  group.userData.design=design.shape;
  batch(group,wheels);batch(turret);batch(gunPivot);group.traverse(o=>{if(o.isMesh&&!o.material.transparent){hitMeshes.push(o);o.userData.originalMaterial=o.material;}});
  // Closed collision meshes fill gaps between decorative parts. They follow
  // the hull and turret independently, and are never shown in the armor mask.
  const collisionMeshes=[],collisionMaterial=new T.MeshBasicMaterial({colorWrite:false,depthWrite:false,side:T.DoubleSide});
  function solid(parent,w,h,d,x,y,z,zone){const o=new T.Mesh(new T.BoxGeometry(w,h,d),collisionMaterial);o.position.set(x,y,z);o.userData.zone=zone;o.userData.collisionOnly=true;parent.add(o);collisionMeshes.push(o);}
  solid(group,width*.94,.92,length*.97,0,1,0,'hull');
  for(const s of [-1,1])solid(group,.68,1.13,length*.82+.9,s*width*.5,.65,0,'tracks');
  // Reuse the closed primary turret shell exactly, rather than an oversized box.
  const turretSolid=new T.Mesh(shell.geometry,collisionMaterial);turretSolid.position.copy(shell.position);turretSolid.rotation.copy(shell.rotation);turretSolid.scale.copy(shell.scale);turretSolid.userData={zone:'turret',collisionOnly:true};turret.add(turretSolid);collisionMeshes.push(turretSolid);
  hitMeshes.push(...collisionMeshes);
  const gunRecoil=new T.Group();for(const child of [...gunPivot.children])gunRecoil.add(child);gunPivot.add(gunRecoil);
  const model={group,turret,gunPivot,gunRecoil,barrelLength,wheels,hitMeshes,collisionMeshes,trackBelts,width,length,holes:[],effectClock:0,markClock:0};
  updateBelts(model,()=>0);return model;
 }
 function updateBelts(t,groundLocal){
  const straight=t.length*.82,r=.52,total=2*straight+2*Math.PI*r,dummy=new T.Object3D();
  for(const belt of t.trackBelts){
   for(let i=0;i<belt.links.count;i++){
    let q=((i/belt.links.count*total+belt.phase)%total+total)%total,z,y,a;
    if(q<straight){z=-straight/2+q;y=.13;a=0;}
    else if((q-=straight)<Math.PI*r){const angle=q/r;z=straight/2+r*Math.sin(angle);y=.65-r*Math.cos(angle);a=-angle;}
    else if((q-=Math.PI*r)<straight){z=straight/2-q;y=1.17;a=-Math.PI;}
    else{q-=straight;const angle=q/r;z=-straight/2-r*Math.sin(angle);y=.65+r*Math.cos(angle);a=-Math.PI-angle;}
    const deformation=T.MathUtils.clamp(groundLocal(belt.x,z),-.52,.52);
    y+=deformation*(y<.66?1:.35);
    if(y<.69)a=-Math.atan2(groundLocal(belt.x,z+.22)-groundLocal(belt.x,z-.22),.44);
    if(t.trackTime>0&&belt.side===t.brokenSide){y=.1+groundLocal(belt.x,z);a=0;z=(i/belt.links.count-.5)*total*.72;}
    dummy.position.set(belt.x,y,z);dummy.rotation.set(a,0,0);dummy.updateMatrix();belt.links.setMatrixAt(i,dummy.matrix);
    dummy.position.y+=.055*Math.cos(a);dummy.position.z+=.055*Math.sin(a);dummy.updateMatrix();belt.cleats.setMatrixAt(i,dummy.matrix);
   }
   belt.links.instanceMatrix.needsUpdate=belt.cleats.instanceMatrix.needsUpdate=true;
  }
 }
 function suspension(t,height,dt,distance=0){
  const p=t.group.position,yaw=t.yaw||0,c=Math.cos(yaw),s=Math.sin(yaw),h=(x,z)=>height(p.x+c*x+s*z,p.z-s*x+c*z);
  const samples=t.wheels.map(w=>h(w.position.x,w.position.z));
  const mean=samples.reduce((a,b)=>a+b,0)/samples.length;
  const targetY=Math.max(mean,Math.max(...samples)-.32);
  const half=t.length*.39,front=(h(-t.width/2,half)+h(t.width/2,half))/2,back=(h(-t.width/2,-half)+h(t.width/2,-half))/2;
  const right=(h(t.width/2,half)+h(t.width/2,-half))/2,left=(h(-t.width/2,half)+h(-t.width/2,-half))/2;
  if(!t.suspension)t.suspension={y:targetY,pitch:-Math.atan2(front-back,2*half),roll:Math.atan2(right-left,t.width),vy:0,vpitch:0,vroll:0,speed:t.speed||0,yaw};
  const state=t.suspension,step=Math.max(.001,Math.min(dt,.05)),mass=t.spec?.mass||32,omega=10*Math.sqrt(32/mass);
  const acceleration=T.MathUtils.clamp(((t.speed||0)-state.speed)/step,-4,4),dyaw=Math.atan2(Math.sin(yaw-state.yaw),Math.cos(yaw-state.yaw));
  const targetPitch=T.MathUtils.clamp(-Math.atan2(front-back,2*half)+acceleration*.008,-.55,.55);
  const targetRoll=T.MathUtils.clamp(Math.atan2(right-left,t.width)-(t.speed||0)*dyaw/step*.006,-.45,.45);
  function spring(key,target){const velocity='v'+key,offset=state[key]-target,k=state[velocity]+omega*offset,decay=Math.exp(-omega*step);state[key]=target+(offset+k*step)*decay;state[velocity]=(state[velocity]-omega*k*step)*decay;}
  GameData.verticalStep(state,targetY,mass,step);
  if(state.grounded){spring('pitch',targetPitch);spring('roll',targetRoll);}
  else{state.pitch=T.MathUtils.clamp(state.pitch+state.vpitch*step,-.7,.7);state.roll=T.MathUtils.clamp(state.roll+state.vroll*step,-.6,.6);state.vpitch*=Math.exp(-step*.2);state.vroll*=Math.exp(-step*.2);}
  p.y=state.y;t.group.rotation.order='YXZ';t.group.rotation.set(state.pitch,yaw,state.roll);t.group.updateMatrixWorld(true);
  const inverse=t.group.matrixWorld.clone().invert();
  const localGround=(x,z)=>new V(p.x+c*x+s*z,h(x,z),p.z-s*x+c*z).applyMatrix4(inverse).y;
  for(const w of t.wheels){const radius=w.userData.radius||.44,target=.13+radius+T.MathUtils.clamp(localGround(w.position.x,w.position.z),-.46,.46);w.position.y=T.MathUtils.lerp(w.position.y,target,1-Math.exp(-step*22));const side=Math.sign(w.position.x);w.rotation.x+=(distance+side*dyaw*t.width/2)/radius;}
  for(const belt of t.trackBelts)belt.phase-=distance+belt.side*dyaw*t.width/2;
  updateBelts(t,localGround);state.speed=t.speed||0;state.yaw=yaw;
 }
 function zone(hit,t){
  const tag=hit.object.userData.zone;if(tag==='tracks'||tag==='roof')return tag;
  let inTurret=tag==='turret';for(let p=hit.object.parent;p;p=p.parent)if(p===t.turret)inTurret=true;
  const frame=inTurret?t.turret:t.group;
  const n=hit.face.normal.clone().transformDirection(hit.object.matrixWorld).transformDirection(frame.matrixWorld.clone().invert());
  if(Math.abs(n.y)>.65)return 'roof';
  if(Math.abs(n.x)>Math.abs(n.z))return inTurret?'turretSide':'side';
  if(n.z<0)return inTurret?'turretRear':'rear';
  return inTurret?'turret':t.group.worldToLocal(hit.point.clone()).y<1.15?'lower':'front';
 }
 const armorDisplay=new T.MeshStandardMaterial({vertexColors:true,roughness:.7,metalness:.05});
 function armorMask(model,enabled,spec){
  model.group.updateMatrixWorld(true);
  model.hitMeshes.forEach(o=>{
   if(o.userData.collisionOnly)return;
   if(!enabled){o.material=o.userData.originalMaterial;if(o.userData.unmaskedGeometry){o.geometry.dispose();o.geometry=o.userData.unmaskedGeometry;delete o.userData.unmaskedGeometry;}return;}
   if(!o.userData.unmaskedGeometry){o.userData.unmaskedGeometry=o.geometry;o.geometry=o.geometry.index?o.geometry.toNonIndexed():o.geometry.clone();}
   const g=o.geometry,p=g.attributes.position,colors=new Float32Array(p.count*3);
   for(let i=0;i<p.count;i+=3){
    const a=new V().fromBufferAttribute(p,i),b=new V().fromBufferAttribute(p,i+1),c=new V().fromBufferAttribute(p,i+2),normal=b.clone().sub(a).cross(c.clone().sub(a)).normalize();
    const point=a.add(b).add(c).multiplyScalar(1/3).applyMatrix4(o.matrixWorld);
    const z=zone({object:o,point,face:{normal}},model),color=new T.Color(GameData.armorColor(GameData.armorThickness(spec,z)));
    for(let j=0;j<3;j++)color.toArray(colors,(i+j)*3);
   }
   g.setAttribute('color',new T.Float32BufferAttribute(colors,3));o.material=armorDisplay;
  });
 }
 const maskCache=new Map();function maskMaterial(c){if(!maskCache.has(c))maskCache.set(c,new T.MeshStandardMaterial({color:c,roughness:.55,metalness:.1,emissive:c,emissiveIntensity:.18}));return maskCache.get(c);}
 function terrainMaterial(kind,size){const m=new T.MeshStandardMaterial({color:kind==='winter'?0xcad5db:kind==='desert'?0xbca57a:0x6d8054,roughness:.97});m.onBeforeCompile=shader=>{shader.vertexShader=shader.vertexShader.replace('#include <common>','#include <common>\nvarying vec3 terrainPosition;').replace('#include <begin_vertex>','#include <begin_vertex>\nterrainPosition=position;');shader.fragmentShader=shader.fragmentShader.replace('#include <common>',`#include <common>
 varying vec3 terrainPosition;
 float hashT(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
 float noiseT(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hashT(i),hashT(i+vec2(1,0)),f.x),mix(hashT(i+vec2(0,1)),hashT(i+vec2(1)),f.x),f.y);}
 `).replace('#include <color_fragment>',`#include <color_fragment>
 vec2 tp=terrainPosition.xz;
 float broad=noiseT(tp*.035),fine=noiseT(tp*2.7),grain=noiseT(tp*18.);
 float dirt=smoothstep(.43,.7,noiseT(tp*.085));
 float road=1.-smoothstep(3.0,6.5,min(abs(tp.x),abs(tp.y)));
 vec3 earth=${kind==='desert'?'vec3(.64,.48,.29)':kind==='winter'?'vec3(.46,.48,.44)':'vec3(.35,.29,.18)'};
 diffuseColor.rgb=mix(diffuseColor.rgb,earth,clamp(road*.6+dirt*.22,0.,.7));
 diffuseColor.rgb*=.72+broad*.42+fine*.15+grain*.065;
 diffuseColor.rgb*=.94+noiseT(tp*.11)*.1;
 ${kind==='training'?`float patches=smoothstep(.35,.68,noiseT(tp*.047));
 diffuseColor.rgb=mix(diffuseColor.rgb*vec3(.68,.85,.48),diffuseColor.rgb*vec3(1.04,.85,.6),patches);
 float blades=step(.8,noiseT(tp*9.))*(1.-smoothstep(.2,.7,patches));diffuseColor.rgb*=1.-blades*.17;`:kind==='desert'?`float ripples=sin(tp.x*2.8+sin(tp.y*.3)*2.)*.5+.5;
 diffuseColor.rgb*=.87+ripples*.15;diffuseColor.rgb*=vec3(1.12,.91,.69);`:`float ice=smoothstep(.5,.75,noiseT(tp*.065));
 diffuseColor.rgb=mix(diffuseColor.rgb,vec3(.33,.43,.5),ice*.45);`}
 `);};m.customProgramCacheKey=()=>`terrain-${kind}`;return m;}
 function sky(scene,kind){const geo=new T.SphereGeometry(1800,32,20),mat=new T.ShaderMaterial({side:T.BackSide,depthWrite:false,uniforms:{top:{value:new T.Color(kind==='desert'?0x6d9cb3:kind==='winter'?0x687f97:0x487f9f)},bottom:{value:new T.Color(kind==='desert'?0xe6ceb1:0xd9e2df)}},vertexShader:'varying vec3 p;void main(){p=position;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);}',fragmentShader:'varying vec3 p;uniform vec3 top;uniform vec3 bottom;void main(){float h=pow(max(normalize(p).y,0.),.48);vec3 c=mix(bottom,top,h);float clouds=sin(p.x*.009+sin(p.z*.007))*sin(p.z*.005+p.x*.003);c=mix(c,vec3(.94,.94,.91),smoothstep(.55,.9,clouds)*smoothstep(.05,.25,h)*.26);gl_FragColor=vec4(c,1.);}'});scene.add(new T.Mesh(geo,mat));}
 function vegetation(world,arena,height,obstacles,quality='high'){
  const winter=arena===GameData.maps.winter,desert=arena===GameData.maps.desert,r=GameData.rng(arena.seed+8401),high=quality==='high';
  function atlas(kind){const key='plant-'+kind;if(textures.has(key))return textures.get(key);const c=document.createElement('canvas');c.width=c.height=256;const x=c.getContext('2d'),random=GameData.rng(927+kind.length);
   if(kind==='grass'){for(let i=0;i<65;i++){const a=random()*256,b=20+random()*180;x.strokeStyle=['#82964d','#667c39','#9eaa66','#b1ab71'][i%4];x.lineWidth=1+random()*3;x.beginPath();x.moveTo(a,256);x.quadraticCurveTo(a-12,180,a+(random()-.5)*90,b);x.stroke();}}
   else {for(let i=0;i<190;i++){const a=random()*256,b=random()*256;if(((a-128)/125)**2+((b-128)/120)**2>1)continue;x.fillStyle=['#4f6b34','#6c8441','#849951','#a0aa66'][i%4];x.beginPath();x.ellipse(a,b,4+random()*12,2+random()*6,random()*6,0,Math.PI*2);x.fill();x.strokeStyle='#b0b87b66';x.lineWidth=.7;x.beginPath();x.moveTo(a-4,b);x.lineTo(a+5,b);x.stroke();}}
   const map=new T.CanvasTexture(c);map.colorSpace=T.SRGBColorSpace;map.anisotropy=4;textures.set(key,map);return map;}
  const grassMat=new T.MeshStandardMaterial({map:atlas('grass'),color:desert?0xc2ad72:winter?0x969889:0xb5bd91,alphaTest:.4,side:T.DoubleSide,roughness:1,metalness:0});
  const leafMat=new T.MeshStandardMaterial({map:atlas('leaf'),color:winter?0x94a69a:desert?0x9b9a64:0xc1c598,alphaTest:.45,side:T.DoubleSide,roughness:1});
  const grass=[],leaves=[],trunks=[],dummy=new T.Object3D();
  const free=(x,z,pad)=>Math.abs(x)>7&&Math.abs(z)>6&&Math.hypot(x,z)>18&&!obstacles.some(o=>Math.hypot(x-o.x,z-o.z)<o.r+pad);
  const record=(list,x,y,z,sx,sy,sz,yaw)=>{dummy.position.set(x,y,z);dummy.rotation.set(0,yaw,0);dummy.scale.set(sx,sy,sz);dummy.updateMatrix();list.push(dummy.matrix.clone());};
  // Seeded groves and scrub patches leave roads, the objective and hard cover clear.
  for(let i=0;i<(high?620:240);i++){
   const x=(r()-.5)*(arena.size-18),z=(r()-.5)*(arena.size-18);if(!free(x,z,3))continue;
   const bush=i%3===0,h=bush?.65+r()*1.2:4.5+r()*5.5;
   if(!bush&&(desert||i%2))continue;
   const y=height(x,z),radius=bush?1+r():1.6+r()*1.5;
   if(!bush)record(trunks,x,y+h*.4,z,.18+r()*.14,h*.8,.18+r()*.14,r()*6);
   for(let j=0;j<(bush?9:26);j++){const a=r()*Math.PI*2,d=r()*radius,cy=bush?y+h*.55:y+h*.65+r()*h*.3;record(leaves,x+Math.cos(a)*d,cy,z+Math.sin(a)*d,bush?2:3.8,bush?1.6:3.2,1,r()*Math.PI);}
  }
  for(let i=0;i<(high?2100:650);i++){const x=(r()-.5)*(arena.size-12),z=(r()-.5)*(arena.size-12);if(!free(x,z,1)||r()<(desert?.72:winter?.55:.05))continue;
   const density=8+Math.floor(r()*10);for(let j=0;j<density;j++){const gx=x+(r()-.5)*9,gz=z+(r()-.5)*9;if(!free(gx,gz,.5))continue;const h=(desert?.25:.35)+r()*.6;record(grass,gx,height(gx,gz)+h*.45,gz,1+r(),h,1,r()*Math.PI);}}
  function instances(list,geometry,mat,name){if(!list.length)return;const o=new T.InstancedMesh(geometry,mat,list.length);list.forEach((m,i)=>o.setMatrixAt(i,m));o.instanceMatrix.needsUpdate=true;o.name=name;o.receiveShadow=true;o.castShadow=name!=='grass';o.computeBoundingSphere();world.add(o);}
  instances(grass,new T.PlaneGeometry(1,1),grassMat,'grass');instances(leaves,new T.PlaneGeometry(1,1),leafMat,'bushes-and-tree-canopies');instances(trunks,new T.CylinderGeometry(.7,1,1,7),material(0x6f6651,'wood'),'tree-trunks');
 }
 function environment(world,arena,height,rand,quality='high'){
  const kind=arena===GameData.maps.winter?'winter':arena===GameData.maps.desert?'desert':'training',stone=material(kind==='desert'?0xa68d68:0x7a8585,'rock'),wood=material(0x65533c,'wood'),foliage=material(kind==='winter'?0x6b847f:0x3a5845,'rock');
  world.traverse(o=>{if(!o.isMesh||o.material.vertexColors||o.material.customProgramCacheKey?.().startsWith('terrain'))return;const old=o.material;if(old.type==='MeshStandardMaterial'&&!old.map){const c=old.color.getHex(),isRock=['DodecahedronGeometry','IcosahedronGeometry'].includes(o.geometry.type),isWood=[0x535147,0x545a50,0x746d50,0x716c50,0x696050].includes(c),isMetal=[0x5c6868,0x677b82,0x434b43,0xb4b7a3,0x515c5d].includes(c),isLeaf=[0x4a6350,0x768e86,0x405c49,0x3a5845].includes(c);o.material=material(c,isRock?'rock':isWood?'wood':isMetal?'steel':isLeaf?'leaf':'brick');}});
  const rockCount=0,treeCount=quality==='high'?230:92;
  for(let i=0;i<rockCount;i++){const x=(rand()-.5)*(arena.size-24),z=(rand()-.5)*(arena.size-24);if(Math.abs(x)<24||Math.abs(z)>arena.size*.35)continue;const r=1+rand()*3,g=new T.IcosahedronGeometry(r,quality==='high'?2:1),pos=g.attributes.position;for(let j=0;j<pos.count;j++){const px=pos.getX(j),py=pos.getY(j),pz=pos.getZ(j),f=.88+.17*Math.sin(px*3+pz*2)*Math.cos(py*4);pos.setXYZ(j,px*f,py*f,pz*f);}g.computeVertexNormals();const rock=mesh(g,stone,world,x,height(x,z)-r*.35,z);rock.scale.set(1.3,.75,1);}
  if(kind!=='desert')for(let i=0;i<treeCount;i++){const x=(rand()-.5)*arena.size*1.4,z=(rand()-.5)*arena.size*1.4;if(Math.abs(x)<arena.size*.37||Math.abs(z)<16)continue;const h=5+rand()*8,g=new T.Group();g.position.set(x,height(x,z),z);world.add(g);cylinder(g,.08,.25,h,0,h/2,0,wood,quality==='high'?10:7);for(let j=0;j<(quality==='high'?7:4);j++){const y=h*.33+j*h*.095,r=(1-j/8)*2.4,b=mesh(new T.ConeGeometry(r,h*.35,quality==='high'?14:8,1),foliage,g,0,y,0);b.rotation.y=j*.9;if(kind==='winter')mesh(new T.ConeGeometry(r*.78,h*.25,quality==='high'?14:8),material(0xc8d4d8,'rock'),g,0,y+h*.09,0);}batch(g);}
  // Layered irregular mountain ridges, continuous beyond the playable area.
  for(let ring=0;ring<2;ring++){const g=new T.PlaneGeometry(1,1,160,12),p=g.attributes.position;for(let j=0;j<p.count;j++){const u=(p.getX(j)+.5)*Math.PI*2,v=p.getY(j)+.5,r=arena.size*(.79+ring*.38)+v*120,h=(22+Math.pow(Math.abs(Math.sin(u*5.3+ring)*Math.cos(u*3.7)),2)*135)*(Math.sin(v*Math.PI));p.setXYZ(j,Math.sin(u)*r,h-12,Math.cos(u)*r);}g.computeVertexNormals();mesh(g,material(kind==='desert'?0xb49b78:kind==='winter'?0xb6c6d0:0x718378,'rock'),world);}
  batch(world,[],true);
 }
 let studio;function lighting(scene){if(!studio){const w=256,h=128,data=new Uint8Array(w*h*4);for(let y=0;y<h;y++)for(let x=0;x<w;x++){const i=(y*w+x)*4,top=1-y/h,panel=(Math.abs(x-w*.24)<25||Math.abs(x-w*.7)<20)&&y>20&&y<60,b=(panel?210:35+top*125);data[i]=b;data[i+1]=b*1.01;data[i+2]=Math.min(255,b*1.08);data[i+3]=255;}studio=new T.DataTexture(data,w,h,T.RGBAFormat);studio.mapping=T.EquirectangularReflectionMapping;studio.colorSpace=T.SRGBColorSpace;studio.needsUpdate=true;}scene.environment=studio;}
 let post;
 function render(renderer,scene,camera,high){
  if(!high||!renderer.setRenderTarget){renderer.render(scene,camera);return;}
  if(!post){const target=new T.WebGLRenderTarget(1,1,{type:T.HalfFloatType,depthBuffer:true});target.depthTexture=new T.DepthTexture(1,1,T.UnsignedIntType);target.samples=4;const scene2=new T.Scene(),camera2=new T.OrthographicCamera(-1,1,1,-1,0,1),m=new T.ShaderMaterial({depthTest:false,depthWrite:false,uniforms:{colorMap:{value:target.texture},depthMap:{value:target.depthTexture},resolution:{value:new T.Vector2()},nearPlane:{value:.15},farPlane:{value:2400}},vertexShader:'varying vec2 screenUV;void main(){screenUV=uv;gl_Position=vec4(position.xy,0.,1.);}',fragmentShader:`
   uniform sampler2D colorMap;uniform sampler2D depthMap;uniform vec2 resolution;uniform float nearPlane;uniform float farPlane;varying vec2 screenUV;
   float viewDepth(vec2 uv){float d=texture2D(depthMap,uv).x;return (nearPlane*farPlane)/(farPlane+(nearPlane-farPlane)*d);}
   void main(){vec2 uv=screenUV,px=1./resolution;vec3 color=texture2D(colorMap,uv).rgb;float d=viewDepth(uv),ao=0.;vec3 glow=vec3(0.);float radius=clamp(35./max(d,1.),1.5,6.);
    for(int i=0;i<8;i++){float a=float(i)*.785398;vec2 offset=vec2(cos(a),sin(a))*px*radius;float nd=viewDepth(uv+offset),delta=d-nd;ao+=smoothstep(.035,.32,delta)*(1.-smoothstep(.65,2.2,delta));vec3 tap=texture2D(colorMap,uv+offset*2.).rgb;glow+=max(tap-vec3(1.3),vec3(0.));}
    color*=1.-ao*.034;color+=glow*.018;float lum=dot(color,vec3(.2126,.7152,.0722));color=mix(vec3(lum),color,.98);float edge=dot(uv-.5,uv-.5);color*=1.-edge*.10;gl_FragColor=vec4(color,1.);
    #include <tonemapping_fragment>
    #include <colorspace_fragment>
   }`});scene2.add(new T.Mesh(new T.PlaneGeometry(2,2),m));post={target,scene:scene2,camera:camera2,material:m,width:0,height:0};}
  const size=renderer.getDrawingBufferSize(new T.Vector2());if(size.x!==post.width||size.y!==post.height){post.width=size.x;post.height=size.y;post.target.setSize(size.x,size.y);post.material.uniforms.resolution.value.copy(size);}post.material.uniforms.nearPlane.value=camera.near;post.material.uniforms.farPlane.value=camera.far;renderer.setRenderTarget(post.target);renderer.render(scene,camera);renderer.setRenderTarget(null);renderer.render(post.scene,post.camera);
 }
 function building(g,w,d,h,industrial,kind){const brick=material(kind==='desert'?0xc9b28b:industrial?0x8c8178:0xb4afa0,'brick'),stone=material(0x707878,'rock'),metal=material(0x56626b),wood=material(0x696050,'wood');g.children.forEach(o=>{if(o.isMesh&&o.geometry===cube)o.material=brick;});box(g,w+.18,.65,d+.18,0,.33,0,stone);for(let side of [-1,1]){box(g,w+.45,.15,.22,0,h-.1,side*(d/2+.15),metal);for(let x=-w/2+1.2;x<w/2-.5;x+=2){box(g,.07,1.12,.14,x,h*.58,side*(d/2+.12),metal);box(g,.7,.06,.14,x,h*.58,side*(d/2+.12),metal);}const pipe=cylinder(g,.07,.07,h,side*(w/2-.22),h/2,d/2+.19,metal,12);for(let y=1;y<h;y+=2)box(g,.26,.08,.18,side*(w/2-.22),y,d/2+.16,metal);}
  for(let x of [-w/2,w/2])for(let z of [-d/2,d/2])box(g,.28,h,.28,x,h/2,z,stone);
  if(industrial){for(let x=-w/2+1;x<w/2;x+=2.6){box(g,.16,h,.2,x,h/2,d/2+.12,metal);}plate(g,w*.38,3,.18,-w*.16,1.5,d/2+.12,metal,.08);for(let i=0;i<9;i++)box(g,w*.38,.035,.03,-w*.16,.2+i*.32,d/2+.24,stone);for(let i=0;i<3;i++){const vent=cylinder(g,.6,.6,.8,-w*.3+i*w*.3,h+.5,-d*.22,metal,20);cylinder(g,.8,.65,.16,-w*.3+i*w*.3,h+.98,-d*.22,metal,20);}for(let y=1;y<h+1;y+=.45)box(g,.75,.05,.06,w/2+.2,y,0,metal);for(let z of [-.35,.35])cylinder(g,.035,.035,h+1,w/2+.2,(h+1)/2,z,metal,8);
  }else{box(g,.8,2.2,.8,-w*.28,h+.5,-d*.17,brick);box(g,1,.13,1,-w*.28,h+1.65,-d*.17,stone);for(let i=0;i<8;i++)box(g,.08,2.1,.07,w*.18-.55+i*.16,1.12,d/2+.14,wood);box(g,.1,.16,.05,w*.18+.4,1.1,d/2+.22,metal);}
  batch(g);
 }
 // Separating-axis test for oriented hull footprints, including track width.
 function overlaps(a,x,z,b){
  const axes=t=>[{x:Math.cos(t.yaw),z:-Math.sin(t.yaw)},{x:Math.sin(t.yaw),z:Math.cos(t.yaw)}],aa=axes(a),bb=axes(b);
  const ah=[a.width/2+.44,a.length/2+.28],bh=[b.width/2+.44,b.length/2+.28],dx=b.group.position.x-x,dz=b.group.position.z-z;
  return [...aa,...bb].every(axis=>{const dot=v=>Math.abs(v.x*axis.x+v.z*axis.z);return Math.abs(dx*axis.x+dz*axis.z)<ah[0]*dot(aa[0])+ah[1]*dot(aa[1])+bh[0]*dot(bb[0])+bh[1]*dot(bb[1]);});
 }
 window.Remaster={vegetation,tank,suspension,zone,armorMask,overlaps,terrainMaterial,sky,environment,material,batch,lighting,render,building};
})();
