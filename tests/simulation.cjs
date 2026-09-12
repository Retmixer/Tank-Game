'use strict';
const assert=require('node:assert/strict');
global.THREE=require('../vendor/three.min.js');
global.GameData=require('../src/data.js');
const D=GameData;
const elements=new Map(),windowEvents={},docEvents={};
class Element{
 constructor(){this.style={};this.children=[];this.hidden=false;this.value='';this.textContent='';this._html='';}
 set innerHTML(s){this._html=s;this.children=[];}get innerHTML(){return this._html;}
 querySelectorAll(){return [];}append(o){this.children.push(o);}prepend(o){this.children.unshift(o);}addEventListener(){}remove(){}get lastChild(){return this.children.at(-1);}
 getContext(){return new Proxy({},{get:()=>()=>{}});}
}
const el=id=>{if(!elements.has(id))elements.set(id,new Element());return elements.get(id);};
global.window=global;global.innerWidth=1366;global.innerHeight=768;global.devicePixelRatio=1;global.location={protocol:'file:',hostname:''};
global.document={getElementById:el,querySelector:el,createElement:()=>new Element(),exitPointerLock(){},addEventListener:(k,f)=>docEvents[k]=f,head:new Element()};
global.addEventListener=(k,f)=>windowEvents[k]=f;
let saved,loop;global.Platform={load:()=>D.defaults(),save:d=>{saved=structuredClone(d);},gameplay(){},markReady(){},init(){},status:'test'};
THREE.WebGLRenderer=class {constructor(){this.shadowMap={};this.info={render:{calls:0}};}setSize(){}setPixelRatio(){}setAnimationLoop(f){loop=f;}render(scene){scene.updateMatrixWorld(true);}};
require('../src/remaster.js');
require('../src/game.js');
assert.equal(gameStatus().state,'garage');assert.equal(el('upgradeBtn').disabled,true);
el('battleBtn').onclick();assert.equal(gameStatus().teams.length,6);
let now=0;const advance=seconds=>{for(let i=0;i<seconds*30;i++){now+=1000/30;loop(now);}};
const startZ=gameStatus().player.z;windowEvents.keydown({code:'KeyW'});windowEvents.keydown({code:'Space',preventDefault(){}});advance(4);assert.equal(gameStatus().player.z,startZ,'Countdown blocks movement');assert.equal(gameStatus().elapsed,0,'Countdown does not consume battle time');assert.ok(gameStatus().countdown>.9);assert.ok(Math.abs(gameStatus().teams[0].z-gameStatus().teams[3].z)>400,'Teams spawn over 400m apart');advance(1.2);windowEvents.keyup({code:'Space'});windowEvents.keydown({code:'KeyW'});advance(3);windowEvents.keyup({code:'KeyW'});assert.ok(gameStatus().player.z>startZ+20,'W must move tank forward');
el('pauseBtn').onclick();const paused=gameStatus();advance(2);assert.equal(gameStatus().elapsed,paused.elapsed,'Pause must stop time');assert.equal(gameStatus().player.z,paused.player.z,'Pause must stop movement');el('resume').onclick();
windowEvents.keydown({code:'Space',preventDefault(){}});advance(6);windowEvents.keyup({code:'Space'});assert.ok(gameStatus().player.reload>0,'Space fires and reloads');
advance(70);const combat=gameStatus();assert.ok(combat.teams.some(t=>t.hp<D.stats(D.tanks[t.team===1?3:0]).hp)||combat.state==='result','Bots must engage in combat');
if(combat.state==='battle'){el('pauseBtn').onclick();el('leave').onclick();}
assert.equal(gameStatus().state,'result');assert.ok(saved.silver>=300);assert.equal(saved.battles,1);const before=saved.silver;
el('returnGarage').onclick();el('upgradeBtn').onclick();assert.equal(gameStatus().levels['0-1'],2);assert.equal(gameStatus().silver,before-300);
for(const map of ['desert','winter']){el('mapSelect').value=map;el('mapSelect').onchange();el('battleBtn').onclick();advance(3);assert.equal(gameStatus().state,'battle');assert.equal(gameStatus().teams.length,6);el('pauseBtn').onclick();el('leave').onclick();el('returnGarage').onclick();}
console.log('PASS: hangar, all 3 maps, 3v3, movement, pause, shooting/reload, bot combat, rewards, upgrade, return to hangar.');
console.log(JSON.stringify({combat,silver:saved.silver,battles:saved.battles},null,2));
