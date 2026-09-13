'use strict';
const assert=require('node:assert/strict'),crypto=require('node:crypto');
global.THREE=require('../vendor/three.min.js');
global.GameData=require('../src/data.js');
global.window=global;
global.document={createElement:()=>({getContext:()=>new Proxy({},{get:()=>()=>{}})})};
require('../src/remaster.js');
const silhouettes=new Set();
for(const spec of GameData.tanks){
 const model=Remaster.tank(spec),hash=crypto.createHash('sha256');
 model.group.updateMatrixWorld(true);
 assert.ok(model.hitMeshes.length>0,spec.name+' has hit geometry');
 for(const mesh of model.hitMeshes){
  assert.ok(mesh.parent,spec.name+' hit mesh survives batching');
  const positions=mesh.geometry.attributes.position.array;
  assert.ok(Array.from(positions).every(Number.isFinite));
  hash.update(Buffer.from(positions.buffer,positions.byteOffset,positions.byteLength));
 }
 silhouettes.add(hash.digest('hex'));
 const originals=model.hitMeshes.map(m=>m.material);
 Remaster.armorMask(model,true,spec);
 Remaster.armorMask(model,false,spec);
 model.hitMeshes.forEach((m,i)=>assert.equal(m.material,originals[i]));
 const muzzle=model.gunPivot.localToWorld(new THREE.Vector3(0,0,model.barrelLength+.5));
 assert.ok(muzzle.z>model.length/2,spec.name+' muzzle clears hull');
 model.turret.rotation.y=.7;model.gunPivot.rotation.x=-.1;
 model.wheels.forEach(w=>{w.rotation.x+=.5;assert.ok(w.parent);});
 model.group.updateMatrixWorld(true);
 console.log(spec.name+': '+model.group.userData.design+', '+model.wheels.length+' road wheels');
}
assert.equal(silhouettes.size,9,'All nine vehicles need different geometry');
console.log('PASS: nine distinct models, finite geometry, armor restoration, muzzle clearance and articulation.');
