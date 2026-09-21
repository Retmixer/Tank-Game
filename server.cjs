const http=require('node:http');
const fs=require('node:fs');
const path=require('node:path');
const root=__dirname;
const port=Number(process.env.STEEL_PORT)||8765;
const types={'.ogg':'audio/ogg','.md':'text/plain; charset=utf-8','.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.png':'image/png','.jpg':'image/jpeg','.txt':'text/plain; charset=utf-8'};
const server=http.createServer((req,res)=>{let url;try{url=new URL(req.url,'http://localhost');}catch{return res.writeHead(400).end();}if(url.pathname.startsWith('/api/'))return res.writeHead(404).end('Not found');let file;try{file=path.resolve(root,'.'+decodeURIComponent(url.pathname));}catch{return res.writeHead(400).end();}if(file!==root&&!file.startsWith(root+path.sep))return res.writeHead(403).end();if(file===root)file=path.join(root,'index.html');fs.readFile(file,(err,data)=>{if(err){res.writeHead(404);return res.end('Not found');}res.writeHead(200,{'Content-Type':types[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store','X-Content-Type-Options':'nosniff'});res.end(data);});});
server.listen(port,'127.0.0.1',()=>console.log(`Стальной рубеж: http://127.0.0.1:${port}`));
