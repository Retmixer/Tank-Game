'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),THREE=require('../vendor/three.min.js');
const source=fs.readFileSync(require.resolve('../src/game.js'),'utf8');
const extract=name=>{const a=source.indexOf('function '+name+'('),b=source.indexOf('\nfunction ',a+10);return source.slice(a,b);};
const context={THREE,V:THREE.Vector3,Math,arena:{size:560},save:{settings:{quality:'high'}},terrainHeightSmooth:(x,z)=>Math.sin(x*.2)*3+Math.cos(z*.11)*2,obstacles:[]};vm.createContext(context);
vm.runInContext(extract('height')+extract('aimGun')+extract('blocked'),context);
const step=560/220,x0=8*step-280,z0=42*step-280;
for(const [u,v] of [[.2,.3],[.8,.6]]){const f=context.terrainHeightSmooth,a=f(x0,z0),b=f(x0,z0+step),d=f(x0+step,z0),c=f(x0+step,z0+step),expected=u+v<=1?a+(d-a)*u+(b-a)*v:b*(1-u)+d*(1-v)+c*(u+v-1);assert.ok(Math.abs(context.height(x0+u*step,z0+v*step)-expected)<1e-8);}
context.obstacles=[{x:0,z:0,r:30,bounds:new THREE.Box3(new THREE.Vector3(-4,-1,-25),new THREE.Vector3(4,10,25))}];
assert.equal(context.blocked(12,0,2),false,'Long building must not block a road beside its actual walls');assert.equal(context.blocked(4.5,0,2),true,'Actual wall remains solid');
const group=new THREE.Group(),turret=new THREE.Group(),gunPivot=new THREE.Group();group.add(turret);turret.add(gunPivot);turret.position.y=2;gunPivot.position.set(0,.3,.6);const tank={group,turret,gunPivot};
for(const roll of [0,.2,-.2]){group.rotation.z=roll;const target=new THREE.Vector3(.1,2,1);let previous;
 for(let i=0;i<200;i++){const before=gunPivot.rotation.x;context.aimGun(tank,target,1/60);assert.ok(Math.abs(gunPivot.rotation.x-before)<=.65/60+1e-9);if(i>150&&previous!==undefined)assert.ok(Math.abs(gunPivot.rotation.x-previous)<1e-9,'Near-wall aim converges without oscillation');previous=gunPivot.rotation.x;}
}
console.log('PASS: visible terrain interpolation, long-building clearance and stable near-wall gun elevation on slopes.');
