/* TRAVA ANTI-DEPLOY-QUEBRADO — valida a sintaxe de TODO JS antes do push.
   Roda no hook git pre-push. Se achar erro, bloqueia o push (exit 1) pra um
   erro de digitação NUNCA chegar nas 50 colaboradoras em produção. */
const fs=require('fs'),vm=require('vm'),p=require('path');
const dir=__dirname;
let err=0,blocos=0;
const html=fs.readFileSync(p.join(dir,'index.html'),'utf8');
const re=/<script\b(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/gi;
let m;
while((m=re.exec(html))){ const code=m[1]; if(!code.trim())continue; blocos++;
  try{ new vm.Script(code); }
  catch(e){ err++; const ln=html.slice(0,m.index).split('\n').length; console.error(`❌ index.html bloco #${blocos} (linha ~${ln}): ${e.message}`); } }
for(const f of ['monitor-erros.js','carteirinhas.js','sw.js']){
  const fp=p.join(dir,f); if(!fs.existsSync(fp)) continue;
  try{ new vm.Script(fs.readFileSync(fp,'utf8')); }
  catch(e){ err++; console.error(`❌ ${f}: ${e.message}`); }
}
if(err){ console.error(`\n🚫 PUSH BLOQUEADO — ${err} erro(s) de sintaxe. Corrija antes de subir (o sistema NÃO vai pro ar quebrado).`); process.exit(1); }
console.log(`✅ Sintaxe OK (${blocos} blocos <script> + arquivos .js). Pode subir.`);
