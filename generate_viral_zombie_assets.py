#!/usr/bin/env python3
"""
Generates pixel-art textures for Viral Zombie Features:
1. explosive_barrel.png (32x36) - Red industrial explosive drum with hazard markings
2. jersey_barrier.png (48x28) - Concrete highway barricade with yellow/black hazard stripes
3. airdrop_crate.png (36x36) - Military air-dropped tactical supply crate
4. charred_crater.png (40x24) - Ground blast scorch mark
"""

import os
from PIL import Image, ImageDraw

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(PROJECT_DIR, "assets", "textures")
os.makedirs(OUT_DIR, exist_ok=True)

def gen_explosive_barrel():
    img = Image.new("RGBA", (32, 36), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Base shadow
    draw.ellipse([6, 30, 26, 35], fill=(0, 0, 0, 70))

    # Cylindrical red drum: x 7 to 25, y 6 to 32
    # Base crimson red with lighting: highlight on left, shadow on right
    for y in range(6, 33):
        for x in range(7, 26):
            # Barrel rib rings at y = 14 and y = 24
            is_rib = (y in (13, 14, 23, 24))
            
            if x <= 10:
                # Left highlight
                c = (255, 70, 60, 255) if not is_rib else (255, 120, 110, 255)
            elif x <= 17:
                # Center red
                c = (210, 30, 25, 255) if not is_rib else (235, 50, 45, 255)
            elif x <= 22:
                # Shaded red
                c = (150, 20, 18, 255) if not is_rib else (175, 30, 28, 255)
            else:
                # Deep shadow right rim
                c = (90, 12, 12, 255)

            draw.point((x, y), fill=c)

    # Top metal rim lid
    draw.ellipse([7, 5, 25, 9], fill=(60, 65, 70, 255))
    draw.ellipse([8, 6, 24, 8], fill=(120, 125, 130, 255))
    # Cap bung
    draw.point((13, 7), fill=(220, 225, 230, 255))

    # Steel reinforcement bands at top and bottom
    for x in range(7, 26):
        draw.point((x, 9), fill=(50, 55, 60, 255) if x > 16 else (100, 105, 110, 255))
        draw.point((x, 30), fill=(40, 45, 50, 255) if x > 16 else (80, 85, 90, 255))

    # Yellow-and-black diamond hazard icon in center: y 16 to 21, x 12 to 20
    draw.polygon([(16, 16), (20, 19), (16, 22), (12, 19)], fill=(255, 215, 30, 255))
    draw.polygon([(16, 17), (19, 19), (16, 21), (13, 19)], fill=(20, 20, 20, 255))
    # Flame / exclamation mark in center of diamond
    draw.point((16, 18), fill=(255, 80, 20, 255))
    draw.point((16, 20), fill=(255, 215, 30, 255))

    img.save(os.path.join(OUT_DIR, "explosive_barrel.png"))
    print("Generated explosive_barrel.png")

def gen_jersey_barrier():
    img = Image.new("RGBA", (48, 28), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Drop shadow
    draw.ellipse([4, 22, 44, 27], fill=(0, 0, 0, 65))

    # Concrete barrier silhouette: wide at base (x 4 to 44, y 18 to 25), narrow at top (x 8 to 40, y 5 to 10)
    for y in range(6, 25):
        # Calculate width per y level
        if y < 14:
            x_min = 7
            x_max = 41
        else:
            x_min = max(4, 7 - (y - 14))
            x_max = min(44, 41 + (y - 14))

        for x in range(x_min, x_max + 1):
            # Base concrete grey tone
            if y < 9:
                base_c = (200, 205, 210, 255) # Top ledge highlight
            elif x in (x_min, x_max):
                base_c = (70, 75, 80, 255) # Edge dark contour
            elif x % 7 == 0 or y % 9 == 0:
                base_c = (140, 145, 150, 255) # Concrete texture variation
            else:
                base_c = (170, 175, 180, 255) # Mid concrete

            # Diagonal yellow / black safety stripes across the mid-face: y 10 to 18
            if 10 <= y <= 18:
                stripe = ((x + y * 2) // 5) % 2 == 0
                if stripe:
                    draw.point((x, y), fill=(235, 190, 30, 255))
                else:
                    draw.point((x, y), fill=(35, 35, 40, 255))
            else:
                draw.point((x, y), fill=base_c)

    # Weathering cracks & chipping
    draw.line([(14, 18), (17, 23)], fill=(90, 95, 100, 255))
    draw.line([(31, 8), (29, 13)], fill=(110, 115, 120, 255))

    img.save(os.path.join(OUT_DIR, "jersey_barrier.png"))
    print("Generated jersey_barrier.png")

def gen_airdrop_crate():
    img = Image.new("RGBA", (36, 36), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Ground shadow
    draw.ellipse([6, 30, 30, 35], fill=(0, 0, 0, 70))

    # Military olive-drab steel crate: x 6 to 30, y 10 to 32
    for y in range(10, 33):
        for x in range(6, 31):
            if x in (6, 30) or y in (10, 32):
                draw.point((x, y), fill=(30, 42, 28, 255)) # perimeter steel frame
            elif x in (7, 8) or y in (11, 12):
                draw.point((x, y), fill=(95, 125, 80, 255)) # highlight bevel
            else:
                draw.point((x, y), fill=(55, 78, 48, 255)) # olive body

    # Yellow cross reinforcement braces & lock latches
    draw.line([(9, 13), (27, 29)], fill=(180, 160, 40, 240), width=1)
    draw.line([(9, 29), (27, 13)], fill=(180, 160, 40, 240), width=1)
    # Center steel clasp
    draw.rectangle([15, 18, 21, 24], fill=(130, 135, 140, 255))
    draw.rectangle([16, 19, 20, 23], fill=(220, 225, 230, 255))
    draw.point((18, 21), fill=(40, 40, 40, 255))

    # Stenciled white military star / supply mark
    draw.point((18, 14), fill=(240, 245, 250, 240))
    draw.line([(16, 15), (20, 15)], fill=(240, 245, 250, 240))

    # Top beacon antenna with flashing neon cyan/green emergency light
    draw.line([(18, 5), (18, 9)], fill=(120, 125, 130, 255), width=2)
    draw.ellipse([15, 2, 21, 6], fill=(50, 255, 140, 255)) # glowing beacon
    draw.point((18, 4), fill=(255, 255, 255, 255)) # core flash

    # Parachute rigging nylon cords extending upwards
    draw.line([(7, 10), (12, 1)], fill=(220, 200, 160, 200), width=1)
    draw.line([(29, 10), (24, 1)], fill=(220, 200, 160, 200), width=1)

    img.save(os.path.join(OUT_DIR, "airdrop_crate.png"))
    print("Generated airdrop_crate.png")

def gen_charred_crater():
    img = Image.new("RGBA", (40, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Scorch oval mark on asphalt
    for y in range(24):
        for x in range(40):
            dx = (x - 20.0) / 18.0
            dy = (y - 12.0) / 10.0
            dist_sq = dx*dx + dy*dy
            if dist_sq <= 1.0:
                # Black soot center, fading outwards with orange embers
                if dist_sq < 0.25:
                    alpha = int(180 * (1.0 - dist_sq))
                    draw.point((x, y), fill=(10, 10, 12, alpha))
                elif dist_sq < 0.65:
                    alpha = int(140 * (1.0 - dist_sq))
                    draw.point((x, y), fill=(25, 20, 20, alpha))
                else:
                    alpha = int(90 * (1.0 - dist_sq))
                    draw.point((x, y), fill=(40, 30, 25, alpha))

    # Smoldering ember specks
    draw.point((18, 11), fill=(255, 120, 20, 210))
    draw.point((23, 13), fill=(255, 80, 10, 190))
    draw.point((16, 14), fill=(240, 140, 30, 180))

    img.save(os.path.join(OUT_DIR, "charred_crater.png"))
    print("Generated charred_crater.png")

if __name__ == "__main__":
    gen_explosive_barrel()
    gen_jersey_barrier()
    gen_airdrop_crate()
    gen_charred_crater()
    print("All viral zombie assets generated successfully!")
