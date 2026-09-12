// G.L.A.S.S. site script. Plain ES module, no build step.
// Sections: manifest/assets, HUD framebuffer (128x64), turntable scrubber, optics steps,
// feature explorer, assistant simulator, GLB viewer, version log.

const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => [...r.querySelectorAll(s)];
const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;

// ------------------------------------------------------------------ assets ---
let manifest = { versions: [], current: null };
try { manifest = await (await fetch('assets/manifest.json', { cache: 'no-cache' })).json(); } catch {}
const cur = manifest.versions.find(v => v.version === manifest.current) || null;
const base = cur ? `assets/${cur.version}/` : null;

for (const el of $$('[data-version]')) el.textContent = cur ? `Prototype ${cur.version}` : 'Prototype';
for (const el of $$('[data-version-long]')) el.textContent = cur ? `Prototype ${cur.version}, ${cur.date}.` : 'Prototype.';
if (cur && !cur.placeholder) document.documentElement.classList.add('final');
for (const img of $$('img[data-asset]')) {
  if (base) img.src = base + img.dataset.asset;
  else img.alt += ' (render not generated yet)';
  img.loading = 'lazy'; img.decoding = 'async';
}

// ---------------------------------------------------- product tiles (home) ---
for (const tile of $$('[data-product]')) {
  const prod = tile.dataset.product;
  (async () => {
    try {
      const m = await (await fetch(`${prod}/assets/manifest.json`, { cache: 'no-cache' })).json();
      const c = m.versions.find(v => v.version === m.current); if (!c) return;
      for (const img of $$('img[data-asset]', tile)) { img.src = `${prod}/assets/${c.version}/${img.dataset.asset}`; img.loading = 'lazy'; }
      for (const el of $$('[data-version]', tile)) el.textContent = `Prototype ${c.version}`;
      if (!c.placeholder) tile.classList.add('final');
    } catch {}
  })();
}

// ------------------------------------------------------------- HUD 128x64 ---
// 5x7 bitmap font, ASCII 32..126 (columns, LSB = top row). Classic GLCD font (Adafruit GFX, BSD), same one the firmware will use.
const FONT = '000000000000005f00000007000700147f147f14242a7f2a12231308646236495620500008070300001c2241000041221c002a1c7f1c2a08083e080800807030000808080808000060600020100804023e5149453e00427f400072494949462141494d331814127f1027454545393c4a49493141211109073649494936464949291e0000140000004034000000081422411414141414004122140802015909063e415d594e7c1211127c7f494949363e414141227f4141413e7f494949417f090909013e414151737f0808087f00417f41002040413f017f081422417f404040407f021c027f7f0408107f3e4141413e7f090909063e4151215e7f09192946264949493203017f01033f4040403f1f2040201f3f4038403f631408146303047804036159494d43007f4141410204081020004141417f04020102044040404040000307080020545478407f284444383844444428384444287f385454541800087e090218a4a49c787f0804047800447d40002040403d007f1028440000417f40007c047804787c080404783844444438fc1824241818242418fc7c08040408485454542404043f44243c4040207c1c2040201c3c4030403c44281028444c9090907c4464544c440008364100000077000000413608000201020402';
const glyph = c => { const i = Math.max(32, Math.min(126, c.charCodeAt(0))) - 32; return [0,1,2,3,4].map(k => parseInt(FONT.substr((i * 5 + k) * 2, 2), 16)); };

class Hud {
  constructor(canvas) { this.c = canvas; this.g = canvas.getContext('2d'); this.g.imageSmoothingEnabled = false; this.clear(); }
  clear() { this.g.fillStyle = '#000'; this.g.fillRect(0, 0, 128, 64); }
  px(x, y) { if (x >= 0 && x < 128 && y >= 0 && y < 64) this.g.fillRect(x, y, 1, 1); }
  text(s, x, y, scale = 1) {
    this.g.fillStyle = '#f2f5f7';
    for (const ch of s) {
      const cols = glyph(ch);
      for (let cx = 0; cx < 5; cx++) for (let r = 0; r < 7; r++) if (cols[cx] >> r & 1)
        this.g.fillRect(x + cx * scale, y + r * scale, scale, scale);
      x += 6 * scale;
    }
    return x;
  }
  line(x0, y0, x1, y1) { this.g.fillStyle = '#f2f5f7'; const dx = Math.abs(x1 - x0), dy = -Math.abs(y1 - y0); let sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1, e = dx + dy; for (;;) { this.px(x0, y0); if (x0 === x1 && y0 === y1) break; const e2 = 2 * e; if (e2 >= dy) { e += dy; x0 += sx; } if (e2 <= dx) { e += dx; y0 += sy; } } }
  wrap(s, y, scale = 1, max = 21) {
    const words = s.split(' '); let line = '';
    for (const w of words) { if ((line + ' ' + w).trim().length > max) { this.text(line, 2, y, scale); y += 8 * scale; line = w; } else line = (line + ' ' + w).trim(); }
    if (line) this.text(line, 2, y, scale);
    return y + 8 * scale;
  }
}

