'use strict';
const assert=require('node:assert/strict');
global.THREE=require('../vendor/three.min.js');
global.GameData=require('../src/data.js');
const D=GameData;Math.random=D.rng(9192026);
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
let saved,loop;global.Platform={load:()=>{const save=D.defaults();save.settings.quality='low';return save;},save:d=>{saved=structuredClone(d);},gameplay(){},markReady(){},init(){},status:'test'};
THREE.WebGLRenderer=class {constructor(){this.shadowMap={};this.info={render:{calls:0}};}setSize(){}setPixelRatio(){}setAnimationLoop(f){loop=f;}render(scene){scene.updateMatrixWorld(true);}};
require('../src/remaster.js');
THREE.TextureLoader=class{load(){return new THREE.Texture();}};require('../assets/models/kenney.js');require('../src/map-assets.js');require('node:vm').runInThisContext(require('node:fs').readFileSync(require.resolve('../src/game.js'),'utf8').replace('function startBattle(options={}){',"function startBattle(options={}){options.map=global.testMap||'training';"));
assert.equal(gameStatus().state,'garage');assert.equal(gameStatus().silver,99999);assert.equal(el('upgradeBtn').disabled,false);
el('battleBtn').onclick();assert.equal(gameStatus().teams.length,6);
let now=0;const advance=seconds=>{for(let i=0;i<seconds*30;i++){now+=1000/30;loop(now);}};
const startZ=gameStatus().player.z;windowEvents.keydown({code:'KeyW'});windowEvents.keydown({code:'Space',preventDefault(){}});advance(4);assert.equal(gameStatus().player.z,startZ,'Countdown blocks movement');assert.equal(gameStatus().elapsed,0,'Countdown does not consume battle time');assert.ok(gameStatus().countdown>.9);assert.ok(Math.abs(gameStatus().teams[0].z-gameStatus().teams[3].z)>400,'Teams spawn over 400m apart');advance(1.2);windowEvents.keyup({code:'Space'});windowEvents.keydown({code:'KeyW'});advance(3);windowEvents.keyup({code:'KeyW'});assert.ok(gameStatus().player.z>startZ+3&&gameStatus().player.z<startZ+20,'W accelerates progressively during the first three seconds');
el('pauseBtn').onclick();const paused=gameStatus();advance(2);assert.equal(gameStatus().elapsed,paused.elapsed,'Pause must stop time');assert.equal(gameStatus().player.z,paused.player.z,'Pause must stop movement');el('resume').onclick();
windowEvents.keydown({code:'Space',preventDefault(){}});advance(6);windowEvents.keyup({code:'Space'});assert.ok(gameStatus().player.reload>0,'Space fires and reloads');
advance(70);for(let i=0;i<6&&gameStatus().state==='battle'&&!gameStatus().teams.some(t=>t.hp<t.maxHp);i++)advance(20);const combat=gameStatus();assert.ok(combat.teams.some(t=>t.hp<t.maxHp)||combat.state==='result','Bots must engage in combat');
if(combat.state==='battle'){el('pauseBtn').onclick();el('leave').onclick();}
assert.equal(gameStatus().state,'result');assert.ok(saved.silver>=300);assert.equal(saved.battles,1);assert.ok(el('modalContent').innerHTML.includes('results-table'),'Results show ranking table');assert.ok(el('modalContent').innerHTML.includes('Ваше место'),'Player rank displayed');const before=saved.silver;
el('returnGarage').onclick();el('upgradeBtn').onclick();assert.equal(gameStatus().levels['0-1'],2);assert.equal(gameStatus().silver,before-300);
assert.deepEqual(saved.modules['0-1'],{gun:2,armor:1,engine:1,tracks:1},'Garage upgrades only the selected gun');
el('module-engine').onclick();el('upgradeBtn').onclick();assert.deepEqual(saved.modules['0-1'],{gun:2,armor:1,engine:2,tracks:1});assert.equal(gameStatus().silver,before-600);
for(const [map,size] of [['desert',5],['winter',7]]){global.testMap=map;el('modeSelect').value=String(size);el('modeSelect').onchange();el('battleBtn').onclick();advance(3);assert.equal(gameStatus().state,'battle');assert.equal(gameStatus().teams.length,size*2);assert.ok(gameStatus().teams.filter(t=>t.id!=='0-1').every(t=>t.role));const balance=gameStatus().silver;el('pauseBtn').onclick();el('leave').onclick();assert.equal(gameStatus().silver,balance,'Early exit awards no silver');el('returnGarage').onclick();}
console.log('PASS: hangar, all 3 maps, 3v3, movement, pause, shooting/reload, bot combat, rewards, upgrade, return to hangar.');
console.log(JSON.stringify({combat,silver:saved.silver,battles:saved.battles},null,2));
