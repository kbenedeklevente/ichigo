#!/usr/bin/env python3
"""Launch isolated art studies or assemble their actual Godot captures into a gallery."""
import argparse
import html
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
WORKTREES = ROOT.parent / 'ichigo-experiments'
OUTPUT = ROOT / 'documents' / 'experiments' / 'gallery'
VARIANTS = [
    ('01-prussian-ink', 'Prussian Ink', 'Carved indigo · sweeping raised relief', 'Shared surface'),
    ('02-faded-tides', 'Faded Tides', 'Sunbleached blue · broad engraved swells', 'Shared surface'),
    ('03-paper-theatre', 'Paper Theatre', 'Individual illustrated waves · overlapping rows', 'Separate cutouts'),
    ('04-woodblock-wings', 'Woodblock Wings', 'Long scenic flats · layered ocean bands', 'Separate cutouts'),
    ('05-ink-diorama', 'Ink Diorama', 'A miniature paper set · drawn character and sea', 'Separate cutouts'),
]


def select(number):
    if not 1 <= number <= len(VARIANTS):
        raise SystemExit('Choose an experiment from 1 to 5.')
    return VARIANTS[number - 1]


def launch(number, capture=False):
    slug, *_ = select(number)
    project = ROOT if number == 3 else WORKTREES / slug
    if not project.is_dir():
        raise SystemExit(f'Missing worktree: {project}. See documents/experiments/wave_art_directions.md')
    args = [str(project / 'scripts/run_game.sh'), '--resolution', '1280x800', '--', '--weather-study']
    if capture:
        dest = OUTPUT / ('current-paper-theatre' if number == 3 else slug)
        dest.mkdir(parents=True, exist_ok=True)
        args.append(f'--capture-dir={dest}')
    subprocess.run(args, cwd=project, check=True)


