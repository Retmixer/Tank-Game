'use strict';
const assert=require('node:assert/strict'),D=require('../src/data.js');
assert.equal(D.collisionRetention(1,0,3,0),0,'Front impact must stop the tank');
assert.equal(D.collisionRetention(1,0,1,3),.16,'Side scrape must bleed most of the speed');
assert.equal(D.collisionRetention(-1,0,3,0),1,'Backing away from a contact stays possible');
assert.equal(D.collisionRetention(0,0,3,0),1,'Stationary contact introduces no motion');
console.log('PASS: head-on stop, shallow side scrape, retreat and stationary contact.');
