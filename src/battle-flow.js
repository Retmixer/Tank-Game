(() => {
 'use strict';
 const $=id=>document.getElementById(id);
 const captions={training:['УЧЕБНЫЙ ПОЛИГОН','ОТРАБАТЫВАЙТЕ ТАКТИКУ'],desert:['ПУСТЫННЫЙ ПОЛИГОН','ЖАРКИЕ СРАЖЕНИЯ'],winter:['ЗИМНИЙ ЗАВОД','ХОЛОД НЕ ПРОЩАЕТ ОШИБОК']};
 document.querySelectorAll('.map-choice').forEach(button=>{const [title,subtitle]=captions[button.dataset.map];button.innerHTML=`<span class="map-photo" aria-hidden="true"></span><span class="map-caption"><strong>${title}</strong><small>${subtitle}</small></span><span class="choice-action">ВЫБРАТЬ</span>`;});
 let busy=false,selected='training',pending=0;
 function progress(value){$('loadingFill').style.width=value+'%';$('loadingPercent').textContent=Math.round(value)+'%';$('loadingProgress').setAttribute('aria-valuenow',Math.round(value));}
 const manager=THREE.DefaultLoadingManager;
 manager.onStart=()=>{pending++;};manager.onLoad=()=>{pending=0;};manager.onProgress=(url,done,total)=>progress(Math.min(94,20+74*done/Math.max(1,total)));
 function select(map){selected=map;document.querySelectorAll('.map-choice').forEach(b=>{const active=b.dataset.map===map;b.setAttribute('aria-pressed',String(active));b.querySelector('.choice-action').textContent=active?'ВЫБРАНО':'ВЫБРАТЬ';});$('mapSelect').value=map;$('mapSelect').onchange?.();}
 function hideSetup(){$('battleSetup').hidden=true;$('garage').inert=false;}
 function close(){if(busy)return;hideSetup();$('battleBtn').focus();}
 function open(){if(busy)return;select($('mapSelect').value||selected);$('setupDifficulty').value=$('botDifficulty').value||'normal';$('setupMode').value=$('modeSelect').value||'3';$('garage').inert=true;$('battleSetup').hidden=false;$('setupBack').focus();}
 const frame=()=>new Promise(resolve=>requestAnimationFrame(resolve));
 async function finish(start){
  while(pending&&performance.now()-start<15000)await new Promise(r=>setTimeout(r,40));
  const remaining=650-(performance.now()-start);if(remaining>0)await new Promise(r=>setTimeout(r,remaining));
  progress(100);await new Promise(r=>setTimeout(r,150));$('loading').hidden=true;busy=false;
 }
 async function load(build,done){
  if(busy)return;busy=true;hideSetup();$('loading').hidden=false;progress(5);
  const start=performance.now();await frame();await frame();
  try{progress(20);build();progress(92);await finish(start);done?.();}
  catch(error){busy=false;$('loading').hidden=true;$('garage').hidden=false;console.error(error);alert('Не удалось загрузить карту. Вернитесь в ангар и повторите попытку.');}
 }
 document.querySelectorAll('.map-choice').forEach(button=>button.onclick=()=>select(button.dataset.map));
 $('setupBack').onclick=close;
 $('setupDifficulty').onchange=()=>{$('botDifficulty').value=$('setupDifficulty').value;$('botDifficulty').onchange?.();};
 $('setupMode').onchange=()=>{$('modeSelect').value=$('setupMode').value;$('modeSelect').onchange?.();};
 $('setupStart').onclick=()=>{if(busy)return;hideSetup();window.BattleFlow.launch?.();};
 document.addEventListener('keydown',event=>{
  if($('battleSetup').hidden)return;
  if(event.code==='Escape'){event.preventDefault();close();}
  if(event.code==='Tab'){
   const controls=[...$('battleSetup').querySelectorAll('button,select')];
   const first=controls[0],last=controls[controls.length-1];
   if(event.shiftKey&&document.activeElement===first){event.preventDefault();last.focus();}
   else if(!event.shiftKey&&document.activeElement===last){event.preventDefault();first.focus();}
  }
 });
 window.BattleFlow={open,load,ready:()=>finish(performance.now()),launch:null};
})();
