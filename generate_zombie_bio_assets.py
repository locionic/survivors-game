#!/usr/bin/env python3
"""
Generate pixel art textures for Project Z-Survivor:
1. assets/textures/toxic_bile_puddle.png (48x48)
2. assets/textures/toxic_glob.png (16x16)
3. assets/textures/zombie_spitter.png (32x32)
4. assets/textures/mutant_juggernaut.png (64x64)
5. assets/textures/bio_titan.png (80x80)
"""

import math
from PIL import Image, ImageDraw

def create_toxic_bile_puddle():
    w, h = 48, 48
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = w / 2.0, h / 2.0
    
    # Outer translucent slime border
    for y in range(h):
        for x in range(w):
            dx = (x - cx) / 21.0
            dy = (y - cy) / 14.0
            dist = math.sqrt(dx * dx + dy * dy)
            # Add organic wobble
            angle = math.atan2(y - cy, x - cx)
            wobble = 0.15 * math.sin(angle * 5.0) + 0.10 * math.cos(angle * 3.0)
            d_wobbled = dist + wobble
            
            if d_wobbled < 0.65:
                # Core toxic acid
                draw.point((x, y), (55, 230, 80, 235))
            elif d_wobbled < 0.85:
                # Mid slime
                draw.point((x, y), (30, 180, 50, 210))
            elif d_wobbled < 1.05:
                # Edge rim
                draw.point((x, y), (15, 120, 30, 160))
            elif d_wobbled < 1.18:
                # Feint splatter edge
                draw.point((x, y), (10, 80, 20, 75))

    # Add bright chartreuse acid bubbles and droplets
    bubbles = [
        (cx - 8, cy - 2, 4),
        (cx + 6, cy + 3, 3),
        (cx - 3, cy + 4, 3),
        (cx + 9, cy - 4, 2),
        (cx - 12, cy + 2, 2),
        (cx + 14, cy - 1, 2),
        (cx - 5, cy - 6, 2),
        (cx + 2, cy - 5, 2),
    ]
    for bx, by, br in bubbles:
        draw.ellipse([bx - br, by - br, bx + br, by + br], fill=(120, 255, 80, 245), outline=(180, 255, 120, 255))
        # Highlight pip
        draw.point((int(bx - br * 0.3), int(by - br * 0.3)), (240, 255, 200, 255))

    # Outer splatters
    splatters = [(5, 22), (42, 26), (20, 6), (28, 41), (12, 36), (36, 12)]
    for sx, sy in splatters:
        draw.ellipse([sx - 1, sy - 1, sx + 1, sy + 1], fill=(45, 210, 60, 200))

    img.save("assets/textures/toxic_bile_puddle.png")
    print("Saved assets/textures/toxic_bile_puddle.png")

def create_toxic_glob():
    w, h = 16, 16
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = w / 2.0, h / 2.0

    for y in range(h):
        for x in range(w):
            dist = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
            if dist <= 3.2:
                # White-hot acid center
                draw.point((x, y), (220, 255, 180, 255))
            elif dist <= 5.5:
                # Searing lime acid
                draw.point((x, y), (90, 245, 55, 245))
            elif dist <= 7.2:
                # Outer toxic corona
                draw.point((x, y), (20, 160, 35, 180))

    # Dripping droplet tail
    draw.point((int(cx - 4), int(cy + 3)), (60, 220, 45, 200))
    draw.point((int(cx + 4), int(cy - 3)), (140, 255, 90, 210))

    img.save("assets/textures/toxic_glob.png")
    print("Saved assets/textures/toxic_glob.png")

