/* Odnośniki do pytań (#pytanie-n): rozwijają odpowiedź przed przewinięciem */
(function(){
  function target(id){var t=id&&document.getElementById(id);if(!t)return null;return t.tagName==='DETAILS'?t:t.closest('details')}
  function open(id){var d=target(id);if(!d)return false;d.open=true;return true}
  function fromHash(){try{var id=decodeURIComponent(location.hash.slice(1));if(open(id)){var t=document.getElementById(id);if(t&&t.scrollIntoView)t.scrollIntoView()}}catch(e){}}
  window.addEventListener('hashchange',fromHash);fromHash();
  document.addEventListener('click',function(e){
    var a=e.target.closest('a[href^="#"]');if(!a)return;
    try{open(decodeURIComponent(a.getAttribute('href').slice(1)))}catch(err){}
  });
})();

/* Menu mobilne: zamyka się po wyborze, Esc, kliknięciu obok i wyjściu fokusu */
(function(){
  var menu=document.querySelector('details.menu'); if(!menu) return;
  var sum=menu.querySelector('summary');
  function close(focus){if(!menu.open)return;menu.open=false;if(focus)sum.focus()}
  menu.addEventListener('click',function(e){if(e.target.closest('.menu-panel a[href]'))close(false)});
  document.addEventListener('keydown',function(e){if(e.key==='Escape'&&menu.open)close(true)});
  document.addEventListener('click',function(e){if(!menu.contains(e.target))close(false)});
  menu.addEventListener('focusout',function(e){if(e.relatedTarget&&!menu.contains(e.relatedTarget))close(false)});
})();

/* Nagłówek: ton nad ciemnymi scenami, tryb kompaktowy, chowanie przy przewijaniu w dół */
(function(){
  var hdr=document.querySelector('.site-header'); if(!hdr) return;
  var menu=hdr.querySelector('details.menu');
  var mqMotion=window.matchMedia('(prefers-reduced-motion: reduce)'), mqLand=window.matchMedia('(max-height: 500px)');
  var lastY=window.scrollY, ticking=false;
  function update(){
    ticking=false;var y=window.scrollY;
    hdr.dataset.compact=y>40?'1':'0';
    var hide=hdr.dataset.hidden==='1';
    if(mqMotion.matches||mqLand.matches||(menu&&menu.open)||hdr.contains(document.activeElement)||y<320)hide=false;
    else if(y>lastY+4)hide=true;
    else if(y<lastY-4)hide=false;
    hdr.dataset.hidden=hide?'1':'0';lastY=y;
  }
  window.addEventListener('scroll',function(){if(!ticking){ticking=true;requestAnimationFrame(update)}},{passive:true});
  update();
  if(!('IntersectionObserver' in window)) return;
  var live=new Set();
  var io=new IntersectionObserver(function(entries){
    entries.forEach(function(en){if(en.isIntersecting)live.add(en.target);else live.delete(en.target)});
    var dark=false;live.forEach(function(t){if(t.classList.contains('dark'))dark=true});
    hdr.dataset.tone=dark?'dark':'light';
  },{rootMargin:'-40px 0px -90% 0px'});
  [].forEach.call(document.querySelectorAll('.scene,.section'),function(s){io.observe(s)});
})();

/* Zdjęcia scen ładowane przy zbliżeniu (bez JS – <noscript>) */
(function(){
  var scenes=[].slice.call(document.querySelectorAll('.scene'));
  if(!('IntersectionObserver' in window)){scenes.forEach(function(s){s.classList.add('bg-on')});return}
  var io=new IntersectionObserver(function(entries){
    entries.forEach(function(en){if(en.isIntersecting){en.target.classList.add('bg-on');io.unobserve(en.target)}});
  },{rootMargin:'100% 0px'});
  scenes.forEach(function(s){io.observe(s)});
})();

/* Wejścia bez animation-timeline (Safari < 26, Firefox): IntersectionObserver; treść nad zgięciem od razu widoczna, przed drukiem wszystko */
(function(){
  if(!('IntersectionObserver' in window)||window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  if(window.CSS&&CSS.supports&&CSS.supports('animation-timeline: view()')) return;
  [].forEach.call(document.querySelectorAll('.section-head > .eyebrow,.end-card > .eyebrow'),function(e){e.classList.add('rv-eyebrow')});
  var els=[].slice.call(document.querySelectorAll('.rv-curtain,.rv-rise,.rv-eyebrow')), vh=window.innerHeight;
  function show(e){e.classList.add('is-in')}
  els.forEach(function(e){if(e.getBoundingClientRect().top<vh)show(e)});
  var io=new IntersectionObserver(function(entries){
    entries.forEach(function(en){if(en.isIntersecting){show(en.target);io.unobserve(en.target)}});
  },{rootMargin:'0px 0px -10% 0px'});
  els.forEach(function(e){if(!e.classList.contains('is-in'))io.observe(e)});
  document.documentElement.classList.add('io-reveal');
  window.addEventListener('beforeprint',function(){els.forEach(show)});
})();

/* Dryf cyfr rozdziałów bez animation-timeline: rAF po zdarzeniu scroll (passive), tylko translate */
(function(){
  if(window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  if(window.CSS&&CSS.supports&&CSS.supports('animation-timeline: view()')) return;
  var nums=[].slice.call(document.querySelectorAll('.chapter-no')).map(function(n){return {el:n,box:n.parentNode,d:parseFloat(getComputedStyle(n).getPropertyValue('--drift'))||60}});
  if(!nums.length) return;
  var ticking=false;
  function clamp(v){return v<0?0:v>1?1:v}
  function frame(){
    ticking=false;var vh=window.innerHeight, out=[];
    nums.forEach(function(n){
      var r=n.box.getBoundingClientRect();if(r.bottom<-vh||r.top>2*vh)return;
      out.push([n.el,(n.d*(1-2*clamp((vh-r.top)/(vh+r.height)))).toFixed(1)+'px']);
    });
    out.forEach(function(o){o[0].style.setProperty('--drift-y',o[1])});
  }
  function request(){if(!ticking){ticking=true;requestAnimationFrame(frame)}}
  document.documentElement.classList.add('sl-js');
  window.addEventListener('scroll',request,{passive:true});
  window.addEventListener('resize',request);
  frame();
})();
