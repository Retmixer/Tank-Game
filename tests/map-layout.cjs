'use strict';
const assert=require('node:assert/strict');
const {execFileSync}=require('node:child_process');
if(!process.argv[2]){
 for(const map of ['training','desert','winter'])process.stdout.write(execFileSync(process.execPath,[__filename,map],{encoding:'utf8'}));
}else{
 global.THREE=require('../vendor/three.min.js');global.GameData=require('../src/data.js');
 const elements=new Map();class Element{constructor(){this.style={};this.children=[];this.hidden=false;this.value='';}set innerHTML(value){this._html=value;this.children=[];}get innerHTML(){return this._html;}querySelectorAll(){return [];}append(child){this.children.push(child);}addEventListener(){}getContext(){return new Proxy({},{get:()=>()=>{}});}}
 const el=id=>{if(!elements.has(id))elements.set(id,new Element());return elements.get(id);};
 global.window=global;global.innerWidth=1280;global.innerHeight=720;global.devicePixelRatio=1;global.location={protocol:'file:',hostname:''};
 global.document={getElementById:el,querySelector:el,createElement:()=>new Element(),exitPointerLock(){},addEventListener(){},head:new Element()};global.addEventListener=()=>{};
 global.Platform={load:()=>GameData.defaults(),save(){},gameplay(){},markReady(){},init(){},status:'test'};
 THREE.WebGLRenderer=class {constructor(){this.shadowMap={};this.info={render:{calls:0}};}setSize(){}setPixelRatio(){}setAnimationLoop(){}render(){}};
 require('../src/remaster.js');require('../src/game.js');
 el('mapSelect').value=process.argv[2];el('mapSelect').onchange();el('battleBtn').onclick();
 const audit=gameMapAudit();assert.equal(audit.spawns.length,6);
 for(const spawn of audit.spawns){assert.equal(spawn.blocked,false,`${audit.map}: blocked spawn at ${spawn.x},${spawn.z}`);assert.ok(spawn.relief<1.5,`${audit.map}: steep spawn (${spawn.relief.toFixed(2)}m)`);assert.ok(spawn.routeSteps>0,`${audit.map}: no path from spawn to center`);}
 console.log(`PASS: ${audit.map} — ${audit.obstacles} colliders, all spawns clear, level and connected.`);
}
