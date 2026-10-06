#!/usr/bin/env python3
"""
Generates the Ba Lang Huyen (ancient courtyard) arena decor textures.

Phase 2 of SURVIVORQUEST_VISUAL_REBIRTH_PLAN.md -- the arena was a dark grey
cobblestone checkerboard stretched to 2800x2100, which read as a test dungeon
rather than a martial realm. Every texture this writes exists for exactly one
consumer:

    arena_courtyard.png  main.tscn Background + GameManager.STAGES["plains"]
    bamboo_reed.png      scenes/arena.tscn Bamboo
    guardian_lion.png    scenes/arena.tscn GuardianLions
    fence_rail.png       scenes/arena.tscn Fences
    lantern_post.png     scenes/arena.tscn LanternPosts
    lantern_glow.png     scenes/arena.tscn LanternPosts (additive, paired w/ PointLight2D)
    autumn_leaf.png      scenes/arena.tscn AutumnLeaves (CPUParticles2D)

None of these are gameplay assets. Nothing reads a pixel off them; the arena's
collision walls, spawn ring and obstacle layout live in scenes/main.tscn and
scripts/enemy_spawner.gd and are untouched by this script.

Unlike the older generate_*.py scripts, OUT_DIR is derived from this file's own
location. generate_sprites.py hardcodes /home/renovibe79/..., which is a
developer's machine and is not this one -- running it here would have written
the whole texture set into a path that does not exist.
"""

from PIL import Image, ImageDraw, ImageFilter, ImageChops
import math
import os
import random

OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets", "textures")
os.makedirs(OUT_DIR, exist_ok=True)

# Seeded so the "hand-authored" look is reproducible: a re-run must not reshuffle
# the moss into a different courtyard and produce a noisy binary diff.
random.seed(20261006)


def out(name):
    return os.path.join(OUT_DIR, name)


# ---------------------------------------------------------------- helpers

def wrapped(img, box_fn):
    """Draws a shape nine times (3x3 neighbourhood) so it survives the wrap.

    Every call past the first is offset by a full texture dimension. For a
    seamless tile that is exactly the set of pixels the shape bleeds into, so a
    stone straddling x=0 gets its other half drawn at x=W instead of clipped.
    """
    w, h = img.size
    for dx in (-w, 0, w):
        for dy in (-h, 0, h):
            box_fn(dx, dy)


def jitter_color(base, rng, spread=14):
    """Per-stone tone variation. Returns RGB only -- callers append their own
    alpha, so baking one in here produced 5-tuples PIL rejects."""
    return tuple(
        max(0, min(255, base[i] + rng.randint(-spread, spread))) for i in range(3)
    )


def speckle(img, rng, amount=900, spread=10):
    """Per-pixel luminance grit -- the difference between 'painted' and 'worn'."""
    noise = Image.effect_noise(img.size, spread).convert("L")
    base = img.convert("RGB")
    outimg = ImageChops.overlay(base, noise.convert("RGB"))
    outimg = Image.blend(base, outimg, 0.28)
    if amount:
        px = outimg.load()
        w, h = outimg.size
        for _ in range(amount):
            x, y = rng.randrange(w), rng.randrange(h)
            c = px[x, y]
            k = rng.randint(-spread, spread * 2)
            px[x, y] = (
                max(0, min(255, c[0] + k)),
                max(0, min(255, c[1] + k)),
                max(0, min(255, c[2] + k)),
            )
    return outimg


# ---------------------------------------------------- 1. courtyard paving

