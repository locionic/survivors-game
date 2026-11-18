#!/usr/bin/env python3
"""
Generates pixel-art textures for SurvivorQuest Visual Rebirth:
1. bamboo_reed.png (32x48)
2. moss_patch.png (32x32)
3. guardian_lion.png (48x48)
4. red_lantern.png (32x48)
"""

import os
from PIL import Image, ImageDraw

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(PROJECT_DIR, "assets", "textures")
os.makedirs(OUT_DIR, exist_ok=True)

def gen_bamboo_reed():
    # 32x48 Bamboo Reed Cluster
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Base shadow
    draw.ellipse([8, 44, 24, 47], fill=(0, 0, 0, 60))

    # Main bamboo stalk (center-left)
    for y in range(4, 46):
        # Joint rings at intervals
        if y in (12, 22, 32, 41):
            draw.line([(12, y), (17, y)], fill=(160, 210, 110, 255), width=1)
            draw.line([(11, y+1), (18, y+1)], fill=(40, 80, 30, 255), width=1)
        else:
            # Highlight on left, mid green center, shadow right
            draw.point((13, y), fill=(130, 195, 85, 255))
            draw.line([(14, y), (15, y)], fill=(85, 160, 60, 255))
            draw.point((16, y), fill=(50, 110, 40, 255))

    # Second thinner bamboo stalk (right)
    for y in range(10, 46):
        if y in (18, 28, 38):
            draw.line([(20, y), (24, y)], fill=(150, 200, 100, 255), width=1)
            draw.line([(19, y+1), (25, y+1)], fill=(35, 75, 25, 255), width=1)
        else:
            draw.point((21, y), fill=(110, 180, 75, 255))
            draw.line([(22, y), (23, y)], fill=(70, 145, 50, 255))
            draw.point((24, y), fill=(45, 100, 35, 255))

    # Third small background shoot (left)
    for y in range(24, 46):
        if y in (31, 39):
            draw.line([(6, y), (9, y)], fill=(120, 170, 80, 200), width=1)
        else:
            draw.line([(7, y), (8, y)], fill=(60, 130, 45, 200))

    # Delicate pointed bamboo leaves branching off nodes
    leaves = [
        # Off node 12 (pointing left and up)
        [(12, 12), (6, 10), (1, 6), (7, 11)],
        [(12, 13), (4, 15), (0, 18), (6, 16)],
        # Off node 22 (pointing right)
        [(17, 22), (23, 19), (29, 17), (23, 21)],
        [(17, 23), (25, 24), (31, 26), (24, 25)],
        # Off node 32 (pointing left)
        [(12, 32), (5, 29), (2, 28), (6, 31)],
        # Top crown leaves
        [(14, 4), (10, 1), (6, 0), (11, 3)],
        [(15, 4), (18, 1), (23, 0), (17, 3)],
        [(14, 5), (14, 0), (15, 0), (15, 4)],
        # Thinner stalk leaves
        [(24, 18), (28, 14), (31, 11), (27, 16)],
        [(20, 28), (14, 26), (9, 25), (15, 28)],
    ]
    for poly in leaves:
        draw.polygon(poly, fill=(95, 175, 65, 240))
        # Leaf midrib highlight
        draw.line([poly[0], poly[2]], fill=(145, 220, 100, 255))

    path = os.path.join(OUT_DIR, "bamboo_reed.png")
    img.save(path)
    print(f"Generated {path}")

def gen_moss_patch():
    # 32x32 Organic Moss Patch
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Base shape - overlapping organic blobs
    blobs = [
        (16, 16, 11, (35, 75, 30, 190)),
        (13, 14, 8, (45, 95, 38, 220)),
        (19, 15, 9, (40, 85, 35, 210)),
        (15, 19, 8, (50, 105, 42, 230)),
        (10, 18, 6, (30, 65, 25, 170)),
        (22, 17, 6, (38, 80, 32, 180)),
        (17, 11, 7, (42, 90, 36, 190)),
        (12, 11, 5, (55, 115, 46, 210)),
        (20, 21, 5, (48, 100, 40, 200)),
    ]
    for cx, cy, r, col in blobs:
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col)

    # Rich texture stippling & jade spore highlights
    spores = [
        # Bright jade-green moss tops
        (14, 14, (90, 190, 75, 240)),
        (15, 13, (110, 215, 90, 255)),
        (16, 15, (100, 205, 80, 240)),
        (18, 14, (85, 180, 70, 230)),
        (13, 17, (95, 195, 78, 240)),
        (16, 18, (115, 225, 95, 255)),
        (17, 19, (100, 200, 82, 240)),
        (19, 18, (80, 170, 65, 220)),
        (11, 14, (85, 175, 70, 210)),
        (21, 15, (75, 160, 60, 200)),
        (12, 19, (70, 150, 55, 200)),
        (15, 10, (90, 185, 75, 210)),
        # Golden-amber spore accents (thảo mộc hoa đốm)
        (14, 16, (220, 200, 80, 220)),
        (17, 13, (235, 210, 90, 230)),
        (18, 17, (210, 185, 70, 210)),
        (13, 12, (200, 190, 75, 190)),
        # Deep shadow crevices
        (11, 16, (20, 45, 18, 220)),
        (16, 21, (22, 50, 20, 220)),
        (20, 13, (18, 42, 16, 200)),
        (14, 20, (25, 55, 22, 210)),
    ]
    for x, y, col in spores:
        draw.point((x, y), fill=col)
        # 2x2 soft dab
        if len(col) == 4 and col[3] > 200:
            draw.point((x+1, y), fill=(col[0], col[1], col[2], col[3]-50))

    path = os.path.join(OUT_DIR, "moss_patch.png")
    img.save(path)
    print(f"Generated {path}")