const pad = n => String(n).padStart(2, '0');
function idle(h, tick) {
  const d = new Date();
  h.clear();
  h.text(`${pad(d.getHours())}:${pad(d.getMinutes())}`, 2, 2, 2);
  h.text('GZOWO  WiFi ok', 2, 24);
  h.text(`BAT ${Math.max(20, 96 - (tick % 60))}%`, 2, 34);
  h.line(0, 44, 127, 44);
  h.text(tick % 8 < 4 ? 'press to talk' : 'G.L.A.S.S.', 2, 50);
}
const huds = $$('canvas[data-hud]').map(c => ({ role: c.dataset.hud, h: new Hud(c) }));
let tick = 0;
setInterval(() => { tick++; for (const { role, h } of huds) if (role !== 'sim' || !simBusy) idle(h, tick); }, 1000);
for (const { h } of huds) idle(h, 0);

// ------------------------------------------------------- assistant simulator ---
let simBusy = false;
const REPLIES = [
  [/godzin|time|która/i, () => { const d = new Date(); return [`Jest ${pad(d.getHours())}:${pad(d.getMinutes())}.`]; }],
  [/pogod|weather/i, () => ['Gzowo: 17 C, zachmurzenie.', 'Wieczorem 11 C, wez kurtke.']],
  [/widz|see|what.*this/i, () => ['Biurko, laptop, kabel USB-C', 'i srubokret pod klawiatura.']],
  [/timer|minut/i, () => ['Timer 10:00 ustawiony.', 'Dam znac w uchu i tutaj.']],
  [/kim jestes|who are you|nazyw/i, () => ['G.L.A.S.S.', 'Gzowo Like A Smart Sass.', 'Asystent w okularach.']],
  [/dzieki|dzięki|thanks/i, () => ['Nie ma sprawy.']],
  [/./, () => ['Tego jeszcze nie umiem.', 'Pogoda, timer, czas, kamera.']],
];
function say(h, q, lines) {
  simBusy = true;
  let i = 0; const all = ['> ' + q, ...lines];
  const step = () => {
    h.clear();
    let y = 2;
    for (let k = 0; k <= i && k < all.length; k++) y = h.wrap(all[k], y, 1);
    if (i < all.length - 1) { i++; setTimeout(step, reduced ? 0 : 450); }
    else setTimeout(() => { simBusy = false; }, 6000);
  };
  step();
}
const simHud = huds.find(x => x.role === 'sim')?.h;
const form = $('[data-sim-form]');
if (form && simHud) {
  const ask = q => { q = q.trim(); if (!q) return; const [, fn] = REPLIES.find(([re]) => re.test(q)); say(simHud, q.slice(0, 40), fn()); };
  form.addEventListener('submit', e => { e.preventDefault(); ask($('#ask').value); $('#ask').value = ''; });
  $('[data-prompts]')?.addEventListener('click', e => { const b = e.target.closest('button'); if (b) ask(b.textContent); });
}

// ---------------------------------------------------- turntable scrubber ---
const scrub = $('canvas[data-scrub]');
if (scrub && cur) {
  const n = cur.frames || 0, g = scrub.getContext('2d'), imgs = new Array(n);
  const load = i => new Promise(res => { if (imgs[i]) return res(imgs[i]); const im = new Image(); im.onload = () => res(imgs[i] = im); im.onerror = () => res(null); im.src = `${base}frames/f${String(i).padStart(3, '0')}.webp`; });
  const draw = im => { if (!im) return; g.clearRect(0, 0, scrub.width, scrub.height); g.drawImage(im, 0, 0, scrub.width, scrub.height); };
  const section = scrub.closest('.scrub'), caps = $$('[data-cap]', section);
  let last = -1;
  const update = () => {
    const r = section.getBoundingClientRect(); const p = Math.min(1, Math.max(0, -r.top / (r.height - innerHeight)));
    const i = Math.round(p * (n - 1)); if (i !== last) { last = i; load(i).then(draw); }
    const c = Math.min(caps.length - 1, Math.floor(p * caps.length)); caps.forEach((el, k) => el.classList.toggle('on', k === c));
  };
  if (n) { load(0).then(draw); for (let i = 1; i < n; i += 1) setTimeout(() => load(i), i * 25); addEventListener('scroll', update, { passive: true }); addEventListener('resize', update); update(); }
}

