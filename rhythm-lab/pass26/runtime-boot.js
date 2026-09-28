function hostBoot(){
 document.querySelectorAll('.modelBtn').forEach(b=>b.addEventListener('click',()=>setModel(b.dataset.model)));
 document.getElementById('playBtn')?.addEventListener('click',play);
 document.getElementById('stopBtn')?.addEventListener('click',stop);
 document.getElementById('helpToolBtn')?.addEventListener('click',showHelp);
 document.getElementById('helpMenuBtn')?.addEventListener('click',showHelp);
 document.querySelectorAll('.viewBtn').forEach(b=>b.addEventListener('click',()=>dev12SetView(b.dataset.view)));
 setProductMode('authentic');setModel('hr16');dev12SetView('play');warmRoms();
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',hostBoot);else hostBoot();