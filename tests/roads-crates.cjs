'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),THREE=require('../vendor/three.min.js');
const source=fs.readFileSync(require.resolve('../src/game.js'),'utf8'),decor=new THREE.Group(),solids=[],obstacles=[];
const material=new THREE.MeshStandardMaterial(),context={THREE,Math,decor,wood:material,steel:material,desert:false,winter:false,arena:{size:560},height:()=>0,footprintSupport:()=>({low:0}),solidMeshes:solids,obstacles,Remaster:{material:()=>material},mesh:(geo,mat,parent)=>{const o=new THREE.Mesh(geo,mat);parent.add(o);return o;},box:(parent,w,h,d,x,y,z)=>{const o=new THREE.Mesh(new THREE.BoxGeometry(w,h,d),material);o.position.set(x,y,z);parent.add(o);return o;}};
const section=(start,end)=>source.slice(source.indexOf(start),source.indexOf(end,source.indexOf(start)+start.length));
vm.createContext(context);
vm.runInContext(section('function obstacle(', '\nfunction footprintSupport(')+section('function blocked(', '\nfunction makeNavigation(')+section('function route(points,','\n function tower(')+section('function supplies(','\n route('),context);
context.route([[0,0],[0,20],[15,30]],16,'road');const road=decor.children[0],p=road.geometry.attributes.position,uv=road.geometry.attributes.uv;
for(let i=0;i<p.count;i++){assert.ok(Math.abs(uv.getX(i)-p.getX(i)/8)<1e-5);assert.ok(Math.abs(uv.getY(i)-p.getZ(i)/8)<1e-5);}
for(let i=0;i<p.count;i+=4)assert.ok(Math.abs(uv.getX(i+1)-uv.getX(i))+Math.abs(uv.getY(i+1)-uv.getY(i))>.01,'Every road strip has non-collapsed UV coordinates');
context.supplies(20,30);assert.equal(obstacles.length,1);assert.equal(context.blocked(20,30,1),true);assert.equal(context.blocked(30,30,1),false);
const ray=new THREE.Raycaster(new THREE.Vector3(20,1,20),new THREE.Vector3(0,0,1),0,20);assert.ok(ray.intersectObjects(solids,false).length,'Crate stops a shell before it reaches the far side');
assert.equal(material.transparent,false);assert.equal(material.opacity,1);
global.THREE=THREE;global.window=global;global.GameData=require('../src/data.js');require('../src/remaster.js');
Remaster.batch(decor,[],true);decor.updateMatrixWorld(true);
assert.ok(ray.intersectObjects(solids,false).length,'Shell collision remains valid after scenery batching');
console.log('PASS: continuous road UVs, no collapsed strips, solid crate movement bounds and shell interception.');
