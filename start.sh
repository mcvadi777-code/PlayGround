#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
PROJECT_ROOT="$(/usr/bin/time -p pwd)"
PORT="${PORT:-3000}"
/usr/bin/time -p test -f dist/index.html
if [ -f package.json ]; then /usr/bin/time -p npm install --no-audit --no-fund; fi
if [ -f package.json ] && /usr/bin/time -p node -e "process.exit(require('./package.json').scripts&&require('./package.json').scripts.build?0:1)"; then /usr/bin/time -p npm run build; fi
/usr/bin/time -p node -e '
const fs=require("fs"),path=require("path");
const root=process.cwd();
const dir=path.join(root,"dist");
const out=process.env.OPENCODE_WEB_DIR||"/home/runner/work/_temp/omgithub-web";
fs.mkdirSync(out,{recursive:true});
fs.writeFileSync(path.join(out,"deployment-output.json"),JSON.stringify({project:root,directory:dir}));
console.log("deployment-output.json written:",path.join(out,"deployment-output.json"));
'
/usr/bin/time -p node -e '
const http=require("http"),fs=require("fs"),path=require("path");
const root=path.join(process.cwd(),"dist");
const port=Number(process.env.PORT||3000);
const mime={".html":"text/html; charset=utf-8",".js":"application/javascript; charset=utf-8",".css":"text/css; charset=utf-8",".json":"application/json",".svg":"image/svg+xml",".png":"image/png",".jpg":"image/jpeg",".jpeg":"image/jpeg",".webp":"image/webp",".ico":"image/x-icon",".txt":"text/plain; charset=utf-8"};
const server=http.createServer((req,res)=>{
  try{
    const url=new URL(req.url,"http://localhost");
    let p=decodeURIComponent(url.pathname);
    if(p.endsWith("/"))p+="index.html";
    const file=path.resolve(root,"."+p);
    if(file!==root&&!file.startsWith(root+"/")){res.writeHead(404);res.end("Not found");return;}
    let target=file;
    if(!fs.existsSync(target)){target=path.join(root,"index.html");}
    const stat=fs.statSync(target);
    if(stat.isDirectory())target=path.join(target,"index.html");
    const data=fs.readFileSync(target);
    res.writeHead(200,{"Content-Type":mime[path.extname(target).toLowerCase()]||"application/octet-stream","Cache-Control":"no-cache"});
    res.end(data);
  }catch(e){res.writeHead(404);res.end("Not found");}
});
server.listen(port,"0.0.0.0",()=>console.log("Serving "+root+" on port "+port));
'