def gen_guardian_lion():
    # 48x48 Imperial Stone Guardian Lion (Nghê / Sư Tử Đá)
    img = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Oval Ground Shadow
    draw.ellipse([6, 40, 42, 47], fill=(0, 0, 0, 90))

    # Carved Stone Plinth / Pedestal (Lotus throne base)
    # Lower base
    draw.rectangle([8, 38, 40, 44], fill=(85, 80, 75, 255))
    draw.rectangle([10, 39, 38, 43], fill=(115, 110, 102, 255))
    draw.line([(8, 38), (40, 38)], fill=(145, 140, 130, 255)) # highlight
    draw.line([(8, 44), (40, 44)], fill=(55, 50, 48, 255))   # shadow
    # Plinth carved lotus filigree band
    for x in range(11, 38, 4):
        draw.rectangle([x, 40, x+2, 42], fill=(135, 130, 120, 255))
        draw.point((x+1, 41), fill=(160, 155, 145, 255))

    # Hindquarters & Body (Proud seated wuxia posture)
    draw.ellipse([14, 20, 34, 38], fill=(95, 90, 85, 255))
    draw.ellipse([15, 21, 33, 37], fill=(120, 115, 108, 255))

    # Chest & Muscular Shoulders
    draw.rectangle([16, 17, 32, 28], fill=(125, 120, 112, 255))
    draw.line([(16, 17), (16, 28)], fill=(155, 150, 140, 255))
    draw.line([(32, 17), (32, 28)], fill=(80, 75, 70, 255))

    # Forelegs (Pillars of stone)
    # Left leg
    draw.rectangle([14, 26, 19, 39], fill=(110, 105, 98, 255))
    draw.rectangle([13, 37, 20, 39], fill=(130, 125, 115, 255)) # claw
    draw.line([(15, 39), (15, 37)], fill=(60, 55, 50, 255))
    draw.line([(18, 39), (18, 37)], fill=(60, 55, 50, 255))

    # Right leg (resting on Jade Dragon Pearl / Brocade Ball)
    draw.rectangle([28, 26, 33, 34], fill=(110, 105, 98, 255))
    draw.rectangle([27, 32, 34, 35], fill=(130, 125, 115, 255))
    # Embroidered Ball / Pearl under right paw
    draw.ellipse([27, 33, 36, 40], fill=(45, 120, 85, 255)) # Jade sphere
    draw.ellipse([28, 34, 35, 39], fill=(70, 165, 120, 255))
    draw.point((30, 35), fill=(140, 240, 190, 255)) # light glint

    # Imperial Mane: Stylized spiral swirls flanking the neck & head
    mane_curls = [
        (11, 14, 4), (33, 14, 4),
        (10, 19, 4), (34, 19, 4),
        (12, 23, 4), (32, 23, 4),
        (14, 10, 4), (30, 10, 4),
    ]
    for mx, my, r in mane_curls:
        draw.ellipse([mx, my, mx+r, my+r], fill=(85, 80, 75, 255))
        draw.ellipse([mx+1, my+1, mx+r-1, my+r-1], fill=(135, 130, 122, 255))
        draw.point((mx+1, my+1), fill=(160, 155, 145, 255))

    # Head (Majestic square leonine brow)
    draw.rectangle([17, 7, 31, 18], fill=(115, 110, 102, 255))
    draw.rectangle([18, 8, 30, 17], fill=(130, 125, 116, 255))
    # Brow ridge
    draw.line([(16, 8), (32, 8)], fill=(160, 155, 145, 255))
    draw.line([(16, 9), (32, 9)], fill=(85, 80, 72, 255))

    # Ears (alert wuxia horn-like ears)
    draw.polygon([(16, 7), (14, 3), (18, 6)], fill=(125, 120, 112, 255))
    draw.polygon([(32, 7), (34, 3), (30, 6)], fill=(125, 120, 112, 255))
    draw.polygon([(15, 5), (15, 4), (17, 6)], fill=(155, 150, 140, 255))

    # Fierce Snout & Open Roaring Jaws
    draw.rectangle([20, 12, 28, 16], fill=(140, 135, 125, 255)) # muzzle
    draw.rectangle([21, 15, 27, 18], fill=(45, 40, 38, 255))   # mouth cavity
    # White fangs
    draw.point((22, 15), fill=(230, 225, 215, 255))
    draw.point((26, 15), fill=(230, 225, 215, 255))
    draw.point((23, 17), fill=(210, 205, 195, 255))
    draw.point((25, 17), fill=(210, 205, 195, 255))

    # Glowing Jade Stone Eyes (Spirit of the Lion)
    draw.rectangle([18, 10, 20, 12], fill=(40, 35, 30, 255))
    draw.point((19, 11), fill=(70, 220, 140, 255))
    draw.rectangle([28, 10, 30, 12], fill=(40, 35, 30, 255))
    draw.point((29, 11), fill=(70, 220, 140, 255))

    # Weathered ancient stone patina (faint moss flecks on shoulders)
    draw.point((16, 21), fill=(65, 110, 60, 200))
    draw.point((17, 22), fill=(80, 130, 70, 220))
    draw.point((31, 22), fill=(65, 110, 60, 180))

    path = os.path.join(OUT_DIR, "guardian_lion.png")
    img.save(path)
    print(f"Generated {path}")

