const http=require('node:http');
const fs=require('node:fs');
const path=require('node:path');
const os=require('node:os');
const crypto=require('node:crypto');
const root=__dirname;
const port=Number(process.env.STEEL_PORT)||8765;
const rooms=new Map();
const types={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.png':'image/png','.jpg':'image/jpeg','.txt':'text/plain; charset=utf-8'};
const json=(res,status,data)=>{res.writeHead(status,{'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store'});res.end(JSON.stringify(data));};
const body=req=>new Promise((resolve,reject)=>{let raw='';req.on('data',c=>{raw+=c;if(raw.length>65536)req.destroy();});req.on('end',()=>{try{resolve(raw?JSON.parse(raw):{});}catch(e){reject(e);}});req.on('error',reject);});
const code=()=>{const chars='ABCDEFGHJKLMNPQRSTUVWXYZ23456789';let value='';do{value='';for(let i=0;i<5;i++)value+=chars[crypto.randomInt(chars.length)];}while(rooms.has(value));return value;};
const token=()=>crypto.randomBytes(18).toString('hex');
const publicRoom=r=>({code:r.code,players:[...r.players.values()].map(p=>({name:p.name,role:p.role})),created:r.created});
function trimRooms(){const now=Date.now();for(const [key,r] of rooms){if(now-r.touched>1000*60*90)rooms.delete(key);else if(r.messages.length>1200)r.messages.splice(0,r.messages.length-700);}}
setInterval(trimRooms,60000).unref();
async function api(req,res,url){
 try{
  if(req.method==='POST'&&url.pathname==='/api/lan/create'){
   const data=await body(req),roomCode=code(),hostToken=token();
   const room={code:roomCode,created:Date.now(),touched:Date.now(),seq:0,messages:[],players:new Map([[hostToken,{name:String(data.name||'Командир').slice(0,24),role:'host'}]])};rooms.set(roomCode,room);return json(res,200,{...publicRoom(room),token:hostToken,role:'host'});
  }
  if(req.method==='POST'&&url.pathname==='/api/lan/join'){
   const data=await body(req),roomCode=String(data.code||'').toUpperCase().replace(/[^A-Z2-9]/g,''),room=rooms.get(roomCode);
   if(!room)return json(res,404,{error:'Лобби не найдено'});if(room.players.size>=2)return json(res,409,{error:'Лобби уже заполнено'});
   const guestToken=token();room.players.set(guestToken,{name:String(data.name||'Напарник').slice(0,24),role:'guest'});room.touched=Date.now();room.messages.push({seq:++room.seq,from:'server',type:'joined',data:publicRoom(room)});return json(res,200,{...publicRoom(room),token:guestToken,role:'guest'});
  }
  if(url.pathname==='/api/lan/room'){
   const room=rooms.get(String(url.searchParams.get('code')||'').toUpperCase());if(!room)return json(res,404,{error:'Лобби закрыто'});return json(res,200,publicRoom(room));
  }
  if(req.method==='POST'&&url.pathname==='/api/lan/send'){
   const data=await body(req),room=rooms.get(String(data.code||'').toUpperCase()),p=room?.players.get(String(data.token||''));if(!room||!p)return json(res,403,{error:'Нет доступа к лобби'});
   const type=String(data.type||'').slice(0,24);if(!['ready','start','input','snapshot','end','leave'].includes(type))return json(res,400,{error:'Неизвестное сообщение'});
   room.touched=Date.now();room.messages.push({seq:++room.seq,from:p.role,type,data:data.data??null});return json(res,200,{ok:true,seq:room.seq});
  }
  if(url.pathname==='/api/lan/poll'){
   const room=rooms.get(String(url.searchParams.get('code')||'').toUpperCase()),auth=String(url.searchParams.get('token')||''),p=room?.players.get(auth);if(!room||!p)return json(res,403,{error:'Связь с лобби потеряна'});
   const since=Math.max(0,Number(url.searchParams.get('since'))||0);room.touched=Date.now();return json(res,200,{room:publicRoom(room),messages:room.messages.filter(m=>m.seq>since&&m.from!==p.role),seq:room.seq});
  }
  if(url.pathname==='/api/lan/info'){
   const addresses=[];for(const entries of Object.values(os.networkInterfaces()))for(const a of entries||[])if(a.family==='IPv4'&&!a.internal)addresses.push(`http://${a.address}:${port}`);return json(res,200,{port,addresses});
  }
  return json(res,404,{error:'API route not found'});
 }catch(error){return json(res,400,{error:'Некорректный запрос',detail:String(error.message)});}
}
const server=http.createServer((req,res)=>{let url;try{url=new URL(req.url,'http://localhost');}catch{return res.writeHead(400).end();}if(url.pathname.startsWith('/api/'))return api(req,res,url);let file;try{file=path.resolve(root,'.'+decodeURIComponent(url.pathname));}catch{return res.writeHead(400).end();}if(file!==root&&!file.startsWith(root+path.sep))return res.writeHead(403).end();if(file===root)file=path.join(root,'index.html');fs.readFile(file,(err,data)=>{if(err){res.writeHead(404);return res.end('Not found');}res.writeHead(200,{'Content-Type':types[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store','X-Content-Type-Options':'nosniff'});res.end(data);});});
server.listen(port,'0.0.0.0',()=>{const addresses=[];for(const entries of Object.values(os.networkInterfaces()))for(const a of entries||[])if(a.family==='IPv4'&&!a.internal)addresses.push(`http://${a.address}:${port}`);console.log(`Steel Frontier: http://127.0.0.1:${port}`);for(const address of addresses)console.log(`LAN / Radmin: ${address}`);console.log('Оставьте это окно открытым на время сетевой игры.');});
