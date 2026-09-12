/* Optional Yandex bridge. The playable build and its assets also work offline. */
window.Platform={
 sdk:null,player:null,ready:false,active:false,cloudTimer:null,status:'● Локальное сохранение',
 load(){try{return GameData.clean(JSON.parse(localStorage.getItem('steel-frontier-v1')));}catch{return GameData.defaults();}},
 save(data){data.updated=Date.now();try{localStorage.setItem('steel-frontier-v1',JSON.stringify(data));}catch{this.status='● Сохранение в памяти — хранилище недоступно';}if(this.player){clearTimeout(this.cloudTimer);this.cloudTimer=setTimeout(()=>this.player.setData({progress:data},true).catch(()=>{this.status='● Локально сохранено · облако недоступно';}),1200);}},
 gameplay(active){this.active=active;try{this.sdk?.features?.GameplayAPI?.[active?'start':'stop']();}catch{}},
 markReady(){this.ready=true;try{this.sdk?.features?.LoadingAPI?.ready();}catch{}},
 async init(onCloud,onPause){
  if(location.protocol==='file:'||['localhost','127.0.0.1'].includes(location.hostname))return;
  try{
   await new Promise((resolve,reject)=>{const script=document.createElement('script');script.src='/sdk.js';script.onload=resolve;script.onerror=reject;document.head.append(script);});
   this.sdk=await YaGames.init();if(this.ready)this.sdk.features?.LoadingAPI?.ready();if(this.active)this.sdk.features?.GameplayAPI?.start();
   this.sdk.on('game_api_pause',()=>onPause());
   // Resumption is explicit through the pause button: gameplay stays stopped until then.
   this.sdk.on('game_api_resume',()=>{});
   const started=Date.now();this.player=await this.sdk.getPlayer({scopes:false});const data=await this.player.getData(['progress']);
   this.status='● Локальное + облачное сохранение';if(data.progress)onCloud(GameData.clean(data.progress),started);
  }catch{this.status='● Локальное сохранение';}
 }
};