def gen_red_lantern():
    # 32x48 Traditional Wuxia Hanging Red Lantern
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Carved wooden hanging pole / bracket at top
    draw.line([(6, 2), (26, 2)], fill=(90, 50, 25, 255), width=2)
    draw.polygon([(6, 2), (10, 2), (6, 8)], fill=(120, 70, 35, 255))
    # Iron hanging ring & chain
    draw.line([(16, 3), (16, 7)], fill=(160, 150, 130, 255), width=1)
    draw.ellipse([14, 6, 18, 9], fill=(190, 160, 60, 255))

    # Ornate Gold Pagoda Top Cap
    draw.polygon([(10, 11), (22, 11), (24, 13), (8, 13)], fill=(225, 180, 45, 255))
    draw.polygon([(11, 10), (21, 10), (23, 12), (9, 12)], fill=(255, 220, 80, 255)) # rim highlight
    draw.line([(7, 13), (25, 13)], fill=(170, 125, 25, 255))

    # Hexagonal Lantern Body (Rich vermilion silk with interior golden candlelight)
    # Outer crimson silk body
    draw.polygon([
        (10, 14), (22, 14),
        (26, 21), (26, 29),
        (22, 34), (10, 34),
        (6, 29), (6, 21)
    ], fill=(195, 30, 30, 255))

    # Shading on outer ribs (Hexagonal perspective)
    draw.polygon([(6, 21), (11, 14), (11, 34), (6, 29)], fill=(155, 20, 25, 255))   # left panel shadow
    draw.polygon([(21, 14), (26, 21), (26, 29), (21, 34)], fill=(155, 20, 25, 255)) # right panel shadow

    # Radiant glowing center (Candle flame inside yellow silk)
    draw.ellipse([11, 18, 21, 30], fill=(245, 120, 35, 255))
    draw.ellipse([13, 20, 19, 28], fill=(255, 210, 65, 255))
    draw.ellipse([14, 22, 18, 26], fill=(255, 255, 180, 255)) # bright core flame

    # Gold Calligraphy Character / Fu Symbol (Phúc) on center panel
    draw.line([(15, 21), (17, 21)], fill=(180, 130, 20, 255))
    draw.line([(16, 20), (16, 27)], fill=(180, 130, 20, 255))
    draw.line([(14, 24), (18, 24)], fill=(180, 130, 20, 255))

    # Bamboo/gold ribs
    draw.line([(11, 14), (11, 34)], fill=(225, 180, 45, 200))
    draw.line([(21, 14), (21, 34)], fill=(225, 180, 45, 200))

    # Ornate Gold Bottom Cap
    draw.polygon([(10, 34), (22, 34), (20, 36), (12, 36)], fill=(225, 180, 45, 255))
    draw.line([(11, 34), (21, 34)], fill=(255, 220, 80, 255))

    # Flowing Silk Tassels & Jade Bead (Tua rua chỉ đỏ & ngọc bội)
    # Jade bead below cap
    draw.ellipse([14, 37, 18, 40], fill=(50, 160, 110, 255))
    draw.point((15, 38), fill=(130, 235, 180, 255))

    # Hanging red silk tassels
    draw.line([(16, 40), (16, 47)], fill=(210, 35, 35, 255), width=2)
    draw.line([(14, 41), (14, 46)], fill=(180, 25, 30, 255))
    draw.line([(18, 41), (18, 46)], fill=(180, 25, 30, 255))
    draw.line([(15, 46), (17, 46)], fill=(240, 190, 50, 255)) # golden silk tie at tassel end

    path = os.path.join(OUT_DIR, "red_lantern.png")
    img.save(path)
    print(f"Generated {path}")

if __name__ == "__main__":
    gen_bamboo_reed()
    gen_moss_patch()
    gen_guardian_lion()
    gen_red_lantern()
    print("All rebirth textures generated successfully!")
