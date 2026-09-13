const assert=require('node:assert/strict'),D=require('../src/data.js');
function fall(mass,hz){const b={y:20,vy:0,grounded:false};for(let i=0;i<hz;i++)D.verticalStep(b,-100,mass,1/hz);return b;}
for(const mass of [12,32,61])for(const hz of [30,60,120]){
 const b=fall(mass,hz);assert.ok(Math.abs(b.y-(20-D.gravity/2))<1e-8);assert.ok(Math.abs(b.vy+D.gravity)<1e-8);assert.equal(b.grounded,false);
}
const b={y:8,vy:0,grounded:false};let impact=0,min=Infinity;
for(let i=0;i<600;i++){D.verticalStep(b,0,32,1/120);impact=Math.max(impact,b.impact);min=Math.min(min,b.y);}
assert.ok(impact>8,'Landing registers downward velocity');assert.ok(min>=-.3,'No tunneling through terrain');assert.ok(Math.abs(b.y)<.01&&Math.abs(b.vy)<.01,'Damped suspension settles');
assert.ok(Math.abs(b.normalForce-32000*D.gravity)<100,'Resting contact balances weight');
D.verticalStep(b,-10,32,1/60);assert.equal(b.grounded,false,'Dropping support releases contact');assert.ok(b.vy<0,'Gravity acts after driving off a ledge');
assert.equal(D.frictionSpeed(0,.1,1/60,D.surfaces.earth.static),0,'Static grip holds a mild slope');
assert.ok(D.frictionSpeed(0,.6,1/60,D.surfaces.snow.static)<0,'Steep snow slopes slide');
function brake(mu){let v=8;for(let i=0;i<60;i++)v=D.frictionSpeed(v,0,1/60,mu);return v;}
assert.ok(brake(D.surfaces.snow.kinetic)>brake(D.surfaces.earth.kinetic),'Snow has a longer stopping distance');
assert.equal(D.frictionSpeed(.01,0,.05,.5),0,'Friction cannot reverse a stopped body');
console.log('PASS: gravity independent of mass/FPS, contact release, landing, weight balance, friction and sliding.');
global.THREE=require('../vendor/three.min.js');global.GameData=D;global.window=global;
global.document={createElement:()=>({getContext:()=>new Proxy({},{get:()=>()=>{}})})};require('../src/remaster.js');
const spec=D.stats(D.tanks[1]),t={...Remaster.tank(spec),spec,yaw:0,speed:4,alive:true};
Remaster.suspension(t,()=>0,1/60);t.suspension.y=t.group.position.y=10;t.suspension.vy=0;t.suspension.grounded=false;t.velocityX=0;t.velocityZ=4;
const fs=require('node:fs'),vm=require('node:vm'),source=fs.readFileSync(require('node:path').join(__dirname,'../src/game.js'),'utf8');
const movement=source.slice(source.indexOf('function groundSurface('),source.indexOf('function muzzlePos('));
const context={D,Remaster,arena:D.maps.training,height:()=>0,blocked:()=>false,tanks:[t],V:THREE.Vector3,vehicleEffects(){},smoke(){}};
vm.createContext(context);vm.runInContext(movement,context);
t.yaw=1;context.accelerateTank(t,-1,1/60);context.moveTank(t,1/60);
assert.equal(t.yaw,0,'Airborne input cannot change heading');assert.equal(t.speed,4,'Airborne input cannot brake');assert.ok(t.group.position.z>0,'Airborne momentum persists');assert.ok(t.group.position.y<10&&t.group.position.y>9.99,'Movement uses free fall rather than ground snapping');
for(let i=0;i<300;i++){context.accelerateTank(t,0,1/60);context.moveTank(t,1/60);}
assert.ok(t.suspension.grounded&&Math.abs(t.group.position.y)<.01,'In-game movement lands and settles');
console.log('PASS: integrated airborne movement, steering lock and landing.');
