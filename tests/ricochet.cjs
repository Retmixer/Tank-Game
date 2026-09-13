'use strict';
const assert=require('node:assert/strict'),D=require('../src/data.js');
const glancing=D.ricochetVelocity({x:100,y:0,z:20},{x:-1,y:0,z:0},.2,0);
assert.ok(glancing,'Glancing non-penetration must ricochet');
assert.ok(glancing.x<0&&glancing.z>0,'Reflection reverses the normal component and keeps the tangent component');
assert.ok(Math.hypot(glancing.x,glancing.y,glancing.z)<Math.hypot(100,0,20),'Armor impact removes shell energy');
assert.equal(D.ricochetVelocity({x:100,y:0,z:0},{x:-1,y:0,z:0},.8,0),null,'Near-normal impact must stop instead of ricocheting');
assert.equal(D.ricochetVelocity({x:100,y:0,z:20},{x:-1,y:0,z:0},.2,2),null,'Bounce count prevents endless ricochets');
console.log('PASS: physical reflection, energy loss, angle threshold and bounce limit.');
