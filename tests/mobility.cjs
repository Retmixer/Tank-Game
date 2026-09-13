const assert=require('node:assert/strict'),D=require('../src/data.js');
function run(spec,seconds,throttle=1,slope=0,hz=60,initial=0){let speed=initial,distance=0;for(let i=0;i<seconds*hz;i++){speed=D.driveSpeed(spec,speed,throttle,slope,1/hz);distance+=speed/hz;}return {speed,distance};}
const light=D.stats(D.tanks[0]),medium=D.stats(D.tanks[1]),heavy=D.stats(D.tanks[5]);
assert.ok(run(light,8).speed>run(heavy,8).speed);
assert.ok(run({...medium,mass:medium.mass*2},8).speed<run(medium,8).speed);
assert.ok(run(medium,8,1,.12).speed<run(medium,8).speed);
assert.ok(run(medium,3,1,-.12).speed>run(medium,3).speed);
for(const t of D.tanks){
 for(let level=1;level<=5;level++)assert.ok(Math.abs(D.stats(t,level).speed*3.6-[35,29,24][t.c])<1e-9,'Class speed cap survives upgrades');
 const s=D.stats(t);assert.ok(run(s,60).speed<=s.speed);assert.ok(Math.abs(run(s,60,-1).speed)<=s.reverse);
 assert.equal(run(s,15,0,0,60,s.speed).speed,0);
 assert.ok(D.driveSpeed(s,5,-1,0,1/60)>0,'Reversing first brakes forward momentum');
 assert.ok(Math.abs(run(s,10,1,0,30).speed-run(s,10,1,0,120).speed)<.12);
 assert.ok(D.driveSpeed(s,0,1,0,1/60)<.05,'No instant launch');
}
console.log('PASS: mass, power, hills, braking, reverse limits and frame-rate independence.',run(medium,3));
