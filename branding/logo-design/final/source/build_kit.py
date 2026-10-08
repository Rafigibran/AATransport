#!/usr/bin/env python3
"""Build A&A Transport final logo kit (concept B - Berbagi).
Symbol geometry is hand-built paths; wordmark is outlined from Liberation Sans
(SIL OFL) with fontTools so no live <text> remains in masters.
Colours align with the Flutter app: primary #3E7BFA, primaryDark #2F5FE0, ink #1B1D28.
"""
import os, re
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

BASE = os.path.expanduser("~/workspace/aatransport/branding/logo-design/final")
SVGDIR = os.path.join(BASE, "svg")
os.makedirs(SVGDIR, exist_ok=True)

PRIMARY="#3E7BFA"; DEEP="#2F5FE0"; INK="#1B1D28"; GREY="#8A8F9E"; WHITE="#FFFFFF"; BLACK="#000000"
BOLD="/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
REG="/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"

# ---------- symbol geometry (final B, polished) ----------
def frame(cx, fill):
    # y48..208, apex flat +-16, outer foot +-59, inner foot +-27, inner apex y108
    return f'<path fill="{fill}" d="M{cx-16} 48 H{cx+16} L{cx+59} 208 H{cx+27} L{cx} 108 L{cx-27} 208 H{cx-59} Z"/>'
def symbol_body(fill):
    return frame(66, fill) + frame(190, fill) + f'<path fill="{fill}" d="M34 162 H222 V186 H34 Z"/>'
def symbol_svg(fill, title, filename):
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256" role="img" aria-labelledby="title"><title id="title">{title.replace("&","&amp;")}</title>{symbol_body(fill)}</svg>\n'
    open(os.path.join(SVGDIR, filename),"w").write(svg)
    print(filename)
    return svg

symbol_svg(PRIMARY, "A&A Transport symbol - Berbagi (primary)", "aatransport-symbol-color.svg")
symbol_svg(INK, "A&A Transport symbol - Berbagi (ink)", "aatransport-symbol-ink.svg")
symbol_svg(BLACK, "A&A Transport symbol - Berbagi (black)", "aatransport-symbol-black.svg")

# small-size cut: thinner legs (24), larger counters, bar y170-192
def frame_small(cx, fill):
    return f'<path fill="{fill}" d="M{cx-14} 40 H{cx+14} L{cx+60} 216 H{cx+36} L{cx} 104 L{cx-36} 216 H{cx-60} Z"/>'
small_body = frame_small(64, PRIMARY) + frame_small(192, PRIMARY) + f'<path fill="{PRIMARY}" d="M36 170 H220 V192 H36 Z"/>'
small_svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256" role="img" aria-labelledby="title"><title id="title">A&amp;A Transport symbol small-size cut - Berbagi</title>{small_body}</svg>\n'
open(os.path.join(SVGDIR,"aatransport-symbol-small.svg"),"w").write(small_svg)
print("aatransport-symbol-small.svg")

# reversed thinned: white symbol scaled 97% about centre (128,128)
thinned = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256" role="img" aria-labelledby="title"><title id="title">A&amp;A Transport symbol reversed thinned (white, for dark backgrounds)</title><g transform="translate(128 128) scale(0.97) translate(-128 -128)">{symbol_body(WHITE)}</g></svg>\n'
open(os.path.join(SVGDIR,"aatransport-symbol-white-thinned.svg"),"w").write(thinned)
print("aatransport-symbol-white-thinned.svg")

# ---------- outlined text ----------
_fonts={}
def get_font(path):
    if path not in _fonts:
        f=TTFont(path); _fonts[path]=(f, f.getGlyphSet(), f.getBestCmap(), f['hmtx'].metrics, f['head'].unitsPerEm)
    return _fonts[path]

def text_width(text, font_path, size, ls=0.0):
    f,gs,cmap,hmtx,upem=get_font(font_path)
    scale=size/upem; w=0.0
    for ch in text:
        gname=cmap[ord(ch)]
        adv=hmtx[gname][0]*scale
        w+=adv+ls
    return w-ls if text else 0

def outline_text(text, font_path, size, x, baseline, fill, ls=0.0):
    """Return (svg_paths_str, total_width). Glyphs baked to outlines, no live text."""
    f,gs,cmap,hmtx,upem=get_font(font_path)
    scale=size/upem; out=[]; cx=x
    for ch in text:
        if ch==' ':
            gname=cmap[ord(' ')]; cx+=hmtx[gname][0]*scale+ls; continue
        gname=cmap[ord(ch)]
        pen=SVGPathPen(gs)
        tpen=TransformPen(pen, (scale,0,0,-scale,cx,baseline))
        gs[gname].draw(tpen)
        d=pen.getCommands()
        if d:
            out.append(f'<path fill="{fill}" d="{d}"/>')
        cx+=hmtx[gname][0]*scale+ls
    return "".join(out), (cx-x-ls if text else 0)

