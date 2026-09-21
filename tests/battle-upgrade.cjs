const assert=require('node:assert/strict'),D=require('../src/data.js'),fs=require('node:fs'),vm=require('node:vm');
const light=D.stats(D.tanks[0]),heavy=D.stats(D.tanks[5]);
const momentum=D.contactImpulse(60,15,4);assert.ok(momentum/15>momentum/60,'Lighter tank receives greater velocity change');
assert.ok(Math.abs(60*(4-momentum/60)+15*(momentum/15)-240)<1e-9,'Contact conserves linear momentum');
assert.equal(D.contactImpulse(60,15,-2),0,'Separating vehicles receive no impulse');
assert.ok(D.driveSpeed(heavy,0,.65,.18,.05)>0,'Heavy tank low gear can start uphill');
assert.ok(D.steeringStep(light,0,1,0,.1)>D.steeringStep(heavy,0,1,0,.1),'Heavy hull builds rotation more slowly');
assert.ok(D.steeringStep(light,0,1,light.speed,.1)<D.steeringStep(light,0,1,0,.1),'Speed reduces turning authority');
function turn(hz){let r=0;for(let i=0;i<hz;i++)r=D.steeringStep(heavy,r,1,3,1/hz);return r;}
assert.ok(Math.abs(turn(30)-turn(120))<1e-10,'Steering independent of FPS');
assert.ok(D.steeringStep(light,.8,0,0,.1)>0,'Releasing steering does not erase momentum instantly');
assert.ok(D.driveSpeed(light,1,.4,0,.03)<D.driveSpeed(light,1,1,0,.03),'Partial throttle changes force');
for(const spec of D.tanks){assert.ok(D.detectionRange(spec,heavy,false,false,true)>D.detectionRange(spec,heavy));assert.ok(D.detectionRange(spec,light)<D.detectionRange(spec,heavy),'Scout concealment still works');}
assert.equal(new Set([0,1,2,3].map(c=>D.sightRange(D.tanks.find(t=>t.c===c),true))).size,4);
const seen=new Set();for(let seed=1;seed<100;seed++){const roster=D.randomRoster(5,D.rng(seed));assert.equal(new Set(roster.map(t=>t.id)).size,5);roster.forEach(t=>seen.add(t.id));}assert.equal(seen.size,12,'All vehicle types appear across battles');
const rows=D.standings([{id:'c',damage:100,kills:1},{id:'b',damage:200,kills:1},{id:'a',damage:200,kills:1},{id:'d',damage:100,kills:2}]);
assert.deepEqual(rows.map(r=>[r.id,r.place]),[['a',1],['b',1],['d',3],['c',4]]);
let previous=Infinity;for(let place=1;place<=6;place++){const reward=D.reward({damage:100,kills:1,place});assert.ok(reward.silver<previous);assert.equal(reward.parts.placement,(7-place)*75);previous=reward.silver;}
// Verify local downloaded data and runtime geometry sizing without a renderer.
global.window=global;global.THREE=require('../vendor/three.min.js');THREE.TextureLoader=class{load(){return new THREE.Texture();}};
require('../assets/models/kenney.js');require('../src/map-assets.js');
for(const name of Object.keys(KenneyModels)){const object=MapAssets.create(name,10,8,7),bounds=new THREE.Box3().setFromObject(object),size=bounds.getSize(new THREE.Vector3());assert.ok(Math.abs(size.x-10)<.001&&Math.abs(size.y-8)<.001&&Math.abs(size.z-7)<.001);assert.ok(Math.abs(bounds.min.y)<.001,'Asset grounded at its origin');object.traverse(o=>{if(o.isMesh){assert.ok(!o.material.transparent);assert.ok(o.geometry.attributes.position.array.every(Number.isFinite));}});}
for(const name of ['engine','wind','shot','hit','boom'])assert.equal(fs.readFileSync(`assets/audio/${name}.ogg`).subarray(0,4).toString(),'OggS');
// Damage events for any owner feed the same ranking counters.
const source=fs.readFileSync('src/game.js','utf8'),damage=source.slice(source.indexOf('function damageTank('),source.indexOf('\nfunction ',source.indexOf('function damageTank(')+1));
const el={style:{},prepend(){},children:[]},context={Math:{...Math,round:Math.round,min:Math.min,max:Math.max,random:()=>.5},capture:50,record:{damage:0,kills:0},elapsed:1,addImpactHole(){},hitText(){},sound(){},burst(){},smoke(){},makeWreck(t){t.alive=false;},document:{createElement:()=>({style:{}}),exitPointerLock(){}},$:()=>el,setTimeout(){},V:THREE.Vector3};vm.createContext(context);vm.runInContext(damage,context);
const owner={team:0,damage:0,kills:0,name:'bot'},target={alive:true,team:1,hp:100,spec:{armor:0},name:'target',group:{position:new THREE.Vector3()}};context.damageTank(target,60,owner,new THREE.Vector3());assert.equal(owner.damage,60);context.damageTank(target,60,owner,new THREE.Vector3());assert.equal(owner.damage,100,'Overkill is not credited');assert.equal(owner.kills,1);context.damageTank(target,60,owner,new THREE.Vector3());assert.equal(owner.kills,1,'Wreck cannot award a second kill');
console.log('PASS: steering inertia, FPS, throttle, class optics, random roster, ties, rank rewards, imported geometry, audio files and all-participant damage.');