def create_zombie_spitter():
    w, h = 32, 32
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Palette
    skin_dark = (35, 60, 45, 255)
    skin_mid = (55, 95, 65, 255)
    skin_light = (80, 140, 90, 255)
    acid_glow = (90, 240, 60, 255)
    acid_bright = (180, 255, 110, 255)
    clothes_tattered = (40, 40, 48, 255)
    eye_red = (255, 40, 30, 255)

    # Tattered legs / pants
    draw.rectangle([11, 23, 14, 29], fill=clothes_tattered)
    draw.rectangle([17, 23, 20, 29], fill=clothes_tattered)
    # Feet
    draw.rectangle([10, 29, 14, 31], fill=skin_dark)
    draw.rectangle([17, 29, 21, 31], fill=skin_dark)

    # Hunched torso
    draw.rectangle([10, 12, 22, 23], fill=skin_mid)
    draw.rectangle([12, 14, 20, 22], fill=skin_light)
    # Tattered shirt remnants
    draw.rectangle([9, 15, 12, 21], fill=clothes_tattered)
    draw.rectangle([20, 16, 23, 21], fill=clothes_tattered)

    # Swollen acidic shoulder pustules
    draw.ellipse([6, 10, 11, 15], fill=acid_glow, outline=skin_dark)
    draw.point((8, 12), acid_bright)
    draw.ellipse([21, 10, 26, 15], fill=acid_glow, outline=skin_dark)
    draw.point((23, 12), acid_bright)

    # Dangling mutated arms with claws
    draw.rectangle([7, 16, 10, 24], fill=skin_mid)
    draw.rectangle([7, 24, 10, 26], fill=skin_dark) # Left claw
    draw.rectangle([22, 16, 25, 24], fill=skin_mid)
    draw.rectangle([22, 24, 25, 26], fill=skin_dark) # Right claw

    # Hunched head & distended jaw/throat
    draw.ellipse([10, 3, 22, 13], fill=skin_mid, outline=skin_dark)
    # Glowing malevolent eyes
    draw.point((13, 6), eye_red)
    draw.point((18, 6), eye_red)

    # Distended acidic throat sac & gaping maw
    draw.ellipse([11, 9, 21, 15], fill=acid_glow, outline=(20, 100, 35, 255))
    draw.ellipse([13, 10, 19, 14], fill=acid_bright)
    # Slime drip from mouth
    draw.point((16, 16), acid_bright)
    draw.point((16, 17), acid_glow)

    img.save("assets/textures/zombie_spitter.png")
    print("Saved assets/textures/zombie_spitter.png")

def create_mutant_juggernaut():
    w, h = 64, 64
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Palette
    skin_dark = (28, 42, 34, 255)
    skin_mid = (48, 74, 58, 255)
    skin_high = (72, 112, 88, 255)
    bone_armor = (160, 155, 140, 255)
    bone_dark = (90, 85, 75, 255)
    acid_core = (60, 235, 70, 255)
    acid_spark = (180, 255, 120, 255)
    blood_dark = (120, 20, 25, 255)

    # Massive pillar legs
    draw.rectangle([18, 44, 27, 58], fill=skin_mid, outline=skin_dark)
    draw.rectangle([37, 44, 46, 58], fill=skin_mid, outline=skin_dark)
    # Feet / hooves
    draw.rectangle([16, 58, 28, 62], fill=bone_dark)
    draw.rectangle([36, 58, 48, 62], fill=bone_dark)

    # Giant broad torso
    draw.rectangle([16, 20, 48, 45], fill=skin_mid, outline=skin_dark)
    draw.rectangle([20, 22, 44, 42], fill=skin_high)
    # Necrotic sinew / torn flesh streaks
    draw.line([22, 28, 28, 38], fill=blood_dark, width=2)
    draw.line([36, 26, 42, 36], fill=blood_dark, width=2)

    # Glowing toxic pustules across torso
    pustules = [(24, 25, 3), (39, 27, 4), (31, 35, 4), (23, 40, 3)]
    for px, py, pr in pustules:
        draw.ellipse([px - pr, py - pr, px + pr, py + pr], fill=acid_core, outline=skin_dark)
        draw.point((px, py), acid_spark)

    # Heavy calcified shoulder bone plates
    draw.polygon([(8, 14), (20, 14), (24, 26), (6, 24)], fill=bone_armor, outline=bone_dark)
    draw.polygon([(44, 14), (56, 14), (58, 24), (40, 26)], fill=bone_armor, outline=bone_dark)
    # Shoulder bone spikes
    draw.polygon([(6, 14), (10, 4), (14, 14)], fill=bone_armor, outline=bone_dark)
    draw.polygon([(50, 14), (54, 4), (58, 14)], fill=bone_armor, outline=bone_dark)

    # Massive tree-trunk arms
    draw.rectangle([6, 25, 16, 46], fill=skin_mid, outline=skin_dark)
    draw.rectangle([48, 25, 58, 46], fill=skin_mid, outline=skin_dark)
    # Bone-plated fists
    draw.rectangle([4, 46, 17, 54], fill=bone_armor, outline=bone_dark)
    draw.rectangle([47, 46, 60, 54], fill=bone_armor, outline=bone_dark)

    # Brutal mutant head
    draw.rectangle([25, 10, 39, 21], fill=skin_mid, outline=skin_dark)
    draw.rectangle([27, 12, 37, 19], fill=skin_high)
    # Glowing red eyes
    draw.rectangle([28, 13, 30, 15], fill=(255, 30, 20, 255))
    draw.rectangle([34, 13, 36, 15], fill=(255, 30, 20, 255))
    # Jagged metal/bone jaw
    draw.polygon([(26, 19), (38, 19), (35, 24), (29, 24)], fill=bone_armor, outline=bone_dark)

    img.save("assets/textures/mutant_juggernaut.png")
    print("Saved assets/textures/mutant_juggernaut.png")

