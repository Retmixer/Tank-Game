'use strict';
const assert=require('node:assert/strict');
const D=require('../src/data.js'),tank=D.tanks[1],id=tank.id;
const old=D.defaults();delete old.modules;old.version=2;old.levels[id]=4;
const migrated=D.clean(old);
assert.deepEqual(migrated.modules[id],{gun:4,armor:4,engine:4,tracks:4});
assert.deepEqual(D.stats(tank,migrated.modules[id]),D.stats(tank,4),'Legacy vehicle upgrades retain every stat');
for(const key of Object.keys(D.moduleNames)){
 const save=D.defaults();save.silver=100000;const base=D.stats(tank,save.modules[id]);
 assert.ok(D.upgradeModule(save,id,key));assert.equal(save.silver,99700);
 for(const other of Object.keys(D.moduleNames))assert.equal(save.modules[id][other],other===key?2:1);
 const current=D.stats(tank,save.modules[id]);
 assert.equal(current.damage>base.damage,key==='gun');assert.equal(current.reload<base.reload,key==='gun');
 assert.equal(D.penetration(current,base).power>D.penetration(base,base).power,key==='gun');
 assert.equal(current.hp>base.hp,key==='armor');assert.equal(D.armorThickness(current,'front')>D.armorThickness(base,'front'),key==='armor');
 assert.equal(current.power>base.power,key==='engine');assert.equal(current.turn>base.turn,key==='tracks');
 assert.equal(current.speed,base.speed,'Class speed cap never increases');
 assert.deepEqual(D.clean(save).modules,save.modules,'Independent progress survives save/load');
 for(let i=0;i<3;i++)assert.ok(D.upgradeModule(save,id,key));
 const before=structuredClone(save);assert.equal(D.upgradeModule(save,id,key),false);assert.deepEqual(save,before);
}
const poor=D.defaults(),before=structuredClone(poor);
assert.equal(D.upgradeModule(poor,id,'gun'),false);assert.deepEqual(poor,before);
poor.silver=10000;assert.equal(D.upgradeModule(poor,'0-0','gun'),false);assert.equal(D.upgradeModule(poor,id,'unknown'),false);
assert.deepEqual(D.moduleLevels({gun:NaN,armor:99,tracks:-3,engine:'5'}),{gun:1,armor:5,engine:1,tracks:1});
console.log('PASS: independent modules, stat isolation, armor/penetration, migration, persistence, costs and caps.');
