const assert=require('node:assert/strict'),D=require('../src/data.js');
const save=D.defaults();save.xp=save.silver=99999;
for(const id of ['2-3','0-0','1-3'])assert.ok(D.unlock(save,id));
assert.deepEqual(D.clean(JSON.parse(JSON.stringify(save))).purchaseOrder,['0-1','2-3','0-0','1-3']);
assert.equal(D.unlock(save,'2-3'),false);
for(const tank of D.tanks.filter(t=>t.c===3)){
 assert.ok(tank.damage>400&&tank.reload>=10);
 assert.ok(D.armorThickness(tank,'front')<=45);
 assert.ok(Number.isFinite(D.penetration(tank,D.tanks[1]).power));
}
console.log('PASS: purchase order survives reload, no duplicates, three high-damage lightly armored SPGs.');
// Exercise the actual movement guard with attempted forward, lateral and turn motion.
const fs=require('node:fs'),vm=require('node:vm');
const source=fs.readFileSync(require.resolve('../src/game.js'),'utf8');
const movement=source.slice(source.indexOf('function moveTank('),source.indexOf('function muzzlePos('));
let contacts=0;const context={Remaster:{suspension(){contacts++;}},height:()=>0};vm.createContext(context);vm.runInContext(movement,context);
const vehicle={trackTime:10,trackYaw:.7,yaw:1.2,speed:9,slip:3,velocityX:8,velocityZ:8,group:{rotation:{y:1.2}}};
assert.equal(context.moveTank(vehicle,.1),false);assert.equal(vehicle.speed,0);assert.equal(vehicle.velocityX,0);assert.equal(vehicle.velocityZ,0);assert.equal(vehicle.yaw,.7);assert.equal(contacts,1);
for(let i=0;i<100;i++)vehicle.trackTime=Math.max(0,vehicle.trackTime-.1);
assert.ok(vehicle.trackTime<1e-12);console.log('PASS: broken track blocks translation and hull rotation, suspension remains active.');