def create_bio_titan():
    w, h = 80, 80
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Palette
    carapace_dark = (16, 26, 20, 255)
    carapace_mid = (28, 48, 36, 255)
    carapace_high = (46, 80, 60, 255)
    bio_neon = (40, 255, 80, 255)
    bio_bright = (190, 255, 130, 255)
    bone_color = (180, 175, 160, 255)
    bone_shadow = (95, 90, 80, 255)

    # Armored legs
    draw.rectangle([22, 54, 34, 72], fill=carapace_mid, outline=carapace_dark)
    draw.rectangle([46, 54, 58, 72], fill=carapace_mid, outline=carapace_dark)
    # Heavy clawed boots
    draw.polygon([(19, 72), (36, 72), (34, 78), (17, 78)], fill=carapace_dark)
    draw.polygon([(44, 72), (61, 72), (63, 78), (46, 78)], fill=carapace_dark)

    # Colossal armored chest & torso
    draw.rectangle([20, 22, 60, 54], fill=carapace_mid, outline=carapace_dark)
    draw.rectangle([24, 25, 56, 50], fill=carapace_high)

    # Radioactive bio-core in center of chest
    draw.ellipse([32, 30, 48, 46], fill=bio_neon, outline=carapace_dark)
    draw.ellipse([36, 34, 44, 42], fill=bio_bright)
    # Radiation symbol spokes
    draw.line([40, 30, 40, 46], fill=carapace_dark, width=2)
    draw.line([32, 38, 48, 38], fill=carapace_dark, width=2)

    # Giant spiked pauldrons
    draw.polygon([(8, 14), (25, 16), (28, 32), (6, 28)], fill=bone_color, outline=bone_shadow)
    draw.polygon([(55, 16), (72, 14), (74, 28), (52, 32)], fill=bone_color, outline=bone_shadow)
    # Tri-spikes on shoulders
    draw.polygon([(6, 14), (10, 2), (15, 14)], fill=bone_color, outline=bone_shadow)
    draw.polygon([(14, 14), (18, 5), (22, 15)], fill=bone_color, outline=bone_shadow)
    draw.polygon([(58, 15), (62, 5), (66, 14)], fill=bone_color, outline=bone_shadow)
    draw.polygon([(65, 14), (70, 2), (74, 14)], fill=bone_color, outline=bone_shadow)

    # Massive crushing arms
    draw.rectangle([6, 30, 20, 56], fill=carapace_mid, outline=carapace_dark)
    draw.rectangle([60, 30, 74, 56], fill=carapace_mid, outline=carapace_dark)
    # Bio-energy vein channels along arms
    draw.line([13, 32, 13, 54], fill=bio_neon, width=2)
    draw.line([67, 32, 67, 54], fill=bio_neon, width=2)

    # Titan fists / claws
    draw.rectangle([4, 56, 22, 66], fill=carapace_dark, outline=bone_shadow)
    draw.rectangle([58, 56, 76, 66], fill=carapace_dark, outline=bone_shadow)
    # Claws
    for cx in [5, 11, 17]:
        draw.polygon([(cx, 66), (cx + 2, 71), (cx + 4, 66)], fill=bone_color)
    for cx in [59, 65, 71]:
        draw.polygon([(cx, 66), (cx + 2, 71), (cx + 4, 66)], fill=bone_color)

    # Crowned demonic / mutant skull head
    draw.polygon([(30, 10), (50, 10), (46, 24), (34, 24)], fill=carapace_dark, outline=bone_shadow)
    draw.rectangle([33, 12, 47, 21], fill=carapace_high)
    # Quadruple glowing green optics
    draw.point((36, 14), bio_bright)
    draw.point((38, 14), bio_neon)
    draw.point((42, 14), bio_neon)
    draw.point((44, 14), bio_bright)
    # Steel skull horns
    draw.polygon([(29, 10), (25, 0), (33, 8)], fill=bone_color, outline=bone_shadow)
    draw.polygon([(51, 10), (55, 0), (47, 8)], fill=bone_color, outline=bone_shadow)

    img.save("assets/textures/bio_titan.png")
    print("Saved assets/textures/bio_titan.png")

if __name__ == "__main__":
    create_toxic_bile_puddle()
    create_toxic_glob()
    create_zombie_spitter()
    create_mutant_juggernaut()
    create_bio_titan()
