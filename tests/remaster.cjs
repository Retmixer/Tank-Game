const assert=require('node:assert/strict'),D=require('../src/data.js');
const s=D.defaults();assert.equal(Object.keys(s.owned).length,1);assert.equal(D.unlock(s,'2-2'),false);assert.equal(D.upgrade(s,'2-2'),false);
const price=D.price('2-2');s.xp=price.xp;s.silver=price.silver;assert.equal(D.unlock(s,'2-2'),true);assert.equal(s.xp,0);assert.equal(s.silver,0);assert.equal(D.unlock(s,'2-2'),false);assert.equal(D.clean(s).owned['2-2'],true);
const migrated=D.clean({version:1,levels:{'1-1':3},silver:600,xp:700});assert.equal(migrated.owned['1-1'],true);assert.equal(migrated.owned['2-2'],undefined);assert.equal(migrated.silver,600);
const gun=D.stats(D.tanks[0]),heavy=D.stats(D.tanks[2]);const front=D.penetration(gun,heavy,'front',1,100),rear=D.penetration(gun,heavy,'rear',1,100),angled=D.penetration(gun,heavy,'front',.35,100);assert.ok(rear.chance>front.chance);assert.ok(angled.chance<=front.chance);assert.equal(rear.color,'#70e899');assert.equal(angled.color,'#ff6262');
for(const m of Object.values(D.maps)){assert.ok(m.size>=560);assert.ok(m.size*.8>=448);}
console.log('PASS: research costs, double purchase, locked upgrades, persistence/migration, armor angles and zones, map scale.');
const profiles=new Set();
for(const tank of D.tanks){
 const base=D.stats(tank,1),upgraded=D.stats(tank,5);
 profiles.add(JSON.stringify(D.armorZones.map(z=>D.armorThickness(base,z))));
 for(const zone of D.armorZones){
  assert.equal(D.penetration(gun,base,zone,1,0).armor,D.armorThickness(base,zone),'Display and penetration share millimetres');
  assert.ok(D.armorThickness(upgraded,zone)>D.armorThickness(base,zone));
 }
 assert.ok(D.armorThickness(base,'lower')<D.armorThickness(base,'front'));
}
assert.equal(profiles.size,9);
assert.ok(D.armorThickness(D.tanks[4],'front')>D.armorThickness(D.tanks[7],'front'));
assert.ok(D.armorThickness(D.tanks[4],'turret')<D.armorThickness(D.tanks[7],'turret'));
console.log('PASS: nine armor profiles, distinct strengths, weak lower plates and upgraded thickness.');
