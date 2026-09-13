const assert=require('node:assert/strict');
global.THREE=require('../vendor/three.min.js');global.GameData=require('../src/data.js');global.window=global;
global.document={createElement:()=>({getContext:()=>new Proxy({},{get:()=>()=>{}})})};
require('../src/remaster.js');
function tank(i){const spec=GameData.stats(GameData.tanks[i]);return {...Remaster.tank(spec),spec,yaw:0,speed:0};}
for(const yaw of [0,Math.PI/2,Math.PI,-Math.PI/2]){
 const t=tank(1);t.yaw=yaw;
 for(let i=0;i<90;i++)Remaster.suspension(t,(x,z)=>.1*x+.15*z,1/60);
 assert.ok(Number.isFinite(t.group.position.y));
 assert.ok(Math.abs(t.group.rotation.x)+Math.abs(t.group.rotation.z)>.1,'Slope produces pitch/roll at every heading');
 const up=new THREE.Vector3(0,1,0).applyQuaternion(t.group.quaternion);
 assert.ok(up.dot(new THREE.Vector3(-.1,1,-.15).normalize())>.995,'Body follows terrain normal');
}
const t=tank(0);
const flatMatrices=t.trackBelts.map(b=>Array.from(b.links.instanceMatrix.array));
for(let i=0;i<90;i++)Remaster.suspension(t,(x,z)=>x>0?.2*Math.sin(z*2):0,1/60);
assert.ok(Math.max(...t.wheels.map(w=>w.position.y))-Math.min(...t.wheels.map(w=>w.position.y))>.05,'Independent wheel travel');
assert.ok(t.trackBelts.some((b,i)=>Array.from(b.links.instanceMatrix.array).some((v,j)=>Math.abs(v-flatMatrices[i][j])>.025)),'Track links articulate to uneven ground');
const phases=t.trackBelts.map(b=>b.phase);Remaster.suspension(t,()=>0,1/60,0);
assert.deepEqual(t.trackBelts.map(b=>b.phase),phases,'Stationary tracks do not scroll');
t.yaw=.1;Remaster.suspension(t,()=>0,1/60,0);
assert.ok(t.trackBelts[0].phase*t.trackBelts[1].phase<0,'Pivot turn moves tracks in opposite directions');
Remaster.suspension(t,()=>0,1/60,.1);
for(const b of t.trackBelts)assert.ok(Array.from(b.links.instanceMatrix.array).every(Number.isFinite));
assert.ok(t.wheels.every(w=>w.position.y>0&&w.position.y<1.3),'Bounded suspension travel');
console.log('PASS: terrain normals, independent wheels, stationary tracks, differential tracks and finite geometry.');