def gallery():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    baseline = ROOT / 'outputs/raised-waves-pointed'
    if baseline.is_dir():
        shutil.copytree(baseline, OUTPUT / 'baseline', dirs_exist_ok=True)
    history_entries = [
        ('p1-camera/camera-20.png', 'First camera study', 'f9200ef', 'Original procedural water and framing.'),
        ('p1-feedback/camera-20.png', 'Framing feedback', '3c60802', 'Smaller framing and browner bucket.'),
        ('weather-study/calm.png', 'Flat weather panels', 'd81ce84', 'Connected illustrated sheets: the rejected flat-water direction.'),
        ('raised-waves/camera-20.png', 'First raised crests', 'Archived intermediate capture', 'Rounded raised-wave trial; no separate exact source revision is recorded.'),
        ('raised-waves-pointed/camera-20.png', 'Pointed raised crests', '8255dd4', 'The baseline before the five art branches.'),
    ]
    history_cards = []
    (OUTPUT / 'history').mkdir(exist_ok=True)
    for i, (source, title, revision, caption) in enumerate(history_entries, 1):
        target = OUTPUT / 'history' / f'{i:02}.png'
        archived_source = ROOT / 'outputs' / source
        if archived_source.exists():
            shutil.copy2(archived_source, target)
        elif not target.exists():
            raise SystemExit(f'Missing archived capture: {source}')
        history_cards.append(f'<article><div class="card-heading"><div><h2>{title}</h2><p>{caption}</p></div></div><button class="picture" data-name="{title}" data-fixed="Archived camera capture"><img src="history/{i:02}.png" alt="{title}"></button><footer>{revision}</footer></article>')
    cards = []
    manifest = []
    for number, (slug, title, description, construction) in enumerate(VARIANTS, 1):
        project = WORKTREES / slug
        missing = [angle for angle in (12, 20, 26, 38, 52) if not (OUTPUT / slug / f'camera-{angle:02}.png').is_file()]
        if missing:
            raise SystemExit(f'{slug}: missing camera captures {missing}')
        revision = subprocess.check_output(['git', '-C', str(ROOT), 'rev-parse', '--short', f'codex/{slug}'], text=True).strip()
        manifest.append(dict(number=number, slug=slug, title=title, branch=f'codex/{slug}', revision=revision, worktree=None, status='selected baseline' if number == 3 else 'retired'))
        command = f'python3 {ROOT}/scripts/wave_experiments.py run {number}'
        launch_control = f'<button class="copy" data-command="{html.escape(command, quote=True)}">Launch current Paper Theatre</button>' if number == 3 else '<span>Archived branch</span>'
        cards.append(f'''<article><div class="card-heading"><span class="number">0{number}</span><div><h2>{title}</h2><p>{description}</p></div><span class="tag">{construction}</span></div>
<button class="picture" data-name="{title}"><img data-slug="{slug}" src="{slug}/camera-20.png" alt="{title}, actual Godot viewport at 20 degrees"></button>
<footer><span>{revision}</span>{launch_control}</footer></article>''')
    (OUTPUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Ichigo / Five seas</title>
<style>
:root{color-scheme:light;--ink:#203e4b;--paper:#eee4cd;--muted:#60757b}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:15px/1.5 system-ui,sans-serif}header,main,.notes,.history-grid{max-width:1560px;margin:auto;padding:32px 36px}header{padding-bottom:20px}.eyebrow{font-size:12px;letter-spacing:.28em;text-transform:uppercase}h1{font:normal clamp(40px,6vw,76px)/1.1 Georgia,serif;margin:16px 0}header p{max-width:730px;color:var(--muted);margin-bottom:0}.toolbar{position:sticky;top:0;z-index:2;background:#eee4cdf5;border-block:1px solid #203e4b22;padding:14px 36px;display:flex;gap:10px;align-items:center;justify-content:center;flex-wrap:wrap}button{font:inherit;cursor:pointer;border:1px solid #203e4b40;color:var(--ink);background:transparent;border-radius:4px;padding:7px 14px}button.active{background:var(--ink);color:var(--paper)}.toolbar span{margin-right:12px;font-size:13px}main,.history-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:26px}article{border:1px solid #203e4b30;background:#f6edda;min-width:0}.card-heading{display:flex;align-items:center;gap:14px;padding:20px}.number{font:26px Georgia;color:#8b694b}h2{font:26px Georgia;margin:0}.card-heading p{margin:5px 0 0;color:var(--muted);font-size:12px}.tag{margin-left:auto;text-align:right;font-size:10px;letter-spacing:.06em;text-transform:uppercase;max-width:75px}.picture{padding:0;border:0;display:block;width:100%;border-radius:0}.picture img{display:block;width:100%;aspect-ratio:1.6;object-fit:contain;background:#a1b8b8}footer{padding:10px 18px;display:flex;justify-content:space-between;align-items:center;color:var(--muted);font:12px monospace}footer button{font:12px system-ui}.notes{padding-top:0;max-width:950px}.notes p{color:var(--muted)}a{color:var(--ink)}dialog{border:0;background:#172d35;padding:8px;max-width:96vw;width:1440px;color:#fff}dialog::backdrop{background:#101b22de}dialog img{width:100%;display:block}dialog button{color:#fff;border-color:#ffffff50;margin:8px}dialog span{padding:12px}#baseline{display:none;max-width:1100px;margin:25px auto}#baseline.visible{display:block}#baseline img{width:100%}@media(max-width:800px){main,.history-grid{grid-template-columns:1fr}header,main,.notes,.history-grid{padding:24px 18px}.toolbar{padding:10px}.tag{display:none}}
</style><header><div class="eyebrow">Ichigo · art experiments · September 2026</div><h1>Five ways to draw a sea.</h1><p><strong>Archived comparison — Paper Theatre is selected.</strong> <a href="current.html">See the current character and bucket pass →</a></p><p>Two studies reshape the existing water. Three rebuild it as illustrated stage pieces. These are real game captures, held at the same calm state and camera angle. Click an image to inspect it.</p></header>
<nav class="toolbar" aria-label="Camera comparison"><span>Matched camera</span><button data-angle="12">12°</button><button data-angle="20" class="active">20°</button><button data-angle="26">26°</button><button data-angle="38">38°</button><button data-angle="52">52°</button><button id="baseline-toggle">Show baseline</button><a href="#history-heading">Iteration history ↓</a></nav><section id="baseline"><h2>Before these experiments</h2><img data-slug="baseline" src="baseline/camera-20.png" alt="Original raised wave study"></section><main>''' + '\n'.join(cards) + '''</main><section class="notes" id="history-heading"><h2>Earlier iterations</h2><p>Archived engine captures in chronological order. These stay at their original framing when the matched-angle control changes. Source commits preserve the major milestones; the intermediate rounded trial is preserved here as an image.</p></section><div class="history-grid">''' + '\n'.join(history_cards) + '''</div><section class="notes"><p>Separate cutouts currently use an invisible gameplay water sampler. Their decorative edges are not exact collision surfaces; this is a later integration question. The current priority is ocean cohesion, motion and camera coverage; fish are secondary. The study interface is retained in these captures for framing context.</p><p>References: <a href="https://teamlazerbeam.itch.io/shroom-and-gloom-jam/devlog/745144/announcement-things-are-happening-with-shroom-and-gloom">Shroom and Gloom's illustrated 3D art study</a> · <a href="https://www.metmuseum.org/art/collection/search/56238">Hokusai, At Sea off Kazusa</a> · your Great Wave, Red Fuji and Shipwrecked references.</p><p>The Paper Theatre launch command opens main. Other active worktrees are retired; their Git branches preserve the source. WASD moves; Q/E or scrolling changes the camera; 1–4 select sky, 5–8 select wind. Tab hides the study controls. Paper Theatre replaced main at 1622c52.</p></section><dialog><div><span id="detail-title"></span><button id="close">Close</button></div><img id="detail-image" alt="Enlarged experiment capture"></dialog>
<script>
let angle=20;const dialog=document.querySelector('dialog');document.querySelectorAll('[data-angle]').forEach(button=>button.onclick=()=>{angle=Number(button.dataset.angle);document.querySelectorAll('[data-angle]').forEach(b=>b.classList.toggle('active',b===button));document.querySelectorAll('img[data-slug]').forEach(img=>{img.src=`${img.dataset.slug}/camera-${angle}.png`;img.alt=img.alt.replace(/at \\d+ degrees/,`at ${angle} degrees`);});});document.querySelectorAll('.picture').forEach(button=>button.onclick=()=>{document.querySelector('#detail-image').src=button.querySelector('img').src;document.querySelector('#detail-title').textContent=`${button.dataset.name} · ${button.dataset.fixed || angle + "°"}`;dialog.showModal();});document.querySelector('#close').onclick=()=>dialog.close();dialog.onclick=e=>{if(e.target===dialog)dialog.close();};document.querySelector('#baseline-toggle').onclick=e=>{const visible=document.querySelector('#baseline').classList.toggle('visible');e.target.textContent=visible?'Hide baseline':'Show baseline';};document.querySelectorAll('.copy').forEach(button=>button.onclick=async()=>{try{await navigator.clipboard.writeText(button.dataset.command);button.textContent='Copied';setTimeout(()=>button.textContent='Copy launch command',1800);}catch{window.prompt('Copy this launch command',button.dataset.command);}});
</script></html>'''
    (OUTPUT / 'index.html').write_text(page)
    print(OUTPUT / 'index.html')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['run', 'capture', 'gallery'])
    parser.add_argument('number', type=int, nargs='?')
    args = parser.parse_args()
    if args.action == 'gallery':
        gallery()
    elif args.number is None:
        parser.error('run/capture needs an experiment number (1–5)')
    else:
        launch(args.number, capture=args.action == 'capture')