def gen_courtyard():
    """Seamless 256x256 weathered flagstone paving with green moss.

    The old floor was a 64x64 cobblestone tile: at the arena's 2800x2100 quad
    that is ~44x magnification, so the "bricks" were 600px soft grey squares --
    the checkerboard. 256x256 is 2.25x the pixels of the old art at 4x less
    magnification, which is the smallest jump that survives that upscale.
    """
    S = 256
    rng = random.Random(4711)
    img = Image.new("RGBA", (S, S), (58, 52, 44, 255))
    draw = ImageDraw.Draw(img)

    # Joints first: a continuous dark mortar that moss later creeps into.
    draw.rectangle([0, 0, S - 1, S - 1], fill=(38, 34, 28, 255))

    # Running-bond flagstones, 4 courses of 64px. Each stone is nudged off the
    # grid by a couple of pixels so the courses do not read as a checkerboard --
    # that regularity was most of the old art's problem.
    stone_w, stone_h = 64, 64
    for row in range(4):
        offset = stone_w // 2 if row % 2 else 0
        for col in range(-1, 5):
            x0 = col * stone_w + offset
            y0 = row * stone_h
            tone = jitter_color((122, 113, 98), rng, 16)

            def _stone(dx, dy, x0=x0, y0=y0, tone=tone, row=row):
                a = rng.randint(-3, 3)
                b = rng.randint(-3, 3)
                pts = [
                    (x0 + 2 + a, y0 + 2 + rng.randint(-2, 2)),
                    (x0 + stone_w - 2 + b, y0 + 2 + rng.randint(-2, 2)),
                    (x0 + stone_w - 2 + rng.randint(-2, 2), y0 + stone_h - 2),
                    (x0 + 2 + rng.randint(-2, 2), y0 + stone_h - 2),
                ]
                draw.polygon([(px + dx, py + dy) for px, py in pts], fill=tone)
                # Sun-bleached top edge, damp shadow along the bottom one.
                draw.line([(pts[0][0] + dx, pts[0][1] + dy),
                           (pts[1][0] + dx, pts[1][1] + dy)],
                          fill=(tone[0] + 16, tone[1] + 15, tone[2] + 12, 255), width=1)
                draw.line([(pts[3][0] + dx, pts[3][1] + dy),
                           (pts[2][0] + dx, pts[2][1] + dy)],
                          fill=(max(0, tone[0] - 26), max(0, tone[1] - 26),
                                max(0, tone[2] - 24), 255), width=1)

            wrapped(img, _stone)

    # Weathered grain and chips.
    img = speckle(img.convert("RGB"), rng, amount=1400, spread=9).convert("RGBA")

    # Moss: soft green blotches biased into the joints and lower corners of the
    # stones, where water actually sits. Blurred so it reads as growth rather
    # than as green confetti.
    moss = Image.new("L", (S, S), 0)
    md = ImageDraw.Draw(moss)
    for _ in range(46):
        cx, cy = rng.randrange(S), rng.randrange(S)
        r = rng.randint(5, 17)
        # Squash toward the joint lines (multiples of 64) for most patches.
        if rng.random() < 0.6:
            cy = min(S - 1, max(0, (cy // 64) * 64 + rng.choice([0, 64])))
        val = rng.randint(90, 175)
        def _blob(dx, dy, cx=cx, cy=cy, r=r, val=val):
            md.ellipse([cx - r + dx, cy - int(r * 0.6) + dy,
                        cx + r + dx, cy + int(r * 0.6) + dy], fill=val)
        wrapped(moss, _blob)
    moss = moss.filter(ImageFilter.GaussianBlur(1.4))

    moss_rgb = None  # moss is mixed into the base per-pixel below, not composited

    base = img.convert("RGBA")
    px_base, px_mask, px_out = base.load(), moss.load(), base.load()
    w, h = base.size
    tones = [(74, 112, 52), (60, 96, 45), (90, 124, 62), (46, 80, 38)]
    for y in range(h):
        for x in range(w):
            m = px_mask[x, y]
            if m < 18:
                continue
            t = tones[(x * 7 + y * 13) % len(tones)]
            # Ease in so the moss edge is a gradient, not a stencil boundary.
            k = min(0.88, (m - 18) / 150.0)
            r0, g0, b0, a0 = px_base[x, y]
            r0 = int(r0 + (t[0] - r0) * k)
            g0 = int(g0 + (t[1] - g0) * k)
            b0 = int(b0 + (t[2] - b0) * k)
            px_out[x, y] = (r0, g0, b0, 255)

    # A little fallen leaf litter, in the courtyard's own crimson/gold so the
    # floor agrees with the leaf particles drifting over it.
    ld = ImageDraw.Draw(base)
    for _ in range(26):
        x, y = rng.randrange(S), rng.randrange(S)
        c = rng.choice([(120, 46, 40), (146, 92, 40), (104, 38, 34)])
        def _leaf(dx, dy, x=x, y=y, c=c):
            ld.line([(x + dx, y + dy), (x + dx + rng.randint(3, 6), y + dy + rng.randint(-2, 2))],
                    fill=c + (200,), width=1)
        wrapped(base, _leaf)

    base.convert("RGB").save(out("arena_courtyard.png"))
    print("Generated arena_courtyard.png")


# --------------------------------------------------------- 2. bamboo reeds

def gen_bamboo():
    """A clump of bamboo culms -- the reed thicket that lines the courtyard."""
    W, H = 72, 176
    rng = random.Random(90210)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Culms are rooted near the canvas floor and reach most of the way up, so
    # the clump fills its 176px height instead of hugging the top edge.
    culms = [
        (14, 166, (96, 138, 62), -3),
        (28, 158, (112, 152, 70), 2),
        (40, 170, (84, 124, 56), -1),
        (56, 162, (104, 146, 64), 4),
    ]
    for cx, base_y, col, lean in culms:
        top = rng.randint(6, 26)
        wdt = rng.randint(5, 8)
        # Culm as a slightly leaning 2px-wide column, seg by seg.
        for y in range(base_y, top, -3):
            t = (base_y - y) / float(max(1, base_y - top))
            x = cx + lean * t
            d.line([(x, y), (x, y - 3)], fill=col + (255,), width=wdt)
            d.line([(x - wdt // 2, y), (x - wdt // 2, y - 3)],
                   fill=(col[0] + 26, col[1] + 30, col[2] + 18, 255), width=1)
            # Node ring every ~34px.
            if (base_y - y) % 34 < 3:
                d.line([(x - wdt // 2 - 1, y), (x + wdt // 2 + 1, y)],
                       fill=(70, 100, 44, 255), width=2)
        # Leaf sprays off the culm, densest in the upper half where real bamboo
        # carries foliage but reachable anywhere along the stalk.
        for _ in range(14):
            ly = rng.randint(top + 6, base_y - 6)
            t = (base_y - ly) / float(max(1, base_y - top))
            lx = cx + lean * t
            ang = rng.uniform(-1.1, 1.1)
            ln = rng.randint(11, 20)
            ex, ey = lx + math.cos(ang) * ln, ly + math.sin(ang) * ln * 0.6
            lc = (rng.randint(70, 128), rng.randint(116, 162), rng.randint(48, 84), 235)
            d.line([(lx, ly), (ex, ey)], fill=lc, width=3)
            d.line([(lx, ly), ((lx + ex) / 2, ly - 3)], fill=lc, width=2)

    img.save(out("bamboo_reed.png"))
    print("Generated bamboo_reed.png")


# ------------------------------------------------------ 3. stone guardian lion

def gen_lion():
    """A weathered stone shishi (guardian lion) on its plinth."""
    S = 128
    rng = random.Random(31415)
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    stone = (138, 132, 120)
    stone_d = (104, 99, 90)
    stone_l = (162, 156, 143)

    # Plinth
    d.polygon([(18, 120), (110, 120), (106, 100), (22, 100)], fill=stone_d + (255,))
    d.rectangle([14, 118, 114, 126], fill=(120, 114, 104, 255))

    # Haunches and chest -- one blob body, carved silhouette.
    d.polygon([(40, 100), (36, 74), (46, 58), (74, 56), (92, 72), (96, 100)], fill=stone + (255,))
    # Forelegs
    d.rectangle([44, 76, 56, 102], fill=stone + (255,))
    d.rectangle([74, 76, 86, 102], fill=stone + (255,))
    # Paw over a ball (the shishi always grips one)
    d.ellipse([78, 92, 100, 112], fill=stone_l + (255,))

    # Mane: overlapping curls around the head
    for i in range(16):
        ang = i / 16.0 * math.tau
        cx = 60 + math.cos(ang) * 19
        cy = 40 + math.sin(ang) * 17
        r = 9 if i % 2 else 11
        d.ellipse([cx - r, cy - r, cx + r, cy + r],
                  fill=jitter_color(stone, rng, 12) + (255,))
    # Head + muzzle
    d.ellipse([42, 26, 80, 58], fill=stone_l + (255,))
    d.ellipse([48, 40, 74, 56], fill=(150, 144, 132, 255))
    # Brow and eyes
    d.rectangle([47, 33, 74, 36], fill=(96, 91, 83, 255))
    d.ellipse([50, 38, 56, 44], fill=(48, 44, 40, 255))
    d.ellipse([64, 38, 70, 44], fill=(48, 44, 40, 255))
    # Curled tail
    d.arc([70, 66, 108, 100], start=250, end=110, fill=stone_d + (255,), width=6)

    # Weathering: dark grime settled low, a couple of chipped edges.
    grime = Image.new("L", (S, S), 0)
    gd = ImageDraw.Draw(grime)
    gd.ellipse([10, 96, 118, 128], fill=120)
    grime = grime.filter(ImageFilter.GaussianBlur(6))
    px, gp = img.load(), grime.load()
    for y in range(S):
        for x in range(S):
            if gp[x, y] > 10 and px[x, y][3] > 0:
                k = min(0.45, gp[x, y] / 260.0)
                r0, g0, b0, a0 = px[x, y]
                px[x, y] = (int(r0 * (1 - k * 0.5)), int(g0 * (1 - k * 0.5)),
                            int(b0 * (1 - k * 0.45)), a0)

    img.save(out("guardian_lion.png"))
    print("Generated guardian_lion.png")


# ---------------------------------------------------- 4. carved wood fence rail

def gen_fence():
    """Horizontally tileable carved fence panel: posts at x=0 and x=W/2.

    Tiling seamlessness needs the post centred *on* the edge, so half of it
    lives at x=0 and half at x=W -- which is what the three wrapped draws below
    produce. arena.gd relies on this to run one repeating Sprite2D per side.
    """
    W, H = 128, 72
    rng = random.Random(777)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    wood = (108, 74, 48)
    wood_d = (74, 50, 32)
    wood_l = (134, 96, 62)

    def rails(dx, dy):
        # Two carved rails with a bevel highlight along the top of each.
        for y in (18, 46):
            d.rectangle([0 + dx, y + dy, W + dx, y + 10 + dy], fill=wood + (255,))
            d.rectangle([0 + dx, y + dy, W + dx, y + 2 + dy], fill=wood_l + (255,))
            d.rectangle([0 + dx, y + 9 + dy, W + dx, y + 10 + dy], fill=wood_d + (255,))
            # Carved cloud-scroll motif stamped along the upper rail.
            for cx in range(8, W, 32):
                d.arc([cx - 7 + dx, y + 1 + dy, cx + 7 + dx, y + 9 + dy],
                      start=200, end=20, fill=wood_d + (255,), width=2)

    def posts(dx, dy):
        for cx in (0, W // 2):
            d.rectangle([cx - 6 + dx, 6 + dy, cx + 6 + dx, H + dy], fill=wood_d + (255,))
            d.rectangle([cx - 4 + dx, 6 + dy, cx - 2 + dx, H + dy], fill=wood_l + (255,))
            # Cap finial
            d.polygon([(cx - 9 + dx, 6 + dy), (cx + 9 + dx, 6 + dy),
                       (cx + 6 + dx, 0 + dy), (cx - 6 + dx, 0 + dy)],
                      fill=wood + (255,))

    wrapped(img, rails)
    wrapped(img, posts)

    # Grain.
    for _ in range(150):
        x, y = rng.randrange(W), rng.randrange(H)
        d.point((x, y), fill=(96, 66, 42, 90))

    img.save(out("fence_rail.png"))
    print("Generated fence_rail.png")


# --------------------------------------------------------- 5. lantern post

def gen_lantern_post():
    """Carved post carrying a red paper lantern -- the courtyard's night light."""
    W, H = 48, 144
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    post = (86, 58, 38)
    post_l = (112, 78, 50)
    # Post + cross arm
    d.rectangle([20, 26, 28, H], fill=post + (255,))
    d.rectangle([20, 26, 22, H], fill=post_l + (255,))
    d.rectangle([12, 26, 36, 32], fill=post + (255,))
    # Base stone
    d.polygon([(12, H - 8), (36, H - 8), (34, H), (14, H)], fill=(118, 112, 100, 255))

    # Lantern body
    d.line([(24, 32), (24, 44)], fill=post_l + (255,), width=2)
    d.ellipse([8, 42, 40, 86], fill=(196, 44, 38, 255))
    d.ellipse([12, 46, 36, 82], fill=(226, 66, 48, 255))
    d.ellipse([16, 54, 26, 70], fill=(248, 140, 88, 200))
    # Ribs
    for x in (14, 24, 34):
        d.arc([x - 6, 44, x + 6, 84], start=90, end=270, fill=(150, 30, 28, 200), width=1)
    # Caps
    d.rectangle([18, 40, 30, 44], fill=(70, 48, 30, 255))
    d.rectangle([18, 84, 30, 88], fill=(70, 48, 30, 255))
    # Tassel
    d.line([(24, 88), (24, 100)], fill=(198, 150, 52, 255), width=2)
    d.polygon([(24, 100), (29, 106), (24, 112), (19, 106)], fill=(206, 58, 46, 255))

    img.save(out("lantern_post.png"))
    print("Generated lantern_post.png")


# ---------------------------------------------------------- 6. lantern glow

def gen_lantern_glow():
    """Soft radial falloff, drawn additively behind each post."""
    S = 256
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    px = img.load()
    c = S / 2.0
    for y in range(S):
        for x in range(S):
            dist = math.hypot(x - c, y - c) / c
            if dist >= 1.0:
                continue
            # Cubic falloff: bright core, long soft skirt, no visible ring edge.
            a = int(255 * (1.0 - dist) ** 3)
            px[x, y] = (255, 168, 84, a)
    img.save(out("lantern_glow.png"))
    print("Generated lantern_glow.png")


# --------------------------------------------------------- 7. autumn leaf

def gen_leaf():
    """Golden maple leaf -- the CPUParticles2D texture."""
    S = 32
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    gold = (232, 168, 58)
    gold_d = (188, 118, 34)
    gold_l = (250, 208, 120)

    # Five-lobed maple silhouette, drawn as a fan of tapered spikes.
    cx, cy = 16, 17
    for ang, ln in [(-90, 9), (-140, 8), (-40, 8), (-165, 6), (-15, 6)]:
        a = math.radians(ang)
        ex, ey = cx + math.cos(a) * ln, cy + math.sin(a) * ln
        d.polygon([(cx, cy), (ex - 2, ey - 1), (ex + 1, ey + 2), (cx + 1, cy + 1)],
                  fill=gold + (255,))
    # Notch between the two centre lobes
    d.polygon([(cx - 3, cy - 2), (cx + 3, cy - 2), (cx, cy + 4)],
              fill=(0, 0, 0, 0))
    d.ellipse([cx - 5, cy - 4, cx + 5, cy + 6], fill=gold + (255,))
    # Veins + stem
    for ang in (-90, -140, -40):
        a = math.radians(ang)
        d.line([(cx, cy + 1), (cx + math.cos(a) * 7, cy + math.sin(a) * 7)],
               fill=gold_d + (200,), width=1)
    d.line([(cx, cy + 5), (cx, S - 3)], fill=gold_d + (255,), width=2)
    d.ellipse([cx - 3, cy - 5, cx + 1, cy - 1], fill=gold_l + (255,))

    img.save(out("autumn_leaf.png"))
    print("Generated autumn_leaf.png")


if __name__ == "__main__":
    gen_courtyard()
    gen_bamboo()
    gen_lion()
    gen_fence()
    gen_lantern_post()
    gen_lantern_glow()
    gen_leaf()
    print("Arena decor textures written to", OUT_DIR)