def _round_coords(svg):
    return re.sub(r"\d+\.\d{3,}", lambda m: f"{float(m.group(0)):.2f}", svg)
def write_svg(filename, vb, body, title):
    w,h=vb.split()[2], vb.split()[3]
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}" width="{w}" height="{h}" role="img" aria-labelledby="title"><title id="title">{title.replace("&","&amp;")}</title>{body}</svg>\n'
    svg=_round_coords(svg)
    open(os.path.join(SVGDIR,filename),"w").write(svg)
    print(filename)
    return svg

# Wordmark segments helper: "A&A" in given colour + " Transport" in other, both Bold
def wordmark(x, baseline, size, col_aa, col_rest, ls=0.0):
    p1,w1=outline_text("A&A", BOLD, size, x, baseline, col_aa, ls)
    # small space is part of second string starting with space
    p2,w2=outline_text(" Transport", BOLD, size, x+w1, baseline, col_rest, ls)
    return p1+p2, w1+w2

# Horizontal lockup (colour): canvas 1020x256, symbol 0..256, gap 28, text x=284
wm, wm_w = wordmark(284, 132, 72, PRIMARY, INK)
tag,_ = outline_text("TRAVEL IN COMFORT", REG, 25, 288, 184, GREY, ls=6)
HW=int(round(284+wm_w+36))
write_svg("aatransport-lockup-horizontal-color.svg",f"0 0 {HW} 256", symbol_body(PRIMARY)+wm+tag, "A&A Transport horizontal lockup (colour) - Berbagi")
# Horizontal ink (one-colour ink for light bg)
wm_i,_ = wordmark(284,132,72, INK, INK)
tag_i,_ = outline_text("TRAVEL IN COMFORT", REG, 25, 288, 184, INK, ls=6)
# tag in ink version should be ink too but lighter weight - keep ink
write_svg("aatransport-lockup-horizontal-ink.svg",f"0 0 {HW} 256", symbol_body(INK)+wm_i+tag_i, "A&A Transport horizontal lockup (ink)")
# Horizontal white (reversed, for board/dark) - use thinned symbol wrapper + white text
wm_white,_ = wordmark(284,132,72, WHITE, WHITE)
tag_w,_ = outline_text("TRAVEL IN COMFORT", REG, 25, 288, 184, WHITE, ls=6)
white_sym = f'<g transform="translate(128 128) scale(0.97) translate(-128 -128)">{symbol_body(WHITE)}</g>'
write_svg("aatransport-lockup-horizontal-white.svg",f"0 0 {HW} 256", white_sym+wm_white+tag_w, "A&A Transport horizontal lockup reversed (white)")

# Wordmark only (colour): width = wm width + padding 48, height 176
wm_only, w_only = wordmark(24, 88, 72, PRIMARY, INK)
tag_only,_ = outline_text("TRAVEL IN COMFORT", REG, 25, 28, 140, GREY, ls=6)
W=int(round(w_only+48))
write_svg("aatransport-wordmark-color.svg", f"0 0 {W} 176", wm_only+tag_only, "A&A Transport wordmark (colour)")

# Stacked lockup: canvas 680 wide. Symbol scaled 1.35, centred. Visual symbol bounds x7..249 (242w), y48..208 (160h)
s=1.35; vis_w=242*s; vis_h=160*s; left=(680-vis_w)/2; top=26
sym_stack = f'<g transform="translate({left-7*s:.1f} {top-48*s:.1f}) scale({s})">{symbol_body(PRIMARY)}</g>'
# wordmark below symbol, centred, size 62
wm_text_w = text_width("A&A Transport", BOLD, 62)
wm_x=(680-wm_text_w)/2; wm_base=top+vis_h+78
wm_s,_ = wordmark(wm_x, wm_base, 62, PRIMARY, INK)
tag_text_w = text_width("TRAVEL IN COMFORT", REG, 22, ls=5)
tag_x=(680-tag_text_w)/2; tag_base=wm_base+44
tag_s,_ = outline_text("TRAVEL IN COMFORT", REG, 22, tag_x, tag_base, GREY, ls=5)
H=int(round(tag_base+30))
write_svg("aatransport-lockup-stacked-color.svg", f"0 0 680 {H}", sym_stack+wm_s+tag_s, "A&A Transport stacked lockup (colour) - Berbagi")
# Stacked white
sym_stack_w = f'<g transform="translate({left-7*s:.1f} {top-48*s:.1f}) scale({s})">{symbol_body(WHITE)}</g>'
wm_sw,_ = wordmark(wm_x, wm_base, 62, WHITE, WHITE)
tag_sw,_ = outline_text("TRAVEL IN COMFORT", REG, 22, tag_x, tag_base, WHITE, ls=5)
write_svg("aatransport-lockup-stacked-white.svg", f"0 0 680 {H}", sym_stack_w+wm_sw+tag_sw, "A&A Transport stacked lockup reversed (white)")

print("lockups done, wordmark width horizontal:", round(wm_w,1))
