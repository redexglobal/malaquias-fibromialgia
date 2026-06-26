/* ============================================================
   MONITOR DE ERROS
   - CAPTURA: roda pra TODOS os usuários — qualquer erro de JavaScript
     (uncaught + promise rejeitada) é registrado na tabela erros_log.
   - PAINEL: aparece SÓ no painel da Natália (natalia@malaquias.com) —
     o painel que o Vilson deixa aberto. Lista os erros pra ele ver antes
     de virar reclamação. 100% aditivo. Requer SQL supabase/erros_log.sql.
   ============================================================ */
(function(){
'use strict';
const esc=s=>window._escHtml?window._escHtml(s):(s||'').toString().replace(/&/g,'&amp;').replace(/</g,'&lt;');
function _fmt(d){ if(!d) return ''; try{ return new Date(d).toLocaleString('pt-BR'); }catch(e){ return d; } }

/* ---------- CAPTURA (todos) ---------- */
const SEEN=new Set(); let _count=0; const MAX=30;
function _logErro(msg, origem){
  try{
    if(typeof sb==='undefined') return;
    msg=(msg||'').toString().slice(0,600);
    if(!msg) return;
    origem=(origem||'').toString();
    /* RUÍDO IGNORADO (2026-06-26): erros de EXTENSÕES do navegador da pessoa —
       MetaMask/carteiras cripto, tradutores, etc. — NÃO são do sistema e poluíam o
       painel. Também ruídos inofensivos do browser. Só registramos erro REAL do app. */
    const _ruido=/ResizeObserver loop|Script error\.?$|Non-Error promise|metamask|ethereum|web3|wallet|solana|phantom|coinbase|evmask|inpage\.js|contentscript|chrome-extension:\/\/|moz-extension:\/\/|safari-web-extension|extension context invalidated|cannot redefine property|requestprovider|failed to connect to metamask|object\.connect/i;
    if(_ruido.test(msg) || _ruido.test(origem)) return;
    const key=msg.slice(0,120);
    if(SEEN.has(key)) return; SEEN.add(key);
    if(_count++>=MAX) return;
    const prof=(typeof currentProfile!=='undefined'&&currentProfile)||{};
    let email=prof.email||null; try{ if(!email&&typeof currentUser!=='undefined'&&currentUser) email=currentUser.email; }catch(e){}
    sb.from('erros_log').insert({
      mensagem: msg,
      origem: (origem||'').toString().slice(0,300),
      url: location.href.slice(0,300),
      user_email: email,
      papel: prof.papel||null,
      ponto: prof.nome_ponto||null,
      user_agent: (navigator.userAgent||'').slice(0,200)
    }).then(()=>{}, ()=>{});
  }catch(e){}
}
window.addEventListener('error', function(e){ _logErro(e&&e.message, ((e&&e.filename)||'')+':'+((e&&e.lineno)||'')); });
window.addEventListener('unhandledrejection', function(e){ const r=e&&e.reason; _logErro((r&&r.message)||r||'promise rejeitada','unhandledrejection'); });

/* ---------- PAINEL (só Natália) ---------- */
function _ehNatalia(){ try{ return !!(typeof currentProfile!=='undefined'&&currentProfile&&currentProfile.email==='natalia@malaquias.com'); }catch(e){ return false; } }

async function _load(){
  const list=document.getElementById('mon-list'); if(!list) return;
  list.innerHTML='<div style="color:#94a3b8;padding:16px">Carregando...</div>';
  let rows=[];
  try{ const { data }=await sb.from('erros_log').select('*').order('criado_em',{ascending:false}).limit(200); rows=data||[]; }
  catch(e){ list.innerHTML='<div style="color:#b91c1c;padding:16px">Não consegui carregar (o SQL erros_log.sql já foi rodado?)</div>'; return; }
  const cc=document.getElementById('mon-count'); if(cc) cc.textContent=rows.length+' erro(s) registrados';
  if(!rows.length){ list.innerHTML='<div style="color:#15803d;padding:16px;background:#dcfce7;border-radius:10px;font-weight:600">✅ Nenhum erro registrado. Tudo limpo!</div>'; return; }
  list.innerHTML=rows.map(r=>`<div style="border:1px solid #e2e8f0;border-left:4px solid #ef4444;border-radius:8px;padding:10px 12px;margin-bottom:8px;background:#fff;color:#111">
    <div style="font-weight:700;color:#b91c1c;font-size:13px">${esc(r.mensagem)}</div>
    <div style="font-size:11px;color:#64748b;margin-top:4px">👤 ${esc(r.user_email||'?')} ${r.ponto?('· '+esc(r.ponto)):''} · 🕐 ${_fmt(r.criado_em)}</div>
    ${r.origem?`<div style="font-size:10px;color:#94a3b8;margin-top:2px">${esc(r.origem)}</div>`:''}
  </div>`).join('');
}
async function _checkBadge(){
  try{
    const desde=new Date(Date.now()-24*3600*1000).toISOString();
    const { count }=await sb.from('erros_log').select('id',{count:'exact',head:true}).gte('criado_em',desde);
    const b=document.getElementById('mon-badge'); if(b&&count){ b.textContent=count>99?'99+':String(count); b.style.display='inline-block'; }
  }catch(e){}
}
function _injetar(){
  if(!_ehNatalia()) return false;
  if(document.getElementById('sec-monitor-erros')) return true;
  const nav=document.getElementById('nav-admin-section')||document.getElementById('nav-principal-section');
  const main=document.querySelector('main.main');
  if(!nav||!main) return false;
  const ni=document.createElement('div'); ni.className='nav-item'; ni.setAttribute('data-section','monitor-erros');
  ni.innerHTML='<i class="fas fa-bug"></i> Monitor de Erros <span id="mon-badge" style="display:none;background:#ef4444;color:#fff;border-radius:10px;font-size:10px;font-weight:700;padding:2px 7px;margin-left:6px"></span>';
  ni.onclick=function(){ if(typeof showSection==='function') showSection('monitor-erros',ni); _load(); };
  nav.appendChild(ni);
  const sec=document.createElement('div'); sec.className='section'; sec.id='sec-monitor-erros';
  sec.innerHTML=`<h1 class="page-title"><i class="fas fa-bug"></i> Monitor de Erros</h1>
    <p style="color:var(--text-muted);margin:-6px 0 14px;font-size:13px">Erros que aconteceram no sistema (de qualquer usuária). Serve pra avisar o suporte antes de virar problema.</p>
    <div style="display:flex;gap:10px;margin-bottom:12px;align-items:center"><button id="mon-refresh" style="background:#475569;color:#fff;border:none;border-radius:8px;padding:9px 14px;font-weight:700;cursor:pointer">🔄 Atualizar</button><span id="mon-count" style="color:var(--text-muted);font-size:13px"></span></div>
    <div id="mon-list"></div>`;
  main.appendChild(sec);
  document.getElementById('mon-refresh').onclick=_load;
  _checkBadge();
  return true;
}
if(!_injetar()){
  const t=setInterval(()=>{ if(_injetar()) clearInterval(t); },800);
  setTimeout(()=>clearInterval(t),40000);
  window.addEventListener('malaquias:profile-ready',()=>_injetar(),{once:true});
}
})();
