'use strict';
// Recoverably archive obsolete artifacts from this exporter. Default: dry run.
const fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'..'),godot=path.join(root,'godot');
const manifest=JSON.parse(fs.readFileSync(path.join(godot,'editor/source_manifest.json'),'utf8'));
const keep=new Set([...manifest.tanks,...manifest.assets,...manifest.maps.flatMap(x=>x.objects)].map(x=>x.file));
function walk(dir){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(dir,e.name)):[path.join(dir,e.name)]);}
for(const scene of walk(path.join(godot,'scenes')).filter(x=>x.endsWith('.tscn'))){
 const text=fs.readFileSync(scene,'utf8');
 for(const match of text.matchAll(/path="res:\/\/(assets\/native\/[^"\n]+)"/g))keep.add(match[1]);
}
const generated=['assets/levels','assets/vehicles','assets/props','assets/native'];
const stale=generated.flatMap(dir=>walk(path.join(godot,dir))).filter(file=>{
 const relative=path.relative(godot,file).replaceAll('\\','/');
 return !keep.has(relative.replace(/\.import$/,''));
});
console.log(`${stale.length} obsolete generated files; ${keep.size} current referenced assets.`);
if(!process.argv.includes('--archive'))process.exit(0);
const backup=path.join(root,'work','godot-obsolete-export-'+Date.now());
for(const file of stale){
 const absolute=path.resolve(file);
 if(!generated.some(dir=>absolute.startsWith(path.join(godot,dir)+path.sep)))throw Error('Unsafe target: '+file);
 const destination=path.join(backup,path.relative(godot,absolute));
 fs.mkdirSync(path.dirname(destination),{recursive:true});fs.renameSync(absolute,destination);
}
console.log('Recoverable backup: '+backup);
