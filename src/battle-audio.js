/* Downloaded local sounds. Attribution and original filenames: assets/CREDITS.md. */
(() => {
 let context,output;const buffers={},loops={},failures=[];
 function attach(ctx,destination){
  if(context)return;context=ctx;output=destination;
  for(const name of ['engine','wind','shot','hit','boom'])fetch(`assets/audio/${name}.ogg`).then(r=>{if(!r.ok)throw Error(r.status);return r.arrayBuffer();}).then(b=>context.decodeAudioData(b)).then(b=>{buffers[name]=b;}).catch(()=>failures.push(name));
 }
 function play(type,volume=1,pitch=1,pan=0){
  if(!buffers[type]||context.state!=='running')return false;
  const source=context.createBufferSource(),gain=context.createGain();source.buffer=buffers[type];source.playbackRate.value=Math.max(.5,Math.min(1.6,pitch));gain.gain.value=volume*({shot:.75,hit:.6,boom:.8}[type]||.4);source.connect(gain);
  let panner;if(context.createStereoPanner){panner=context.createStereoPanner();panner.pan.value=Math.max(-1,Math.min(1,pan));gain.connect(panner);panner.connect(output);}else gain.connect(output);
  source.onended=()=>{source.disconnect();gain.disconnect();panner?.disconnect();};source.start();return true;
 }
 function loop(name,level,rate=1){
  if(!context||!buffers[name])return;
  if(!loops[name]&&level>0){const node=context.createBufferSource(),gain=context.createGain();node.buffer=buffers[name];node.loop=true;node.connect(gain);gain.connect(output);gain.gain.value=0;node.start();loops[name]={node,gain};}
  const item=loops[name];if(!item)return;item.gain.gain.setTargetAtTime(level,context.currentTime,.12);item.node.playbackRate.setTargetAtTime(rate,context.currentTime,.2);
 }
 function update(t,biome,active){
  const moving=Math.min(1,Math.abs(t?.speed||0)/Math.max(1,t?.spec.speed||1));
  const load=Math.abs(t?.throttle||0),gear=Math.min(3,Math.floor(moving*4));
  // Distinct engine note by vehicle mass, changing RPM under load and gear shifts.
  const rpm=.78+moving*.42-gear*.07+load*.16;
  loop('engine',active&&t?.alive?.22+load*.08+moving*.08:0,rpm*Math.pow(32/(t?.spec.mass||32),.15));
  loop('wind',active?(biome==='desert'?.16:biome==='winter'?.2:.1):0,biome==='winter'?.88:1);
 }
 window.BattleAudio={attach,play,update,has:name=>!!buffers[name],status:()=>({loaded:Object.keys(buffers),failed:failures.slice()})};
})();
