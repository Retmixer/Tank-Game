'use strict';
const assert=require('node:assert/strict'),crypto=require('node:crypto');
global.THREE=require('../vendor/three.min.js');
global.GameData=require('../src/data.js');
global.window=global;
global.document={createElement:()=>({getContext:()=>new Proxy({},{get:()=>()=>{}})})};
require('../src/remaster.js');
const source=require('node:fs').readFileSync(require('node:path').join(__dirname,'../src/game.js'),'utf8');
const wreckSource=source.slice(source.indexOf('function makeWreck('),source.indexOf('function damageTank('));
const makeWreck=require('node:vm').runInNewContext('('+wreckSource.trim()+')',{mat:color=>new THREE.MeshStandardMaterial({color})});
const silhouettes=new Set();
for(const spec of GameData.tanks){
 const model=Remaster.tank(spec),hash=crypto.createHash('sha256');
 model.group.updateMatrixWorld(true);
 for(const target of [new THREE.Vector3(0,1,0),new THREE.Vector3(model.width*.5,.65,0)]){
  for(const direction of [new THREE.Vector3(1,0,0),new THREE.Vector3(-1,0,0),new THREE.Vector3(0,0,1),new THREE.Vector3(0,0,-1)]){
   const ray=new THREE.Raycaster(target.clone().addScaledVector(direction,15),direction.clone().negate(),0,30);
   assert.ok(ray.intersectObjects(model.collisionMeshes,false).length,spec.name+' closed collision from every side');
  }
 }
 const insideRay=new THREE.Raycaster(new THREE.Vector3(0,1,0),new THREE.Vector3(0,0,1),0,10);
 assert.ok(insideRay.intersectObjects(model.collisionMeshes,false).length,'Inside-origin shells hit an exit surface');
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
 makeWreck(model);
 assert.equal(model.alive,false);
 model.collisionMeshes.forEach(m=>assert.equal(m.material.colorWrite,false,'Wreck collision stays invisible'));
 const wreckRay=new THREE.Raycaster(new THREE.Vector3(0,1,15),new THREE.Vector3(0,0,-1),0,30);
 assert.ok(wreckRay.intersectObjects(model.hitMeshes,false).length,'Destroyed vehicle still blocks shells');
 console.log(spec.name+': '+model.group.userData.design+', '+model.wheels.length+' road wheels');
}
assert.equal(silhouettes.size,9,'All nine vehicles need different geometry');
const a={width:3,length:6,yaw:0,group:{position:{x:0,z:0}}},b={...a,group:{position:{x:0,z:5.5}}};
assert.ok(Remaster.overlaps(a,0,0,b),'Long hull ends collide');
b.group.position={x:4.1,z:0};assert.ok(!Remaster.overlaps(a,0,0,b),'Parallel tanks fit side by side');
b.yaw=Math.PI/2;assert.ok(Remaster.overlaps(a,0,0,b),'Rotated hull uses its length');
console.log('PASS: nine distinct models, finite geometry, armor restoration, muzzle clearance and articulation.');
