const assert=require('node:assert/strict'),D=require('../src/data.js');
const s=D.defaults();assert.equal(Object.keys(s.owned).length,1);assert.equal(D.unlock(s,'2-2'),false);assert.equal(D.upgrade(s,'2-2'),false);
const price=D.price('2-2');s.xp=price.xp;s.silver=price.silver;assert.equal(D.unlock(s,'2-2'),true);assert.equal(s.xp,0);assert.equal(s.silver,0);assert.equal(D.unlock(s,'2-2'),false);assert.equal(D.clean(s).owned['2-2'],true);
const migrated=D.clean({version:1,levels:{'1-1':3},silver:600,xp:700});assert.equal(migrated.owned['1-1'],true);assert.equal(migrated.owned['2-2'],undefined);assert.equal(migrated.silver,600);
const gun=D.stats(D.tanks[0]),heavy=D.stats(D.tanks[2]);const front=D.penetration(gun,heavy,'front',1,100),rear=D.penetration(gun,heavy,'rear',1,100),angled=D.penetration(gun,heavy,'front',.35,100);assert.ok(rear.chance>front.chance);assert.ok(angled.chance<=front.chance);assert.equal(rear.color,'#70e899');assert.equal(angled.color,'#ff6262');
for(const m of Object.values(D.maps)){assert.ok(m.size>=560);assert.ok(m.size*.8>=448);}
console.log('PASS: research costs, double purchase, locked upgrades, persistence/migration, armor angles and zones, map scale.');
