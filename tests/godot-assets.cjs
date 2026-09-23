'use strict';
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../godot');
const manifest=JSON.parse(fs.readFileSync(path.join(root,'editor/source_manifest.json'),'utf8'));
assert.equal(manifest.tanks.length,12);
assert.equal(manifest.maps.length,4);
let objects=0,meshes=0;
for(const entry of [...manifest.tanks,...manifest.assets,...manifest.maps.flatMap(x=>x.objects)]){
 const file=path.join(root,entry.file),buffer=fs.readFileSync(file);
 assert.equal(buffer.readUInt32LE(0),0x46546c67,file);
 assert.equal(buffer.readUInt32LE(8),buffer.length,file);
 const json=JSON.parse(buffer.subarray(20,20+buffer.readUInt32LE(12)).toString());
 assert(json.meshes.length>0,file); meshes+=json.meshes.length;objects++;
 for(const image of json.images)assert(fs.existsSync(path.resolve(path.dirname(file),image.uri)),image.uri);
 for(const mesh of json.meshes)for(const primitive of mesh.primitives){
  const positions=json.accessors[primitive.attributes.POSITION];
  const indices=json.accessors[primitive.indices];
  assert(positions.count>0); assert.equal(indices.count%3,0);
 }
}
for(const map of manifest.maps.filter(m=>m.id!=='hangar')){
 assert.equal(map.spawns[0].length,7);
 assert.equal(map.spawns[1].length,7);
 assert(map.objects.reduce((n,x)=>n+x.solid_nodes.length,0)>80,map.id);
 const scene=fs.readFileSync(path.join(root,'scenes/levels',map.id+'.tscn'),'utf8');
 assert(scene.includes('Spawns/TeamA'));assert(scene.includes('StaticBody3D'));
 assert(scene.includes('res://assets/native/'));
}
for(const vehicle of manifest.tanks){
 const scene=fs.readFileSync(path.join(root,'scenes/vehicles',vehicle.id+'.tscn'),'utf8');
 assert(scene.includes('name="Muzzle"'));assert(scene.includes('res://resources/vehicles/'));
}
console.log(`PASS: ${objects} independent glTF assets, ${meshes} mesh objects, 12 vehicles, 3 authored battle maps.`);
