(function(root){
 'use strict';
 const nations=['СССР','Германия','Франция'];
 const classes=['Лёгкий танк','Средний танк','Тяжёлый танк'];
 const names=[['105 «Ветер»','205 «Оплот»','305 «Гранит»'],['L-12 «Искра»','M-24 «Клин»','S-36 «Монолит»'],['A-7 «Стриж»','B-14 «Порыв»','C-21 «Редут»']];
 const descriptions=['Разведка, скорость и обход с фланга. Бейте первым и меняйте позицию.','Баланс подвижности и огневой мощи. Поддержите союзников на любом направлении.','Крепкая броня и мощное орудие. Держите рубеж и прикрывайте команду.'];
 const costs=[0,300,1900,4300,7200];
 const tanks=nations.flatMap((nation,n)=>classes.map((cls,c)=>({id:`${n}-${c}`,nation,n,c,name:names[n][c],cls,description:descriptions[c],color:[0x728269,0x74818a,0x908e74][n],hp:[580,820,1160][c]+[0,40,-20][n],damage:[105,157,228][c]+[4,8,-4][n],reload:[2.5,3.6,4.9][c]+[0,.15,-.15][n],speed:[15,11.8,8.5][c]+[.3,-.4,.5][n],turn:[1.25,1,.73][c],turret:[1.65,1.4,1.08][c],armor:[8,17,28][c]+[0,2,-1][n],view:[135,118,104][c]+[0,-3,5][n],spread:[.019,.015,.018][c],aim:[.85,1.1,1.5][c],zoom:[2.2,3.15,4.1][c]+[.05,.2,.35][n],tracks:[90,125,170][c],camo:[.22,.14,.08][c]})));
 const maps={training:{name:'Учебный полигон',subtitle:'ХОЛМЫ · ДЕРЕВНЯ · ФЛАНГИ',size:560,seed:123,ground:0x788365,fog:0xa0aca2,sky:0xa6b7b6,time:420},desert:{name:'Пустынный полигон',subtitle:'ДЮНЫ · СКАЛЫ · ДАЛЬНИЙ БОЙ',size:680,seed:456,ground:0xbda276,fog:0xd7bf95,sky:0xd8c7a6,time:480},winter:{name:'Зимний завод',subtitle:'ЦЕХА · ПРОХОДЫ · БЛИЖНИЙ БОЙ',size:600,seed:789,ground:0xc0cccc,fog:0xa5b7c5,sky:0xb4c7d5,time:450}};
 const moduleNames={gun:'Орудие',armor:'Броня',engine:'Двигатель',tracks:'Ходовая'};
 function moduleLevels(value=1){return Object.fromEntries(Object.keys(moduleNames).map(k=>{const v=typeof value==='number'?value:value?.[k];return [k,Number.isFinite(v)?Math.max(1,Math.min(5,Math.floor(v))):1];}));}
 function stats(tank,level=1){const modules=moduleLevels(level),g=modules.gun-1,a=modules.armor-1,e=modules.engine-1,t=modules.tracks-1;return {...tank,modules,level:Math.max(...Object.values(modules)),power:Math.round(tank.power*(1+e*.04)),hp:Math.round(tank.hp*(1+a*.075)),damage:Math.round(tank.damage*(1+g*.065)),reload:+(tank.reload*(1-g*.025)).toFixed(2),speed:tank.speed,turn:tank.turn*(1+t*.03),turret:tank.turret*(1+g*.025),armor:tank.armor+a*2,view:tank.view+g*4,spread:tank.spread*(1-g*.045),aim:tank.aim*(1-g*.025),zoom:+(tank.zoom+g*.12).toFixed(2),tracks:tank.tracks+t*8,camo:tank.camo};}
 function upgradeModule(save,id,key){if(!tanks.some(t=>t.id===id)||!save.owned?.[id]||!Object.hasOwn(moduleNames,key))return false;const modules=moduleLevels(save.modules?.[id]??save.levels?.[id]),level=modules[key];if(level>=5||!Number.isFinite(save.silver)||save.silver<costs[level])return false;save.silver-=costs[level];modules[key]++;(save.modules??={})[id]=modules;(save.levels??={})[id]=Math.max(...Object.values(modules));return true;}
 // Original vehicle specifications: tonnes, horsepower and forward/reverse km/h.
 const mobility=[[14,320,35,14],[32,520,29,11],[49,620,24,8],[17,340,35,12],[38,600,29,10],[61,700,24,7],[12,290,35,16],[29,540,29,13],[54,650,24,8]];
 tanks.forEach((t,i)=>{const [mass,power,speed,reverse]=mobility[i];Object.assign(t,{mass,power,speed:speed/3.6,reverse:reverse/3.6});});
 classes.push('Самоходное орудие');
 for(let n=0;n<3;n++)tanks.push({...tanks[n*3+1],id:`${n}-3`,c:3,name:['СУ-152 «Гром»','G-150 «Молот»','AM-155 «Оса»'][n],cls:classes[3],description:'Тяжёлое орудие поддержки. Высокий разовый урон, слабая броня и долгая перезарядка.',hp:620+n*25,damage:430+n*20,reload:10.5+n*.6,armor:5+n,tracks:100,mass:[38,32,28][n],power:[520,480,450][n],speed:27/3.6,reverse:9/3.6,turn:.65,turret:.75,view:130,spread:.021,aim:2.2,zoom:4.5,camo:.17});
 const gravity=9.81;
 const shellSpeed=285,shellGravity=.1;
 // Normalized dispersion: 1 is a cold/moving gun, 0.18 is fully aimed.
 function aimStep(value,aiming,motion,aimTime,dt){
  const movement=Math.max(0,Math.min(1,Math.abs(motion))),target=aiming?Math.min(1,.18+movement*.72):Math.min(1,.72+movement*.28);
  const rate=aiming?Math.max(.12,aimTime):.32;
  return Math.max(.18,Math.min(1,value+(target-value)*(1-Math.exp(-Math.max(0,dt)*4/rate))));
 }
 function shellDrop(distance,speed=shellSpeed,gravityScale=shellGravity){const time=Math.max(0,distance)/Math.max(1,speed);return .5*gravity*Math.max(0,gravityScale)*time*time;}
 function sightRange(spec,scoped=false){return (spec?.view||100)*(scoped?([1.9,1.65,1.45,2.1][spec?.c]||1.5):1);}
 function detectionRange(observer,target,moving=false,fired=false,scoped=false){const concealment=Math.max(0,Math.min(.55,(target?.camo||0)+(moving?-.05:0)+(fired?-.22:0)));return Math.max(45,sightRange(observer,scoped)*(1-concealment*.72));}
 // Differential steering: heavier hulls build yaw momentum more slowly;
 // traction limits steering at speed and on slippery surfaces.
 function steeringStep(spec,rate,input,speed,dt,surface=surfaces.earth){
  const grip=Math.min(1,surface.kinetic/surfaces.earth.kinetic),fraction=Math.min(1,Math.abs(speed)/spec.speed);
  const target=Math.max(-1,Math.min(1,input))*spec.turn*Math.sqrt(grip)*(1-fraction*.48);
  const response=(input?3.8:6)*Math.sqrt(32/spec.mass)*grip;
  return rate+(target-rate)*(1-Math.exp(-response*Math.max(0,dt)));
 }
 function contactImpulse(massA,massB,closingSpeed){return Math.max(0,closingSpeed)*1.04/(1/Math.max(1,massA)+(Number.isFinite(massB)?1/Math.max(1,massB):0));}
 function randomRoster(count,random=Math.random){const pool=tanks.slice();for(let i=pool.length-1;i>0;i--){const j=Math.min(i,Math.floor(random()*(i+1)));[pool[i],pool[j]]=[pool[j],pool[i]];}return pool.slice(0,count);}
 // Equal damage and kills share a place. Stable IDs only order tied rows.
 function standings(rows){
  const sorted=rows.map(r=>({...r,damage:Math.max(0,r.damage||0),kills:Math.max(0,r.kills||0)})).sort((a,b)=>b.damage-a.damage||b.kills-a.kills||String(a.id).localeCompare(String(b.id)));
  sorted.forEach((r,i)=>{const previous=sorted[i-1];r.place=previous&&r.damage===previous.damage&&r.kills===previous.kills?previous.place:i+1;});return sorted;
 }

 const surfaces={earth:{static:.72,kinetic:.55,rolling:.025},sand:{static:.58,kinetic:.46,rolling:.065},snow:{static:.35,kinetic:.24,rolling:.04}};
 // Acceleration along a slope with Coulomb friction and static sticking.
 function frictionSpeed(speed,slope,dt,mu){const angle=Math.atan(slope),pull=-gravity*Math.sin(angle),friction=mu*gravity*Math.cos(angle);if(Math.abs(speed)<.001&&Math.abs(pull)<=friction)return 0;const sign=Math.sign(speed)||Math.sign(pull),next=speed+(pull-sign*friction)*dt;if(next*sign<0&&Math.abs(pull)<=friction)return 0;return next;}
 // Unilateral spring contact: terrain can push upwards but never pull a body down.
 function verticalStep(body,support,mass,dt){
  const steps=Math.max(1,Math.ceil(dt*120)),h=dt/steps,k=3200000/(mass*1000),damping=1.5*Math.sqrt(k);body.impact=0;
  for(let i=0;i<steps;i++){
   const contact=body.y<=support+.18;
   const normal=contact?Math.max(0,gravity+k*(support-body.y)-damping*body.vy):0;
   if(contact&&!body.grounded&&body.vy<0)body.impact=Math.max(body.impact,-body.vy);
   const acceleration=normal-gravity;body.y+=body.vy*h+.5*acceleration*h*h;body.vy+=acceleration*h;body.grounded=normal>0;
   if(body.y<support-.3){body.impact=Math.max(body.impact,-body.vy);body.y=support-.3;body.vy=Math.max(0,body.vy)*.1;body.grounded=true;}
   body.normalForce=normal*mass*1000;
  }
  return body;
 }
 function driveSpeed(spec,speed,throttle,slope,dt,turn=0,damaged=false,surface=surfaces.earth){
  dt=Math.max(0,Math.min(dt,.1));throttle=Math.max(-1,Math.min(1,throttle));
  const cap=(throttle<0?spec.reverse:spec.speed)*(damaged?.5:1),target=throttle*cap;
  // Opposite input brakes to a stop before engaging reverse. No input holds brakes.
  const braking=!throttle||speed*throttle<0||Math.abs(speed)>Math.abs(target)+.15;
  const brake=Math.min(surface.static,3.2*Math.sqrt(32/spec.mass)/gravity);
  if(braking)return Math.max(-spec.reverse,Math.min(spec.speed,frictionSpeed(speed,slope,dt,Math.abs(speed)<.001?surface.static:brake)));
  const mass=spec.mass*1000,power=spec.power*735.5*.72;
  // Low gear supplies wheel torque uphill. Limit net acceleration rather than
  // tractive force, otherwise a heavy tank stalls on a modest slope at launch.
  const traction=Math.min(surface.kinetic*gravity/Math.sqrt(1+slope*slope),power/(mass*Math.max(1.2,Math.abs(speed))))*Math.abs(throttle);
  const resistance=surface.rolling*gravity+.0025*speed*speed+Math.abs(turn)*.32;
  const rawForce=Math.sign(throttle)*Math.max(0,traction-resistance)-gravity*Math.sin(Math.atan(slope));
  const accelerationLimit=Math.min(2.65,1+spec.power/spec.mass*.06);
  const force=Math.max(-accelerationLimit,Math.min(accelerationLimit,rawForce));
  let next=speed+force*dt;
  // Static grip can hold a stalled vehicle only below the friction angle.
  if(next*throttle<0&&Math.abs(slope)<=surface.static)next=0;
  return Math.max(-spec.reverse*(damaged?.5:1),Math.min(spec.speed*(damaged?.5:1),throttle>0?Math.min(target,next):Math.max(target,next)));
 }
 function defaults(){return {version:3,purchaseOrder:['0-1'],modules:Object.fromEntries(tanks.map(t=>[t.id,moduleLevels()])),owned:{'0-1':true},updated:0,selected:'0-1',nation:0,silver:0,xp:0,levels:Object.fromEntries(tanks.map(t=>[t.id,1])),battles:0,wins:0,tutorial:false,settings:{volume:.45,quality:'high',difficulty:'normal',sensitivity:1},map:'training'};}
 function clean(raw){const d=defaults();if(!raw||typeof raw!=='object')return d;const number=(x,min,max,fallback)=>Number.isFinite(x)?Math.max(min,Math.min(max,x)):fallback;for(const k of ['silver','xp','battles','wins','updated'])d[k]=Math.floor(number(raw[k],0,1e14,0));for(const t of tanks){d.levels[t.id]=Math.floor(number(raw.levels?.[t.id],1,5,1));if(raw.owned?.[t.id]===true||(!raw.owned&&d.levels[t.id]>1))d.owned[t.id]=true;}for(const t of tanks){d.modules[t.id]=moduleLevels(raw.modules?.[t.id]??d.levels[t.id]);d.levels[t.id]=Math.max(...Object.values(d.modules[t.id]));}const requested=tanks.find(t=>t.id===raw.selected),fallback=tanks.find(t=>d.owned[t.id])||tanks[1];d.selected=requested&&d.owned[requested.id]?requested.id:fallback.id;d.nation=tanks.find(t=>t.id===d.selected).n;d.purchaseOrder=[...new Set([...(Array.isArray(raw.purchaseOrder)?raw.purchaseOrder:[]),...Object.keys(d.owned)])].filter(id=>d.owned[id]);d.tutorial=raw.tutorial===true;d.map=maps[raw.map]?raw.map:'training';const s=raw.settings||{};d.settings.volume=number(s.volume,0,1,.45);d.settings.sensitivity=number(s.sensitivity,.25,2.5,1);d.settings.quality=['low','high'].includes(s.quality)?s.quality:'high';d.settings.difficulty=['easy','normal','hard'].includes(s.difficulty)?s.difficulty:'normal';return d;}
 function upgrade(save,id){if(!save.owned?.[id])return false;const level=save.levels[id];if(!tanks.some(t=>t.id===id)||level>=5||save.silver<costs[level])return false;save.silver-=costs[level];save.levels[id]++;(save.modules??={})[id]=moduleLevels(save.levels[id]);return true;}
 function reward(r){const rank=r.place>0?Math.max(0,7-r.place):0,parts={participation:300,damage:Math.floor(Math.max(0,r.damage||0)*.2),kills:(r.kills||0)*150,victory:r.win?200:0,spotting:(r.spotted||0)*25,objective:Math.floor((r.capture||0)*4),survival:r.survived?75:0,placement:rank*75};return {parts,silver:Object.values(parts).reduce((a,b)=>a+b,0),xp:Math.floor(70+Math.max(0,r.damage||0)*.12+(r.kills||0)*60+(r.win?100:0)+rank*30)};}
 function segmentCircle(ax,az,bx,bz,cx,cz,r){const dx=bx-ax,dz=bz-az,l=dx*dx+dz*dz,t=l?Math.max(0,Math.min(1,((cx-ax)*dx+(cz-az)*dz)/l)):0;return (ax+dx*t-cx)**2+(az+dz*t-cz)**2<=r*r;}
 function rng(seed){return ()=>{seed|=0;seed=seed+0x6D2B79F5|0;let t=Math.imul(seed^seed>>>15,1|seed);t=t+Math.imul(t^t>>>7,61|t)^t;return ((t^t>>>14)>>>0)/4294967296;};}
 function price(id){const t=tanks.find(t=>t.id===id);return t?{xp:[350,850,1500,2100][t.c]+t.n*150,silver:[1200,2800,4800,6500][t.c]+t.n*400}:null;}
 function unlock(save,id){const p=price(id);if(!p||save.owned?.[id]||save.xp<p.xp||save.silver<p.silver)return false;save.xp-=p.xp;save.silver-=p.silver;(save.purchaseOrder??=Object.keys(save.owned||{})).push(id);(save.owned??={})[id]=true;return true;}
 // Millimetres at level I. Each vehicle has a different distribution of armor.
 const armorZones=['front','lower','side','rear','turret','turretSide','turretRear','roof','tracks'];
 const armorProfiles={
  '0-3':[45,30,25,20,50,25,20,12,20],
  '1-3':[35,25,20,18,40,20,18,10,18],
  '2-3':[30,20,18,15,35,18,15,10,16],
  '0-0':[48,28,24,18,58,30,22,12,18],
  '0-1':[95,55,55,38,125,75,48,22,30],
  '0-2':[150,88,92,60,185,120,75,30,45],
  '1-0':[65,42,20,16,48,25,20,10,16],
  '1-1':[125,65,42,30,100,58,38,18,26],
  '1-2':[165,125,100,82,155,110,90,35,50],
  '2-0':[38,22,18,14,72,24,18,9,14],
  '2-1':[78,45,36,25,140,48,30,16,22],
  '2-2':[135,95,115,70,175,85,55,28,42]
 };
 function armorThickness(tank,zone){const profile=armorProfiles[tank.id]||armorProfiles[`${tank.n}-${tank.c}`];const index=armorZones.indexOf(zone);return Math.round(profile[index<0?0:index]*(1+(Math.max(1,tank.modules?.armor||tank.level||1)-1)*.025));}
 function armorColor(mm){return mm<30?'#70e899':mm<60?'#add66a':mm<95?'#f2cd61':mm<135?'#ed9454':mm<170?'#ed6256':'#ba4268';}
 function penetration(attacker,defender,zone='front',cosine=1,distance=0){const armor=armorThickness(defender,zone),effective=armor/Math.max(.2,Math.abs(cosine)),power=([98,125,164,205][attacker.c]+((attacker.modules?.gun||attacker.level||1)-1)*5)*Math.max(.76,1-distance/2200),chance=Math.max(0,Math.min(1,(power/effective-.75)/.5));return {armor,effective,power,chance,color:chance>=.75?'#70e899':chance>=.25?'#ffbb55':'#ff6262'};}
 function ricochetVelocity(velocity,normal,incidence,bounces=0){if(!velocity||!normal||incidence>=.44||bounces>=2)return null;const speed=Math.hypot(velocity.x,velocity.y,velocity.z);if(speed<=48)return null;const dot=velocity.x*normal.x+velocity.y*normal.y+velocity.z*normal.z,retention=.48+incidence*.22;return {x:(velocity.x-2*dot*normal.x)*retention,y:(velocity.y-2*dot*normal.y)*retention,z:(velocity.z-2*dot*normal.z)*retention};}
 function collisionRetention(dx,dz,ox,oz){
  const approach=(dx*ox+dz*oz)/(Math.hypot(dx,dz)*Math.hypot(ox,oz)||1);
  return approach<=0?1:approach>.48?0:.16;
 }
 root.GameData={contactImpulse,sightRange,steeringStep,randomRoster,standings,moduleNames,moduleLevels,upgradeModule,price,unlock,penetration,ricochetVelocity,collisionRetention,armorZones,armorThickness,armorColor,gravity,shellSpeed,shellGravity,aimStep,shellDrop,detectionRange,surfaces,frictionSpeed,verticalStep,driveSpeed,nations,classes,tanks,costs,maps,stats,defaults,clean,upgrade,reward,segmentCircle,rng};
 if(typeof module!=='undefined')module.exports=root.GameData;
})(typeof window!=='undefined'?window:globalThis);
