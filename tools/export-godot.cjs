/* Offline migration only. Exports original Three.js geometry; never runs in the game. */
'use strict';
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),crypto=require('node:crypto');
const {createCanvas}=require('@napi-rs/canvas');
const root=path.resolve(__dirname,'..'),out=path.join(root,'godot');
process.chdir(root);
if(fs.existsSync(path.join(out,'editor/source_manifest.json'))&&!process.argv.includes('--replace-assets'))throw new Error('Exported assets already exist. Commit your Blender/editor changes, then explicitly pass --replace-assets to replace the source assets.');
global.THREE=require('../vendor/three.min.js');global.window=global;
global.GameData=require('../src/data.js');global.Platform={load:()=>null};
Math.random=GameData.rng(2047);
global.document={createElement:()=>createCanvas(256,256),createElementNS:()=>({})};
THREE.TextureLoader.prototype.load=function(uri){const t=new THREE.Texture();t.userData.uri=uri;return t;};
// Skip only the final browser-wide batch; it destroys the logical prop hierarchy.
vm.runInThisContext(fs.readFileSync(path.join(root,'src/remaster.js'),'utf8').replace('batch(world,[],true);','/* Keep world objects for editor export. */'),{filename:'remaster-export-source.js'});
require('../assets/models/kenney.js');require('../src/map-assets.js');require('../src/map-dressing.js');
const safe=s=>s.replace(/[^a-zA-Z0-9_-]/g,'_');
const write=(file,data)=>{fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,data);};
const manifest={tanks:[],maps:[],materials:{},assets:[],source:'original src/game.js + src/remaster.js',version:2};
const imageNames=new Map();
function textureURI(t){
 if(!t)return null;
 if(t.userData.uri){const p=t.userData.uri;const dest=path.join(out,p);if(!fs.existsSync(dest)){fs.mkdirSync(path.dirname(dest),{recursive:true});fs.copyFileSync(path.join(root,p),dest);}return p;}
 if(t.image?.toBuffer){if(!imageNames.has(t)){const png=t.image.toBuffer('image/png'),name='assets/textures/atlas_'+crypto.createHash('sha256').update(png).digest('hex').slice(0,12)+'.png';write(path.join(out,name),png);imageNames.set(t,name);}return imageNames.get(t);}
 return null;
}
function glb(object,file){
 const doc={asset:{version:'2.0',generator:'Steel Frontier original asset exporter'},scene:0,scenes:[{nodes:[0]}],nodes:[],meshes:[],materials:[],accessors:[],bufferViews:[],buffers:[],images:[],textures:[],samplers:[{magFilter:9729,minFilter:9987,wrapS:10497,wrapT:10497}]};
 const chunks=[],mats=new Map(),images=new Map();let length=0;
 function access(array,n,type='FLOAT',position=false){
  const a=type==='UINT'?new Uint32Array(array):new Float32Array(array),b=Buffer.from(a.buffer);const index=doc.accessors.length;
  doc.bufferViews.push({buffer:0,byteOffset:length,byteLength:b.length});chunks.push(b);length+=b.length;
  const acc={bufferView:doc.bufferViews.length-1,componentType:type==='UINT'?5125:5126,count:a.length/n,type:n===1?'SCALAR':'VEC'+n};
  if(position){acc.min=Array(n).fill(Infinity);acc.max=Array(n).fill(-Infinity);for(let i=0;i<a.length;i++){acc.min[i%n]=Math.min(acc.min[i%n],a[i]);acc.max[i%n]=Math.max(acc.max[i%n],a[i]);}}
  doc.accessors.push(acc);return index;
 }
 function tex(t){const uri=textureURI(t);if(!uri)return undefined;if(!images.has(uri)){const i=doc.images.length;doc.images.push({uri:path.relative(path.dirname(file),path.join(out,uri)).replaceAll('\\','/')});doc.textures.push({source:i,sampler:0});images.set(uri,i);}return {index:images.get(uri)};}
 function mat(m){
  if(mats.has(m))return mats.get(m);
  const map=textureURI(m.map),normal=textureURI(m.normalMap),rough=textureURI(m.roughnessMap||m.bumpMap);
  const color=m.color?.toArray()||[1,1,1];const key=crypto.createHash('sha256').update(JSON.stringify([color,map,normal,rough,m.roughness,m.metalness,m.opacity,m.alphaTest,m.vertexColors])).digest('hex').slice(0,12);
  const name='surface_'+key;
  manifest.materials[name]={color,texture:map,normal,roughness_texture:rough,roughness:m.roughness??1,metallic:m.metalness||0,alpha:m.transparent?m.opacity:1,transparent:!!m.transparent,alpha_test:m.alphaTest||0,double_sided:m.side===THREE.DoubleSide,vertex_color:!!m.vertexColors,repeat:m.map?.repeat?.toArray()||[1,1]};
  const pbr={baseColorFactor:[...color,m.transparent?m.opacity:1],metallicFactor:m.metalness||0,roughnessFactor:m.roughness??1};const texture=tex(m.map);if(texture)pbr.baseColorTexture=texture;
  const entry={name,pbrMetallicRoughness:pbr,doubleSided:m.side===THREE.DoubleSide};const norm=tex(m.normalMap);if(norm)entry.normalTexture=norm;
  if(m.alphaTest){entry.alphaMode='MASK';entry.alphaCutoff=m.alphaTest;}else if(m.transparent)entry.alphaMode='BLEND';
  const idx=doc.materials.length;doc.materials.push(entry);mats.set(m,idx);return idx;
 }
 function node(o,rootNode=false){
  if(o.userData.collisionOnly||o.material?.colorWrite===false||o.isLight)return null;
  const idx=doc.nodes.length,entry={name:o.name||o.userData.asset||o.type};doc.nodes.push(entry);
  o.updateMatrix();entry.matrix=rootNode?new THREE.Matrix4().toArray():o.matrix.toArray();
  if(o.isMesh){
   const g=o.geometry,attrs={},names={position:'POSITION',normal:'NORMAL',uv:'TEXCOORD_0',color:'COLOR_0'};
   for(const [key,label] of Object.entries(names)){const a=g.attributes[key];if(!a)continue;const data=[];for(let i=0;i<a.count;i++)for(let c=0;c<a.itemSize;c++){const value=a.array[i*a.itemSize+c];data.push(key==='uv'&&c===1?1-value:value);}attrs[label]=access(data,a.itemSize,'FLOAT',key==='position');}
   const materials=Array.isArray(o.material)?o.material:[o.material],groups=g.groups.length?g.groups:[{start:0,count:g.index?g.index.count:g.attributes.position.count,materialIndex:0}];
   const primitives=groups.map(group=>{const count=Math.min(group.count,g.index?g.index.count:g.attributes.position.count),indices=[];for(let i=group.start;i<group.start+count;i++)indices.push(g.index?g.index.array[i]:i);return {attributes:attrs,indices:access(indices,1,'UINT'),material:mat(materials[group.materialIndex]||materials[0]),mode:4};});
   entry.mesh=doc.meshes.length;doc.meshes.push({name:entry.name,primitives});
  }
  const children=[];
  if(o.isInstancedMesh&&!rootNode){
   const baseMesh=entry.mesh;delete entry.mesh;entry.name='Instances_'+entry.name;
   const transform=new THREE.Matrix4();
   for(let i=0;i<o.count;i++){o.getMatrixAt(i,transform);children.push(doc.nodes.length);doc.nodes.push({name:'Instance_'+i,mesh:baseMesh,matrix:transform.toArray()});}
  }
  children.push(...o.children.map(c=>node(c)).filter(x=>x!==null));if(children.length)entry.children=children;return idx;
 }
 node(object,true);
 if(!doc.meshes.length)return false;
 doc.buffers=[{byteLength:length}];const bin=Buffer.concat(chunks);let json=Buffer.from(JSON.stringify(doc));json=Buffer.concat([json,Buffer.alloc((4-json.length%4)%4,32)]);
 const header=Buffer.alloc(20);header.writeUInt32LE(0x46546c67,0);header.writeUInt32LE(2,4);header.writeUInt32LE(28+json.length+bin.length,8);header.writeUInt32LE(json.length,12);header.writeUInt32LE(0x4e4f534a,16);
 const bh=Buffer.alloc(8);bh.writeUInt32LE(bin.length,0);bh.writeUInt32LE(0x004e4942,4);write(file,Buffer.concat([header,json,bh,bin]));return true;
}
for(const spec of GameData.tanks){
 const model=Remaster.tank(spec);model.group.name='TankVisual';model.turret.name='Turret';model.gunPivot.name='GunPivot';model.gunRecoil.name='Recoil';model.wheels.forEach((w,i)=>w.name='Wheel_'+i);
 const file='assets/vehicles/tank_'+spec.id+'.glb';glb(model.group,path.join(out,file));
 manifest.tanks.push({...spec,file,width:model.width,length:model.length,barrel_length:model.barrelLength,mesh_count:model.hitMeshes.filter(x=>!x.userData.collisionOnly).length});
 console.log('Vehicle',spec.id,spec.name);
}
// Preserve separately selectable map objects instead of browser merged batches.
Remaster.batch=()=>{};
let source=fs.readFileSync('src/game.js','utf8');source=source.slice(0,source.indexOf('function blocked('));
source=source.replace('mergeMeshes(set,[],true);','/* Keep workshop details individually editable. */');
source+=`\nconst exportBuilding=building;building=function(...args){const first=world.children.length;exportBuilding(...args);for(const object of world.children.slice(first))object.name=args[5]?'Factory':'House';};\n`;
source+=`\nfunction makeNavigation() {}\nwindow.PortSource={build(id){scene=new THREE.Scene();world=new THREE.Group();arena=D.maps[id];obstacles=[];obstacleBuckets=new Map();solidMeshes=[];save.settings.quality='high';buildMap();return {world,obstacles,height,ground};},hangar(){scene=new THREE.Scene();world=new THREE.Group();scene.userData.sun=new THREE.DirectionalLight();buildHangarSet();return {world,obstacles:[],ground:world.children.find(o=>o.geometry?.parameters?.width===70)};}};})();`;
vm.runInThisContext(source,{filename:'game-export-source.js'});
function exportWorld(id,result,data){
 const records=[],solid=new Set(result.obstacles.map(x=>x.object));
 result.obstacles.forEach((entry,i)=>{entry.object.name=(entry.object.name||entry.object.userData.asset||(entry.object.geometry?.type==='IcosahedronGeometry'?'Rock':'Cover'))+'_'+String(i).padStart(4,'0');});
 let count=0;
 for(const object of result.world.children){
  if(object.isLight)continue;
  const category=object===result.ground?'Terrain':object.name||object.userData.asset||(solid.has(object)?'Obstacle':'Scenery');
  const name=safe(category)+'_'+String(count++).padStart(4,'0'),file='assets/levels/'+id+'/'+name+'.glb';
  object.updateMatrix();const record={name,file,transform:object.matrix.toArray(),solid:solid.has(object)||category==='Terrain'};
  record.solid_nodes=[];object.traverse(o=>{if(solid.has(o))record.solid_nodes.push(o.name);});
  if(object.isInstancedMesh){record.instances=[];const m=new THREE.Matrix4();for(let i=0;i<object.count;i++){object.getMatrixAt(i,m);record.instances.push(m.toArray());}}
  if(glb(object,path.join(out,file)))records.push(record);
 }
 const spawns=[[],[]];if(result.height)for(let team=0;team<2;team++)for(let i=0;i<7;i++){const sign=team?1:-1,offset=(i-3)*8,x=sign*data.size*.4+offset,z=sign*data.size*.4-offset;spawns[team].push([x,result.height(x,z)+1,z]);}
 const entry={id,...data,objects:records,spawns};manifest.maps.push(entry);console.log('Level',id,records.length,'separate assets');
}
for(const [id,map] of Object.entries(GameData.maps))exportWorld(id,PortSource.build(id),map);
exportWorld('hangar',PortSource.hangar(),{name:'Ангар',size:70,sky:0x222a25,fog:0x222a25});
for(const [name] of Object.entries(KenneyModels)){const o=MapAssets.create(name,6,6,6);const file='assets/props/'+name+'.glb';glb(o,path.join(out,file));manifest.assets.push({name,file});}
write(path.join(out,'editor/source_manifest.json'),JSON.stringify(manifest));
console.log('Export finished. Original geometry is now independent glTF assets.');