// --------------------------------------------------------- optics steps ---
const optics = $('.optics');
if (optics) {
  const svg = $('svg', optics);
  const show = k => {
    $$('[data-copy]', optics).forEach(el => el.classList.toggle('on', +el.dataset.copy === k));
    for (let i = 0; i <= 4; i++) {
      $$(`.p${i}`, svg).forEach(el => el.classList.toggle('on', i <= k));
      $$(`.b${i}`, svg).forEach(el => el.classList.toggle('on', i <= k));
    }
    $$('.l0', svg).forEach(el => el.classList.toggle('on', k >= 0));
    // beams: b1 (mirror->lens) from step 1, b2 (lens->splitter) from step 2, b3 (splitter->eye) from step 3
  };
  const io = new IntersectionObserver(es => { for (const e of es) if (e.isIntersecting) show(+e.target.dataset.step); }, { rootMargin: '-45% 0px -45% 0px' });
  $$('[data-step]', optics).forEach(s => io.observe(s));
  show(0);
}

// ------------------------------------------------------- feature explorer ---
const ex = $('.explorer');
if (ex) ex.addEventListener('click', e => {
  const b = e.target.closest('[data-x]'); if (!b || b.tagName !== 'BUTTON') return;
  const k = b.dataset.x;
  $$('.item', ex).forEach(i => { const on = i.dataset.x === k; i.classList.toggle('on', on); i.setAttribute('aria-selected', on); });
  $$('.art img', ex).forEach(i => i.classList.toggle('on', i.dataset.x === k));
});

// ------------------------------------------------------------- GLB viewer ---
const box = $('[data-viewer]');
if (box && base) (async () => {
  try {
    const THREE = await import('three');
    const { GLTFLoader } = await import('three/addons/loaders/GLTFLoader.js');
    const { OrbitControls } = await import('three/addons/controls/OrbitControls.js');
    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true }); renderer.setPixelRatio(Math.min(2, devicePixelRatio));
    renderer.setSize(box.clientWidth, box.clientHeight); box.prepend(renderer.domElement);
    const scene = new THREE.Scene();
    const cam = new THREE.PerspectiveCamera(30, box.clientWidth / box.clientHeight, 1, 5000); cam.position.set(260, 180, 320);
    scene.add(new THREE.HemisphereLight(0xffffff, 0x222226, 1.6));
    const key = new THREE.DirectionalLight(0xffffff, 2.2); key.position.set(200, 300, 200); scene.add(key);
    const ctl = new OrbitControls(cam, renderer.domElement); ctl.enableDamping = true; ctl.enablePan = false; ctl.autoRotate = !reduced; ctl.autoRotateSpeed = 0.8;
    new GLTFLoader().load(base + 'model.glb', g => { const m = g.scene; const b = new THREE.Box3().setFromObject(m); const c = b.getCenter(new THREE.Vector3()); m.position.sub(c); scene.add(m); ctl.target.set(0, 0, 0); });
    const loop = () => { ctl.update(); renderer.render(scene, cam); requestAnimationFrame(loop); }; loop();
    addEventListener('resize', () => { cam.aspect = box.clientWidth / box.clientHeight; cam.updateProjectionMatrix(); renderer.setSize(box.clientWidth, box.clientHeight); });
  } catch (e) { console.warn('viewer', e); }
})();

// ------------------------------------------------------------ version log ---
const vg = $('[data-versions]');
if (vg) {
  if (!manifest.versions.length) vg.innerHTML = '<p class="small">No renders published yet.</p>';
  for (const v of [...manifest.versions].reverse()) {
    const el = document.createElement('article'); el.className = 'v';
    el.innerHTML = `<img src="assets/${v.version}/frames/f000.webp" alt="${v.version} turntable frame" loading="lazy"><div class="n"><span>${v.version}</span><span class="small">${v.date}</span></div><p></p>`;
    $('p', el).textContent = v.note; vg.append(el);
  }
}
