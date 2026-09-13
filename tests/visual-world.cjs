'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
global.THREE=require('../vendor/three.min.js');global.GameData=require('../src/data.js');global.window=global;
global.document={createElement:()=>({getContext:()=>new Proxy({},{get:()=>()=>{}})})};require('../src/remaster.js');
for(const arena of Object.values(GameData.maps)){
 const world=new THREE.Group();Remaster.vegetation(world,arena,(x,z)=>Math.sin(x*.02),[{x:50,z:50,r:20}],'low');
 const grass=world.getObjectByName('grass');assert.ok(grass?.count>100,'Every biome has grass or dry stalks');
 assert.ok(world.children.length<=3,'Vegetation is instanced rather than one draw call per plant');
 const matrix=new THREE.Matrix4(),p=new THREE.Vector3();
 for(let i=0;i<grass.count;i++){grass.getMatrixAt(i,matrix);p.setFromMatrixPosition(matrix);assert.ok(Math.abs(p.x)>6.9&&Math.abs(p.z)>5.9,'Roads stay clear');assert.ok(Math.hypot(p.x-50,p.z-50)>20,'No vegetation inside cover');assert.ok(Number.isFinite(p.y));}
}
const source=fs.readFileSync(require.resolve('../src/game.js'),'utf8'),start=source.indexOf('function updateCamera('),end=source.indexOf('\nfunction ',start+10);
const player={alive:true,length:6,team:0,spec:{zoom:3},group:new THREE.Group()},camera=new THREE.PerspectiveCamera(60,1,.15,2400);
const context={player,tanks:[player],camera,THREE,V:THREE.Vector3,viewYaw:0,viewPitch:0,aiming:true,ray:new THREE.Raycaster(),solidMeshes:[],height:()=>0,shake:0,Math};vm.createContext(context);vm.runInContext(source.slice(start,end),context);context.updateCamera(1/60);
assert.ok(camera.position.z>3,'Optics camera is in front of the hull');assert.ok(camera.position.y>=1.5);
const wall=new THREE.Mesh(new THREE.BoxGeometry(8,8,.2),new THREE.MeshBasicMaterial());wall.position.set(0,3,2);wall.updateMatrixWorld(true);context.solidMeshes=[wall];context.updateCamera(1/60);assert.ok(camera.position.z<2,'Optics must not see through cover');
context.solidMeshes=[];context.aiming=false;for(let i=0;i<60;i++)context.updateCamera(1/60);assert.ok(camera.position.z<-11,'Third person camera returns behind the tank');
console.log('PASS: biome vegetation, instancing, clear roads/cover, forward optics, wall obstruction and camera return.');
