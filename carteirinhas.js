/* ============================================================
   ABA CARTEIRINHAS (AGF) — Fibromialgia / Doenças Crônicas
   - Gera carteirinha (frente + verso) do paciente, QR no lugar da foto.
   - Botão "Gerar" por paciente na busca -> popup escolhe modelo -> PDF/Imagem/WhatsApp.
   - Export: Imprimir / PDF / Imagem / WhatsApp (compartilhamento nativo no celular).
   100% aditivo. Admin + colaborador. Requer SQL supabase/carteirinhas.sql.
   ============================================================ */
(function(){
'use strict';
const BASE_URL = location.origin;
const TIPOS = { fibromialgia:{titulo:'Fibromialgia', cor:'#1e9e3e', pref:'FIB'}, cronicas:{titulo:'Doenças Crônicas', cor:'#1e9e3e', pref:'DC'} };
const nrm = s => window._normNomeDup ? window._normNomeDup(s) : (s||'').toLowerCase().trim();
const dig = s => (s||'').toString().replace(/\D/g,'');
const esc = s => window._escHtml ? window._escHtml(s) : (s||'').toString().replace(/&/g,'&amp;').replace(/</g,'&lt;');
function fmtData(d){ if(!d) return ''; const p=String(d).slice(0,10).split('-'); return p.length===3?`${p[2]}/${p[1]}/${p[0]}`:d; }
function fmtCpf(c){ const d=dig(c); return d.length===11? d.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/,'$1.$2.$3-$4'): (c||''); }
let _sel=null, _tipo='fibromialgia', _token=null, _renderedOnce=false;

/* ---------- lazy libs ---------- */
function _loadScript(src){ return new Promise((res,rej)=>{ const s=document.createElement('script'); s.src=src; s.onload=res; s.onerror=()=>rej(new Error('falha '+src)); document.head.appendChild(s); }); }
let _libsP=null;
function _ensureLibs(){
  if(_libsP) return _libsP;
  _libsP=(async()=>{
    if(typeof window.QRCode==='undefined') await _loadScript('https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js');
    if(typeof window.html2canvas==='undefined') await _loadScript('https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js');
    if(!(window.jspdf&&window.jspdf.jsPDF)) await _loadScript('https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js');
  })();
  return _libsP;
}

/* ---------- logo oficial (com fallback) ---------- */
const AGF_LOGO = `<img src="agf-logo.jpg" alt="AGF — Associação Goiana de Fisioterapia" style="height:46px;object-fit:contain;display:block;margin-left:auto">`;

/* ---------- frente ---------- */
function _frenteHTML(){
  const t=TIPOS[_tipo];
  const v=id=>{ const e=document.getElementById('ct-'+id); return e?e.value:''; };
  return `<div id="ct-frente" class="ct-card">
    <div class="ct-f-top">
      <div>
        <div class="ct-f-lead">Carteira de Identificação da Pessoa com:</div>
        <div class="ct-f-titulo" style="color:${t.cor}">${esc(t.titulo)}</div>
        <div class="ct-f-ozo">Tratamento com OZÔNIOTERAPIA</div>
      </div>
      <div style="min-width:120px"><div class="ct-f-ent">ENTIDADE EXECUTORA</div>${AGF_LOGO}</div>
    </div>
    <div class="ct-f-body">
      <div class="ct-f-fields">
        <div class="ct-fld ct-wide"><span>NOME:</span><b>${esc(v('nome'))}</b></div>
        <div class="ct-f-row">
          <div class="ct-fld"><span>CPF:</span><b>${esc(v('cpf'))}</b></div>
          <div class="ct-fld"><span>DOC. DE IDENTIFICAÇÃO:</span><b>${esc(v('rg'))}</b></div>
        </div>
        <div class="ct-f-row">
          <div class="ct-fld"><span>ÓRGÃO EXP.:</span><b>${esc(v('orgao'))}</b></div>
          <div class="ct-fld"><span>CONTATO/TELEFONE:</span><b>${esc(v('contato'))}</b></div>
        </div>
        <div class="ct-f-row">
          <div class="ct-fld"><span>DATA DE NASCIMENTO:</span><b>${esc(v('nasc'))}</b></div>
          <div class="ct-fld"><span>DATA DE EMISSÃO:</span><b>${esc(v('emissao'))}</b></div>
        </div>
      </div>
      <div class="ct-qrbox" id="ct-qrbox"><span class="ct-qr-ph">QR</span></div>
    </div>
    <div class="ct-f-foot">Apoio Institucional: <b>Advogado Malaguias</b></div>
  </div>`;
}

/* ---------- verso (histórico) ---------- */
function _versoHTML(){
  let visitas=[];
  if(_sel && Array.isArray(window.allPacientes)){
    const cpf=dig(_sel.cpf);
    visitas=window.allPacientes.filter(p=> cpf.length===11? dig(p.cpf)===cpf : (nrm(p.nome)===nrm(_sel.nome)&&dig(p.whatsapp)===dig(_sel.whatsapp)))
      .sort((a,b)=>(a.data_consulta||a.criado_em||'').localeCompare(b.data_consulta||b.criado_em||''));
  }
  let linhas='';
  for(let i=0;i<10;i++){
    const vis=visitas[i];
    const data=vis?fmtData(vis.data_consulta||vis.criado_em):'';
    const ret=vis?fmtData(vis.proximo_retorno):'';
    linhas+=`<tr><td class="ct-sess">${String(i+1).padStart(2,'0')}</td><td contenteditable>${data}</td><td contenteditable></td><td contenteditable>${ret}</td><td contenteditable></td><td contenteditable></td></tr>`;
  }
  return `<div id="ct-verso" class="ct-card ct-verso">
    <div class="ct-v-head"><span class="ct-v-ico">✚</span> CARTÃO DE CONSULTAS E RETORNO</div>
    <table class="ct-v-table"><thead><tr><th>SESSÃO</th><th>DATA</th><th>EVOLUÇÃO TRATAMENTO (0 a 10)</th><th>RETORNO</th><th>HORÁRIO</th><th>VISTO DR. WATANABE</th></tr></thead><tbody>${linhas}</tbody></table>
    <div class="ct-v-obs"><span>OBSERVAÇÕES:</span><div contenteditable class="ct-v-obsbox"></div></div>
  </div>`;
}

function _renderPreview(){ const w=document.getElementById('ct-preview'); if(!w) return; w.innerHTML=_frenteHTML()+_versoHTML(); if(_token) _desenharQR(); }

async function _desenharQR(){
  const box=document.getElementById('ct-qrbox'); if(!box||!_token) return;
  try{ await _ensureLibs(); box.innerHTML=''; new window.QRCode(box,{ text:BASE_URL+'/verificar.html?c='+_token, width:120, height:120, correctLevel:window.QRCode.CorrectLevel.M }); }
  catch(e){ box.innerHTML='<span class="ct-qr-ph">QR</span>'; }
}

/* ---------- preencher campos do paciente ---------- */
function _preencheDe(p){
  _sel=p; _token=null;
  const set=(id,val)=>{ const e=document.getElementById('ct-'+id); if(e) e.value=val||''; };
  set('nome',p.nome); set('cpf',fmtCpf(p.cpf)); set('rg',p.rg); set('orgao',p.orgao_expedidor);
  set('contato',p.whatsapp); set('nasc',fmtData(p.data_nascimento));
  set('emissao',fmtData(new Date().toISOString().slice(0,10)));
  const val=new Date(); val.setFullYear(val.getFullYear()+1); set('validade',fmtData(val.toISOString().slice(0,10)));
  _renderPreview();
  const st=document.getElementById('ct-status'); if(st){ st.textContent='Paciente selecionado. Revise e clique em "Gerar carteirinha".'; st.style.color='#0f766e'; }
}

/* ---------- busca (com botão Gerar por paciente) ---------- */
function _buscar(){
  const q=nrm(document.getElementById('ct-busca').value);
  const out=document.getElementById('ct-result'); if(!out) return;
  if(q.length<2){ out.innerHTML=''; out.style.display='none'; return; }
  const all=window.allPacientes||[]; const seen=new Set(); const hits=[];
  for(const p of all){
    if(hits.length>=12) break;
    const key=dig(p.cpf).length===11?'cpf:'+dig(p.cpf):'nw:'+nrm(p.nome)+'|'+dig(p.whatsapp);
    if(seen.has(key)) continue;
    if(nrm(p.nome).includes(q)||dig(p.cpf).includes(dig(q))){ seen.add(key); hits.push(p); }
  }
  out.style.display='block';
  out.innerHTML=hits.length? hits.map((p,i)=>`<div class="ct-hit-row"><div class="ct-hit" data-i="${i}">${esc(p.nome)} <small>${p.cpf?esc(fmtCpf(p.cpf)):'sem CPF'}</small></div><button class="ct-hit-gen" data-gi="${i}">🪪 Gerar</button></div>`).join('') : '<div class="ct-hit" style="color:#94a3b8;padding:10px">Nenhum paciente encontrado</div>';
  out._hits=hits;
}

/* ---------- gerar carteirinha (cria/reusa registro + QR) ---------- */
async function _gerar(btn){
  if(!_sel){ if(window.showToast) showToast('Escolha um paciente primeiro',true); return false; }
  if(typeof sb==='undefined'){ if(window.showToast) showToast('Sem conexão',true); return false; }
  if(btn){ btn.disabled=true; btn.textContent='Gerando...'; }
  try{
    const vget=id=>{ const e=document.getElementById('ct-'+id); return e?e.value.trim():''; };
    const cpf=dig(vget('cpf'));
    try{ await sb.from('pacientes_fibro').update({ rg:vget('rg')||null, orgao_expedidor:vget('orgao')||null }).eq('id',_sel.id); }catch(e){}
    let row=null;
    try{
      const { data }=await sb.from('carteirinhas').select('*').eq('paciente_id',_sel.id).eq('tipo',_tipo).eq('ativo',true).order('criado_em',{ascending:false}).limit(1);
      if(Array.isArray(data)&&data.length) row=data[0];
    }catch(e){}
    if(!row){
      const numero=TIPOS[_tipo].pref+'-'+Math.random().toString(36).slice(2,8).toUpperCase();
      const val=new Date(); val.setFullYear(val.getFullYear()+1);
      const payload={ paciente_id:_sel.id, tipo:_tipo, numero, nome:vget('nome'), cpf, emitida_em:new Date().toISOString().slice(0,10), validade:val.toISOString().slice(0,10), ativo:true };
      try{ payload.emitida_por=(typeof currentUser!=='undefined'&&currentUser)?currentUser.id:null; }catch(e){}
      const { data, error }=await sb.from('carteirinhas').insert(payload).select().single();
      if(error) throw error; row=data;
    }
    _token=row.id;
    const stN=document.getElementById('ct-numero'); if(stN) stN.textContent='Nº '+(row.numero||'');
    await _desenharQR();
    const st=document.getElementById('ct-status'); if(st){ st.textContent='✅ Carteirinha gerada! Agora é só imprimir / baixar.'; st.style.color='#15803d'; }
    if(window.showToast) showToast('Carteirinha gerada! 🪪');
    return true;
  }catch(e){
    console.warn('[carteirinha]',e&&e.message);
    const st=document.getElementById('ct-status'); if(st){ st.textContent='Erro: '+(e&&e.message||'falhou'); st.style.color='#b91c1c'; }
    if(window.showToast) showToast('Erro ao gerar carteirinha',true);
    return false;
  }finally{ if(btn){ btn.disabled=false; btn.textContent='🪪 Gerar carteirinha'; } }
}

/* ---------- export ---------- */
async function _capturar(el){ await _ensureLibs(); return window.html2canvas(el,{scale:3,backgroundColor:'#fff',useCORS:true,imageTimeout:4000}); }
function _toFile(canvas,nome){ return new Promise(r=>canvas.toBlob(b=>r(new File([b],nome,{type:'image/png'})),'image/png')); }
async function _baixarPNG(){
  if(!_token){ if(window.showToast) showToast('Gere a carteirinha primeiro',true); return; }
  try{
    const f=await _capturar(document.getElementById('ct-frente'));
    const v=await _capturar(document.getElementById('ct-verso'));
    [['frente',f],['verso',v]].forEach(([n,cv])=>{ const a=document.createElement('a'); a.href=cv.toDataURL('image/png'); a.download=`carteirinha-${_tipo}-${n}.png`; a.click(); });
    if(window.showToast) showToast('Imagens baixadas (frente + verso)');
  }catch(e){ if(window.showToast) showToast('Erro ao gerar imagem',true); }
}
async function _baixarPDF(){
  if(!_token){ if(window.showToast) showToast('Gere a carteirinha primeiro',true); return; }
  try{
    await _ensureLibs();
    const { jsPDF }=window.jspdf;
    const pdf=new jsPDF({orientation:'landscape',unit:'mm',format:'a4'});
    const f=await _capturar(document.getElementById('ct-frente'));
    const v=await _capturar(document.getElementById('ct-verso'));
    const w=160, hf=w*(f.height/f.width);
    pdf.setFontSize(11); pdf.text('Carteirinha — Frente',15,12);
    pdf.addImage(f.toDataURL('image/png'),'PNG',15,16,w,hf);
    pdf.text('Carteirinha — Verso',15,16+hf+12);
    pdf.addImage(v.toDataURL('image/png'),'PNG',15,16+hf+16,w,w*(v.height/v.width));
    pdf.save(`carteirinha-${_tipo}-${dig(_sel&&_sel.cpf)||'paciente'}.pdf`);
  }catch(e){ if(window.showToast) showToast('Erro ao gerar PDF',true); }
}
function _imprimir(){
  if(!_token){ if(window.showToast) showToast('Gere a carteirinha primeiro',true); return; }
  const f=document.getElementById('ct-frente'), v=document.getElementById('ct-verso');
  const w=window.open('','_print','width=900,height=650'); if(!w) return;
  w.document.write('<html><head><title>Carteirinha</title>'+document.getElementById('ct-style').outerHTML+'<style>body{padding:20px;background:#fff}.ct-card{margin:0 auto 20px}</style></head><body>'+f.outerHTML+v.outerHTML+'</body></html>');
  w.document.close(); setTimeout(()=>{ w.focus(); w.print(); },500);
}
async function _whatsapp(){
  if(!_token){ if(window.showToast) showToast('Gere a carteirinha primeiro',true); return; }
  try{
    const cf=await _capturar(document.getElementById('ct-frente'));
    const cv=await _capturar(document.getElementById('ct-verso'));
    const files=[ await _toFile(cf,'carteirinha-frente.png'), await _toFile(cv,'carteirinha-verso.png') ];
    if(navigator.canShare && navigator.canShare({files})){
      try{ await navigator.share({ files, title:'Carteirinha AGF', text:'Carteirinha AGF' }); return; }
      catch(e){ if(e&&e.name==='AbortError') return; }
    }
    files.forEach(f=>{ const a=document.createElement('a'); a.href=URL.createObjectURL(f); a.download=f.name; a.click(); });
    const zap=dig(_sel&&_sel.whatsapp);
    const msg=encodeURIComponent('Olá! Segue sua carteirinha AGF (anexe as imagens que acabaram de baixar). 🪪');
    window.open(zap?('https://wa.me/55'+zap+'?text='+msg):('https://wa.me/?text='+msg),'_blank');
    if(window.showToast) showToast('Imagens baixadas — anexe no WhatsApp');
  }catch(e){ if(window.showToast) showToast('Erro ao compartilhar',true); }
}

/* ---------- popup rápido (botão Gerar por paciente) ---------- */
function _quick(p){
  let bg=document.getElementById('ct-quick-bg');
  if(!bg){ bg=document.createElement('div'); bg.id='ct-quick-bg'; bg.style.cssText='position:fixed;inset:0;background:rgba(0,0,0,.55);z-index:99999;display:flex;align-items:center;justify-content:center;padding:16px'; bg.addEventListener('click',e=>{ if(e.target===bg) bg.style.display='none'; }); document.body.appendChild(bg); }
  bg.style.display='flex';
  const bs='padding:11px;border:none;border-radius:10px;font-weight:800;font-size:13px;cursor:pointer;color:#fff';
  bg.innerHTML=`<div style="background:#fff;border-radius:16px;max-width:420px;width:96%;padding:18px">
    <div style="font-size:16px;font-weight:800;color:#0f172a">🪪 Gerar carteirinha</div>
    <div style="font-size:13px;color:#64748b;margin:2px 0 14px">${esc(p.nome)}</div>
    <div style="font-size:12px;color:#475569;font-weight:700;margin-bottom:6px">1) Modelo:</div>
    <div style="display:flex;gap:8px;margin-bottom:12px">
      <button class="ct-q-tipo on" data-t="fibromialgia" style="flex:1;padding:10px;border:2px solid #1e9e3e;background:#ecfdf5;color:#15803d;border-radius:10px;font-weight:700;cursor:pointer">Fibromialgia</button>
      <button class="ct-q-tipo" data-t="cronicas" style="flex:1;padding:10px;border:2px solid #e2e8f0;background:#fff;color:#475569;border-radius:10px;font-weight:700;cursor:pointer">Doenças Crônicas</button>
    </div>
    <div id="ct-q-status" style="font-size:12px;color:#64748b;margin-bottom:10px">Gerando...</div>
    <div id="ct-q-actions" style="display:none;flex-direction:column;gap:8px">
      <button id="ct-q-pdf" style="${bs};background:#0ea5e9">📄 Baixar PDF</button>
      <button id="ct-q-png" style="${bs};background:#6366f1">🖼️ Baixar Imagem</button>
      <button id="ct-q-zap" style="${bs};background:#16a34a">📱 Enviar no WhatsApp</button>
    </div>
    <button id="ct-q-close" style="${bs};background:#94a3b8;margin-top:8px;width:100%">Fechar</button>
  </div>`;
  let tipoQ='fibromialgia';
  async function doGen(){
    const stt=document.getElementById('ct-q-status'); const act=document.getElementById('ct-q-actions');
    stt.textContent='Gerando carteirinha...'; act.style.display='none';
    _tipo=tipoQ; _syncTipoBtns(); _preencheDe(p);
    const ok=await _gerar(null);
    if(ok){ stt.textContent='✅ Pronto! Escolha como salvar:'; stt.style.color='#15803d'; act.style.display='flex'; }
    else { stt.textContent='Erro ao gerar (o SQL foi rodado?).'; stt.style.color='#b91c1c'; }
  }
  bg.querySelectorAll('.ct-q-tipo').forEach(b=>b.addEventListener('click',()=>{
    tipoQ=b.getAttribute('data-t');
    bg.querySelectorAll('.ct-q-tipo').forEach(x=>{ const on=x===b; x.style.borderColor=on?'#1e9e3e':'#e2e8f0'; x.style.background=on?'#ecfdf5':'#fff'; x.style.color=on?'#15803d':'#475569'; });
    doGen();
  }));
  bg.querySelector('#ct-q-close').onclick=()=>bg.style.display='none';
  bg.querySelector('#ct-q-pdf').onclick=_baixarPDF;
  bg.querySelector('#ct-q-png').onclick=_baixarPNG;
  bg.querySelector('#ct-q-zap').onclick=_whatsapp;
  doGen();
}

/* ---------- tipo (botões do painel) ---------- */
function _syncTipoBtns(){ const a=document.getElementById('ct-tipo-fibro'), b=document.getElementById('ct-tipo-cron'); if(a) a.classList.toggle('on',_tipo==='fibromialgia'); if(b) b.classList.toggle('on',_tipo==='cronicas'); }
function _setTipo(t){ _tipo=t; _token=null; _syncTipoBtns(); _renderPreview(); }

/* ---------- injeta CSS + nav + seção ---------- */
function _injetar(){
  if(document.getElementById('sec-carteirinhas')) return true;
  const nav=document.getElementById('nav-principal-section');
  const main=document.querySelector('main.main');
  if(!nav||!main) return false;

  const ni=document.createElement('div');
  ni.className='nav-item'; ni.setAttribute('data-section','carteirinhas');
  ni.innerHTML='<i class="fas fa-id-card"></i> Carteirinhas';
  ni.onclick=function(){ if(typeof showSection==='function') showSection('carteirinhas',ni); setTimeout(()=>{ if(!_renderedOnce){ _renderPreview(); _renderedOnce=true; } },50); };
  nav.appendChild(ni);

  const st=document.createElement('style'); st.id='ct-style';
  st.textContent=`
    #sec-carteirinhas .ct-grid{display:flex;gap:20px;flex-wrap:wrap;align-items:flex-start}
    #sec-carteirinhas .ct-panel{flex:1;min-width:280px;max-width:380px}
    #sec-carteirinhas .ct-preview-wrap{flex:2;min-width:320px}
    .ct-inp{width:100%;padding:8px 10px;border:1px solid var(--input-border,#cbd5e1);border-radius:8px;font-size:13px;margin-bottom:8px;background:var(--input-bg,#fff);color:var(--text-primary,#111)}
    .ct-lbl{font-size:11px;color:var(--text-muted,#64748b);font-weight:700;margin-bottom:3px;display:block}
    .ct-tipo-btns{display:flex;gap:8px;margin-bottom:12px}
    .ct-tipo-btn{flex:1;padding:10px;border:2px solid var(--input-border,#e2e8f0);border-radius:10px;background:var(--input-bg,#fff);cursor:pointer;font-weight:700;font-size:13px;color:var(--text-secondary,#475569);text-align:center}
    .ct-tipo-btn.on{border-color:#1e9e3e;background:rgba(22,163,74,.14);color:var(--accent,#15803d)}
    #ct-result{border:1px solid var(--input-border,#e2e8f0);border-radius:8px;max-height:260px;overflow:auto;margin-bottom:10px;display:none;background:var(--bg-card,#fff);color:var(--text-primary,#111)}
    .ct-hit-row{display:flex;align-items:center;gap:6px;border-bottom:1px solid var(--border-glass,#f1f5f9)}
    .ct-hit{flex:1;padding:9px 10px;cursor:pointer;font-size:13px}
    .ct-hit:hover{background:rgba(0,230,118,.08)}
    .ct-hit small{color:#94a3b8;font-size:11px}
    .ct-hit-gen{flex:none;margin-right:8px;background:#16a34a;color:#fff;border:none;border-radius:7px;padding:6px 10px;font-size:11px;font-weight:800;cursor:pointer}
    .ct-btn{width:100%;padding:11px;border:none;border-radius:10px;font-weight:800;font-size:14px;cursor:pointer;margin-bottom:8px;color:#fff}
    .ct-btn-go{background:#16a34a}.ct-btn-2{background:#0ea5e9}.ct-btn-3{background:#6366f1}.ct-btn-4{background:#475569}.ct-btn-zap{background:#25D366}
    .ct-card{width:540px;max-width:100%;background:#fff;border:1px solid #cbd5e1;border-radius:16px;padding:16px 18px;margin-bottom:18px;font-family:Arial,sans-serif;box-shadow:0 6px 18px rgba(0,0,0,.08);color:#111}
    .ct-f-top{display:flex;justify-content:space-between;align-items:flex-start;gap:10px}
    .ct-f-lead{font-size:11px;color:#334155;font-weight:700}
    .ct-f-titulo{font-size:34px;font-weight:900;line-height:1.05}
    .ct-f-ozo{font-size:14px;font-weight:800;color:#e30613}
    .ct-f-ent{font-size:9px;color:#1d3f8f;font-weight:800;letter-spacing:.5px;margin-bottom:2px;text-align:right}
    .ct-f-body{display:flex;gap:12px;margin-top:10px}
    .ct-f-fields{flex:1;display:flex;flex-direction:column;gap:7px}
    .ct-f-row{display:flex;gap:7px}
    .ct-fld{flex:1;border:1px solid #cbd5e1;border-radius:6px;padding:5px 7px;min-height:38px}
    .ct-fld span{font-size:8px;color:#475569;font-weight:700;display:block}
    .ct-fld b{font-size:13px;color:#0f172a}
    .ct-qrbox{width:130px;height:130px;border:1px solid #cbd5e1;border-radius:6px;display:flex;align-items:center;justify-content:center;flex:none}
    .ct-qrbox img,.ct-qrbox canvas{width:120px!important;height:120px!important}
    .ct-qr-ph{color:#94a3b8;font-size:28px;font-weight:800}
    .ct-f-foot{text-align:center;font-size:11px;color:#475569;margin-top:12px;border-top:1px solid #e2e8f0;padding-top:7px}
    .ct-verso{padding:0;overflow:hidden}
    .ct-v-head{background:#1f3a5f;color:#fff;font-size:18px;font-weight:900;padding:10px 14px}
    .ct-v-ico{background:#fff;color:#1f3a5f;border-radius:50%;padding:0 5px;margin-right:4px}
    .ct-v-table{width:100%;border-collapse:collapse;font-size:10px}
    .ct-v-table th{background:#5a7a3f;color:#fff;font-size:8px;padding:4px 3px;border:1px solid #cbd5e1;font-weight:800}
    .ct-v-table td{border:1px solid #cbd5e1;height:18px;padding:2px 4px;text-align:center;color:#111}
    .ct-v-table .ct-sess{background:#f1f5f9;font-weight:800;color:#1f3a5f}
    .ct-v-obs{padding:8px 12px 14px}
    .ct-v-obs>span{background:#1f3a5f;color:#fff;font-size:10px;font-weight:800;padding:2px 8px;border-radius:4px;display:inline-block;margin-bottom:5px}
    .ct-v-obsbox{border:1px solid #1f3a5f;border-radius:8px;min-height:54px;color:#111;padding:4px 6px}
  `;
  document.head.appendChild(st);

  const sec=document.createElement('div');
  sec.className='section'; sec.id='sec-carteirinhas';
  sec.innerHTML=`
    <h1 class="page-title"><i class="fas fa-id-card"></i> Carteirinhas AGF</h1>
    <p style="color:var(--text-muted);margin:-6px 0 16px;font-size:13px">Busque o paciente e clique em <b>🪪 Gerar</b> pra escolher o modelo e baixar/enviar. Ou monte manualmente abaixo.</p>
    <div class="ct-grid">
      <div class="ct-panel">
        <div class="ct-tipo-btns">
          <div class="ct-tipo-btn on" id="ct-tipo-fibro">Fibromialgia</div>
          <div class="ct-tipo-btn" id="ct-tipo-cron">Doenças Crônicas</div>
        </div>
        <label class="ct-lbl">Buscar paciente (nome ou CPF)</label>
        <input class="ct-inp" id="ct-busca" placeholder="Digite o nome..." autocomplete="off">
        <div id="ct-result"></div>
        <label class="ct-lbl">Nome</label><input class="ct-inp" id="ct-nome">
        <div style="display:flex;gap:8px"><div style="flex:1"><label class="ct-lbl">CPF</label><input class="ct-inp" id="ct-cpf"></div><div style="flex:1"><label class="ct-lbl">Contato/Telefone</label><input class="ct-inp" id="ct-contato"></div></div>
        <div style="display:flex;gap:8px"><div style="flex:1"><label class="ct-lbl">Doc. Identificação (RG)</label><input class="ct-inp" id="ct-rg"></div><div style="flex:1"><label class="ct-lbl">Órgão Exp.</label><input class="ct-inp" id="ct-orgao"></div></div>
        <div style="display:flex;gap:8px"><div style="flex:1"><label class="ct-lbl">Nascimento</label><input class="ct-inp" id="ct-nasc"></div><div style="flex:1"><label class="ct-lbl">Emissão</label><input class="ct-inp" id="ct-emissao"></div></div>
        <label class="ct-lbl">Validade</label><input class="ct-inp" id="ct-validade">
        <button class="ct-btn ct-btn-go" id="ct-gerar">🪪 Gerar carteirinha</button>
        <div id="ct-numero" style="text-align:center;font-weight:800;color:#0f766e;margin-bottom:6px"></div>
        <button class="ct-btn ct-btn-4" id="ct-print">🖨️ Imprimir</button>
        <button class="ct-btn ct-btn-2" id="ct-pdf">📄 Baixar PDF</button>
        <button class="ct-btn ct-btn-3" id="ct-png">🖼️ Baixar Imagem</button>
        <button class="ct-btn ct-btn-zap" id="ct-zap">📱 Enviar no WhatsApp</button>
        <div id="ct-status" style="font-size:12px;margin-top:6px;color:#64748b"></div>
      </div>
      <div class="ct-preview-wrap"><div id="ct-preview"></div></div>
    </div>`;
  main.appendChild(sec);

  document.getElementById('ct-busca').addEventListener('input',_buscar);
  document.getElementById('ct-result').addEventListener('click',e=>{
    const hits=document.getElementById('ct-result')._hits||[];
    const gen=e.target.closest('.ct-hit-gen');
    if(gen){ const p=hits[+gen.getAttribute('data-gi')]; if(p) _quick(p); return; }
    const h=e.target.closest('.ct-hit'); if(!h||h.getAttribute('data-i')==null) return;
    const p=hits[+h.getAttribute('data-i')]; if(p){ _preencheDe(p); document.getElementById('ct-result').style.display='none'; document.getElementById('ct-busca').value=p.nome; }
  });
  ['nome','cpf','rg','orgao','contato','nasc','emissao','validade'].forEach(id=>{ const e=document.getElementById('ct-'+id); if(e) e.addEventListener('input',()=>{ _token=null; _renderPreview(); }); });
  document.getElementById('ct-tipo-fibro').onclick=()=>_setTipo('fibromialgia');
  document.getElementById('ct-tipo-cron').onclick=()=>_setTipo('cronicas');
  document.getElementById('ct-gerar').onclick=function(){ _gerar(this); };
  document.getElementById('ct-print').onclick=_imprimir;
  document.getElementById('ct-pdf').onclick=_baixarPDF;
  document.getElementById('ct-png').onclick=_baixarPNG;
  document.getElementById('ct-zap').onclick=_whatsapp;
  _renderPreview();
  return true;
}

/* ============================================================
   GESTÃO DE CARTEIRINHAS (admin): listar / buscar / reimprimir / revogar
   ============================================================ */
function _statusCart(c){
  const hoje=new Date().toISOString().slice(0,10);
  if(c.ativo===false) return {txt:'Revogada',cor:'#b91c1c',bg:'#fee2e2'};
  if(c.validade && String(c.validade).slice(0,10)<hoje) return {txt:'Vencida',cor:'#b45309',bg:'#fef3c7'};
  return {txt:'Ativa',cor:'#15803d',bg:'#dcfce7'};
}
async function _gestaoLoad(){
  const tb=document.getElementById('gc-body'); if(!tb) return;
  tb.innerHTML='<tr><td colspan="7" style="text-align:center;padding:20px;color:#94a3b8">Carregando...</td></tr>';
  try{ const { data }=await sb.from('carteirinhas').select('*').order('criado_em',{ascending:false}).limit(3000); window._gcRows=data||[]; }
  catch(e){ tb.innerHTML='<tr><td colspan="7" style="color:#b91c1c;padding:20px;text-align:center">Erro ao carregar (a tabela carteirinhas existe?)</td></tr>'; return; }
  _gestaoRender();
}
function _gestaoRender(){
  const tb=document.getElementById('gc-body'); if(!tb) return;
  const q=nrm(document.getElementById('gc-busca')?.value||''); const qd=dig(q);
  let rows=window._gcRows||[];
  if(q) rows=rows.filter(c=> nrm(c.nome).includes(q) || (c.numero||'').toLowerCase().includes(q.toLowerCase()) || (qd&&dig(c.cpf).includes(qd)));
  const cont=document.getElementById('gc-count'); if(cont) cont.textContent=rows.length+' carteirinha(s)';
  if(!rows.length){ tb.innerHTML='<tr><td colspan="7" style="text-align:center;padding:20px;color:#94a3b8">Nenhuma carteirinha encontrada</td></tr>'; return; }
  tb.innerHTML=rows.slice(0,500).map(c=>{
    const s=_statusCart(c);
    return `<tr>
      <td style="padding:7px 8px;font-weight:800;color:#0f766e">${esc(c.numero||'—')}</td>
      <td style="padding:7px 8px">${esc(c.nome||'—')}</td>
      <td style="padding:7px 8px">${c.tipo==='cronicas'?'Doenças Crônicas':'Fibromialgia'}</td>
      <td style="padding:7px 8px;text-align:center">${fmtData(c.emitida_em)}</td>
      <td style="padding:7px 8px;text-align:center">${fmtData(c.validade)}</td>
      <td style="padding:7px 8px;text-align:center"><span style="background:${s.bg};color:${s.cor};padding:2px 9px;border-radius:8px;font-size:11px;font-weight:800">${s.txt}</span></td>
      <td style="padding:7px 8px;white-space:nowrap">
        <button class="gc-act" data-act="reimp" data-id="${c.id}" style="background:#0ea5e9;color:#fff;border:none;border-radius:6px;padding:4px 9px;font-size:11px;font-weight:700;cursor:pointer;margin-right:4px">🖨️ Reimprimir</button>
        <button class="gc-act" data-act="${c.ativo===false?'reativar':'revogar'}" data-id="${c.id}" style="background:${c.ativo===false?'#16a34a':'#ef4444'};color:#fff;border:none;border-radius:6px;padding:4px 9px;font-size:11px;font-weight:700;cursor:pointer">${c.ativo===false?'✅ Reativar':'🚫 Revogar'}</button>
      </td>
    </tr>`;
  }).join('');
}
function _gestaoReimprimir(cart){
  const p=(window.allPacientes||[]).find(x=>x.id===cart.paciente_id);
  _tipo = cart.tipo==='cronicas'?'cronicas':'fibromialgia'; _syncTipoBtns();
  if(p){ _preencheDe(p); } else { _sel={id:cart.paciente_id,nome:cart.nome,cpf:cart.cpf,whatsapp:''}; }
  const set=(id,v)=>{ const e=document.getElementById('ct-'+id); if(e) e.value=v||''; };
  set('nome',cart.nome); set('cpf',fmtCpf(cart.cpf));
  set('emissao',fmtData(cart.emitida_em)); set('validade',fmtData(cart.validade));
  _token=cart.id;
  if(typeof showSection==='function') showSection('carteirinhas', document.querySelector('[data-section=carteirinhas]'));
  _renderPreview();
  const stN=document.getElementById('ct-numero'); if(stN) stN.textContent='Nº '+(cart.numero||'');
  const st=document.getElementById('ct-status'); if(st){ st.textContent='2ª via carregada (mesmo QR). É só imprimir / baixar.'; st.style.color='#0f766e'; }
}
async function _gestaoAcao(act,id){
  const cart=(window._gcRows||[]).find(c=>c.id===id); if(!cart) return;
  if(act==='reimp'){ _gestaoReimprimir(cart); return; }
  if(act==='revogar' && !confirm('Revogar a carteirinha '+(cart.numero||'')+' de '+(cart.nome||'')+'?\nO QR passará a mostrar "inválida". (Dá pra reativar depois.)')) return;
  try{
    await sb.from('carteirinhas').update({ ativo: act==='reativar' }).eq('id',id);
    cart.ativo = (act==='reativar'); _gestaoRender();
    if(window.showToast) showToast(act==='reativar'?'Carteirinha reativada ✅':'Carteirinha revogada 🚫');
  }catch(e){ if(window.showToast) showToast('Erro ao atualizar',true); }
}
function _gestaoInjetar(){
  if(document.getElementById('sec-gestao-carteirinhas')) return true;
  const nav=document.getElementById('nav-admin-section'); const main=document.querySelector('main.main');
  if(!nav||!main) return false;
  const ni=document.createElement('div'); ni.className='nav-item'; ni.setAttribute('data-section','gestao-carteirinhas');
  ni.innerHTML='<i class="fas fa-id-card-alt"></i> Gestão Carteirinhas';
  ni.onclick=function(){ if(typeof showSection==='function') showSection('gestao-carteirinhas',ni); _gestaoLoad(); };
  nav.appendChild(ni);
  const sec=document.createElement('div'); sec.className='section'; sec.id='sec-gestao-carteirinhas';
  sec.innerHTML=`
    <h1 class="page-title"><i class="fas fa-id-card-alt"></i> Gestão de Carteirinhas</h1>
    <p style="color:var(--text-muted);margin:-6px 0 14px;font-size:13px">Todas as carteirinhas emitidas (por qualquer admin ou colaborador). Busque, reimprima a 2ª via (mesmo QR) ou revogue uma perdida/cancelada.</p>
    <div style="display:flex;gap:10px;align-items:center;margin-bottom:12px;flex-wrap:wrap">
      <input id="gc-busca" class="ct-inp" style="max-width:340px;margin:0" placeholder="Buscar por número, nome ou CPF...">
      <button id="gc-refresh" style="background:#475569;color:#fff;border:none;border-radius:8px;padding:9px 14px;font-weight:700;cursor:pointer">🔄 Atualizar</button>
      <span id="gc-count" style="color:var(--text-muted);font-size:13px"></span>
    </div>
    <div style="overflow:auto;border:1px solid #e2e8f0;border-radius:10px">
      <table style="width:100%;border-collapse:collapse;font-size:13px;background:#fff;color:#111">
        <thead><tr style="background:#f1f5f9;color:#334155;font-size:12px">
          <th style="padding:8px;text-align:left">Número</th><th style="padding:8px;text-align:left">Nome</th><th style="padding:8px;text-align:left">Tipo</th><th style="padding:8px">Emissão</th><th style="padding:8px">Validade</th><th style="padding:8px">Status</th><th style="padding:8px">Ações</th>
        </tr></thead>
        <tbody id="gc-body"></tbody>
      </table>
    </div>`;
  main.appendChild(sec);
  document.getElementById('gc-busca').addEventListener('input',_gestaoRender);
  document.getElementById('gc-refresh').onclick=_gestaoLoad;
  document.getElementById('gc-body').addEventListener('click',e=>{ const b=e.target.closest('.gc-act'); if(b) _gestaoAcao(b.getAttribute('data-act'), b.getAttribute('data-id')); });
  return true;
}

/* ---------- ACESSO RÁPIDO: botão 🪪 nas linhas de Pacientes e Cadastrados ----------
   As duas listas usam tr[data-pac-key]. Adiciona um botão que leva pra aba
   Carteirinhas com o paciente JÁ carregado e a carteirinha JÁ gerada (QR pronto). */
window._ctAbrirPaciente=function(key){
  const all=window.allPacientes||[]; let p=null;
  if(key && key.indexOf('cpf:')===0){ const c=key.slice(4); p=all.find(x=>dig(x.cpf)===c); }
  else if(key && key.indexOf('nw:')===0){ const parts=key.slice(3).split('|'); p=all.find(x=>nrm(x.nome)===parts[0] && dig(x.whatsapp)===(parts[1]||'')); }
  if(!p){ if(window.showToast) showToast('Paciente não encontrado',true); return; }
  if(typeof showSection==='function') showSection('carteirinhas', document.querySelector('[data-section=carteirinhas]'));
  _preencheDe(p);
  try{ window.scrollTo(0,0); }catch(e){}
  _gerar(null); /* já gera a carteirinha (QR pronto) */
};
function _decorarRows(){
  document.querySelectorAll('tr[data-pac-key]').forEach(tr=>{
    if(tr.querySelector('.ct-row-btn')) return;
    const tds=tr.querySelectorAll('td'); if(!tds.length) return;
    const b=document.createElement('button');
    b.className='ct-row-btn'; b.type='button'; b.title='Gerar carteirinha deste paciente'; b.textContent='🪪';
    b.style.cssText='margin-left:6px;background:#16a34a;color:#fff;border:none;border-radius:6px;padding:2px 7px;font-size:12px;cursor:pointer;vertical-align:middle';
    b.addEventListener('click',function(ev){ ev.stopPropagation(); window._ctAbrirPaciente(tr.getAttribute('data-pac-key')); });
    tds[tds.length-1].appendChild(b);
  });
}
let _ctObs=false;
function _startRowObserver(){
  if(_ctObs) return; const main=document.querySelector('main.main'); if(!main) return; _ctObs=true;
  let to=null;
  try{ new MutationObserver(()=>{ clearTimeout(to); to=setTimeout(()=>{ try{_decorarRows();}catch(e){} },300); }).observe(main,{childList:true,subtree:true}); }catch(e){}
  setTimeout(()=>{ try{_decorarRows();}catch(e){} },600);
}

function _initAll(){ const a=_injetar(); const b=_gestaoInjetar(); if(a) _startRowObserver(); return a&&b; }
if(!_initAll()){
  const t=setInterval(()=>{ if(_initAll()) clearInterval(t); },600);
  setTimeout(()=>clearInterval(t),30000);
  window.addEventListener('malaquias:profile-ready',()=>_initAll(),{once:true});
}
})();
