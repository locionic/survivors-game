#!/usr/bin/env python3
"""
Generates pixel-art textures for Zombie Outbreak Tactical Arsenal:
1. frag_grenade.png (32x32)
2. cluster_warhead.png (36x36)
3. riot_shield.png (32x48)
4. bio_barrier.png (36x48)
5. molotov.png (24x32)
6. napalm_strike.png (32x40)
7. combat_machete.png (32x40)
"""

import os
from PIL import Image, ImageDraw

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(PROJECT_DIR, "assets", "textures")
os.makedirs(OUT_DIR, exist_ok=True)

def gen_frag_grenade():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Base shadow
    draw.ellipse([8, 26, 24, 30], fill=(0, 0, 0, 70))

    # Grenade oval body
    # Base dark olive: (45, 65, 35)
    # Mid olive: (65, 95, 45)
    # Highlight: (95, 135, 60)
    for y in range(10, 28):
        for x in range(7, 25):
            # Oval mask
            dx = (x - 15.5) / 7.5
            dy = (y - 19.0) / 8.5
            if dx*dx + dy*dy <= 1.0:
                # Segment grooves (pineapple pattern)
                is_groove = (x in (11, 15, 19)) or (y in (14, 18, 22))
                if is_groove:
                    draw.point((x, y), fill=(30, 45, 25, 255))
                elif dx < -0.3 and dy < -0.2:
                    draw.point((x, y), fill=(110, 155, 70, 255)) # highlight
                elif dx > 0.3 or dy > 0.4:
                    draw.point((x, y), fill=(40, 60, 30, 255)) # shadow
                else:
                    draw.point((x, y), fill=(70, 100, 50, 255)) # midtone

    # Neck collar
    draw.rectangle([13, 7, 18, 9], fill=(60, 65, 60, 255))
    draw.point((14, 7), fill=(100, 105, 100, 255))

    # Safety fuse & lever (spoon)
    # Spoon curves down right side
    draw.line([(18, 7), (20, 8), (21, 11), (21, 20)], fill=(140, 145, 140, 255), width=1)
    draw.line([(19, 8), (22, 11), (22, 19)], fill=(90, 95, 90, 255), width=1)

    # Pull ring on left
    draw.ellipse([9, 5, 13, 9], outline=(180, 185, 190, 255))
    draw.line([(12, 7), (14, 7)], fill=(150, 155, 160, 255))

    img.save(os.path.join(OUT_DIR, "frag_grenade.png"))
    print("Generated frag_grenade.png")

def gen_cluster_warhead():
    img = Image.new("RGBA", (36, 36), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Base shadow
    draw.ellipse([10, 30, 26, 34], fill=(0, 0, 0, 65))

    # Warhead body (pointing up-right or straight up)
    # We will orient it pointing upwards (center x = 18)
    # Nose cone: y 3 to 10
    for y in range(3, 11):
        w = int((y - 3) * 1.0) + 1
        for x in range(18 - w, 18 + w + 1):
            if x < 18:
                draw.point((x, y), fill=(240, 60, 50, 255)) # red highlight
            else:
                draw.point((x, y), fill=(180, 30, 25, 255)) # red shadow

    # Cylindrical main hull: y 11 to 26
    for y in range(11, 27):
        for x in range(12, 25):
            # Hazard stripes across y 17 to 20
            if 16 <= y <= 20:
                is_stripe = ((x + y) % 6) < 3
                if is_stripe:
                    draw.point((x, y), fill=(240, 200, 20, 255) if x <= 17 else (180, 150, 10, 255))
                else:
                    draw.point((x, y), fill=(35, 35, 40, 255) if x <= 17 else (20, 20, 25, 255))
            else:
                # Titanium grey body
                if x <= 14:
                    draw.point((x, y), fill=(200, 210, 220, 255))
                elif x <= 19:
                    draw.point((x, y), fill=(150, 160, 170, 255))
                else:
                    draw.point((x, y), fill=(90, 100, 110, 255))

    # Stabilizer fins at base
    # Left fin
    draw.polygon([(12, 23), (7, 28), (12, 28)], fill=(120, 130, 140, 255))
    draw.line([(7, 28), (12, 23)], fill=(170, 180, 190, 255))
    # Right fin
    draw.polygon([(24, 23), (29, 28), (24, 28)], fill=(70, 80, 90, 255))
    draw.line([(24, 23), (29, 28)], fill=(110, 120, 130, 255))
    # Center fin keel
    draw.line([(18, 22), (18, 28)], fill=(180, 190, 200, 255), width=2)

    # Rocket nozzle & exhaust plume
    draw.rectangle([15, 27, 21, 29], fill=(60, 60, 65, 255))
    # Cyan/blue thruster flame
    draw.polygon([(16, 29), (20, 29), (18, 34)], fill=(100, 220, 255, 230))
    draw.point((18, 31), fill=(240, 255, 255, 255))

    img.save(os.path.join(OUT_DIR, "cluster_warhead.png"))
    print("Generated cluster_warhead.png")

def gen_riot_shield():
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Drop shadow
    draw.ellipse([6, 42, 26, 46], fill=(0, 0, 0, 60))

    # Shield dimensions: x 6 to 26, y 4 to 42
    # Semi-transparent polycarbonate body
    for y in range(4, 43):
        for x in range(6, 27):
            # Curved corner test
            cx = 10 if x < 10 else (22 if x > 22 else x)
            cy = 8 if y < 8 else (38 if y > 38 else y)
            dist_sq = (x - cx)**2 + (y - cy)**2
            if dist_sq <= 16:
                # Translucent glassy blue: (160, 210, 245, 175)
                # Left specular sheen
                if x in (8, 9):
                    draw.point((x, y), fill=(220, 240, 255, 215))
                elif y in (15, 28): # Reinforcement horizontal ridges
                    draw.point((x, y), fill=(200, 230, 255, 220))
                else:
                    draw.point((x, y), fill=(140, 195, 235, 160))

    # Heavy black / titanium reinforced perimeter border
    for y in range(4, 43):
        for x in range(6, 27):
            # Border pixels
            is_edge = (x in (6, 26) or y in (4, 42))
            if is_edge:
                cx = 10 if x < 10 else (22 if x > 22 else x)
                cy = 8 if y < 8 else (38 if y > 38 else y)
                if (x - cx)**2 + (y - cy)**2 <= 18:
                    draw.point((x, y), fill=(40, 48, 56, 255))
            # Corner accents
            if (x in (7, 25) and y in (5, 41)):
                draw.point((x, y), fill=(120, 135, 150, 255))

    # Tactical black handle bar & arm strap in center
    draw.rectangle([13, 20, 19, 26], fill=(25, 30, 36, 240))
    draw.rectangle([14, 21, 18, 25], fill=(50, 58, 68, 240))
    # Grip line
    draw.line([(16, 18), (16, 28)], fill=(15, 18, 22, 255), width=1)

    # Bold tactical stenciled "POLICE" strip (abstract pixel pattern)
    # Yellow warning band across upper quadrant
    draw.line([(9, 12), (23, 12)], fill=(240, 210, 30, 240), width=1)
    # Stencil dot letters
    for px in [10, 12, 14, 16, 18, 20, 22]:
        draw.point((px, 12), fill=(30, 30, 30, 255))

    img.save(os.path.join(OUT_DIR, "riot_shield.png"))
    print("Generated riot_shield.png")

def gen_bio_barrier():
    img = Image.new("RGBA", (36, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Drop shadow
    draw.ellipse([8, 42, 28, 46], fill=(0, 0, 0, 50))

    # Hexagonal energy barrier
    # Points of hexagon
    hex_pts = [(18, 3), (32, 12), (32, 34), (18, 43), (4, 34), (4, 12)]
    
    # Fill translucent energy
    draw.polygon(hex_pts, fill=(25, 210, 150, 130))

    # Inner hex lattice pattern
    for y in range(8, 40, 6):
        draw.line([(8, y), (28, y)], fill=(60, 255, 180, 80), width=1)
    for x in range(8, 30, 6):
        draw.line([(x, 8), (x, 38)], fill=(60, 255, 180, 80), width=1)

    # Neon glowing hexagon perimeter outline
    draw.polygon(hex_pts, outline=(80, 255, 190, 255))
    # Outer glow
    for p1, p2 in zip(hex_pts, hex_pts[1:] + [hex_pts[0]]):
        draw.line([p1, p2], fill=(160, 255, 230, 240), width=2)

    # Biohazard motif in center (lime yellow)
    # Center circle
    draw.ellipse([16, 21, 20, 25], fill=(230, 255, 60, 230))
    # 3 outer arcs (top, bottom-left, bottom-right)
    draw.ellipse([14, 14, 22, 20], outline=(230, 255, 60, 220), width=2)
    draw.ellipse([11, 23, 19, 29], outline=(230, 255, 60, 220), width=2)
    draw.ellipse([17, 23, 25, 29], outline=(230, 255, 60, 220), width=2)
    # Center hollow hole
    draw.point((18, 23), fill=(10, 100, 70, 255))

    # Energy spark particles at vertices
    draw.point((18, 2), fill=(255, 255, 255, 255))
    draw.point((33, 11), fill=(255, 255, 255, 255))
    draw.point((33, 35), fill=(255, 255, 255, 255))
    draw.point((18, 44), fill=(255, 255, 255, 255))
    draw.point((3, 35), fill=(255, 255, 255, 255))
    draw.point((3, 11), fill=(255, 255, 255, 255))

    img.save(os.path.join(OUT_DIR, "bio_barrier.png"))
    print("Generated bio_barrier.png")

def gen_molotov():
    img = Image.new("RGBA", (24, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Shadow
    draw.ellipse([6, 28, 18, 31], fill=(0, 0, 0, 60))

    # Bottle body: y 13 to 28, x 7 to 17
    # Rounded glass base
    for y in range(13, 28):
        for x in range(7, 18):
            # Glass container
            is_edge = (x in (7, 17) or y == 27)
            if is_edge:
                draw.point((x, y), fill=(50, 70, 50, 230))
            elif y >= 17: # Amber gasoline fluid inside
                if x in (8, 9):
                    draw.point((x, y), fill=(255, 200, 70, 220)) # liquid highlight
                else:
                    draw.point((x, y), fill=(220, 130, 20, 200)) # amber fuel
            else: # Empty bottle glass
                if x == 9:
                    draw.point((x, y), fill=(200, 230, 200, 140))
                else:
                    draw.point((x, y), fill=(90, 130, 90, 100))

    # Bottle neck: y 8 to 13, x 10 to 14
    for y in range(8, 14):
        for x in range(10, 15):
            if x in (10, 14):
                draw.point((x, y), fill=(60, 80, 60, 240))
            else:
                draw.point((x, y), fill=(100, 140, 100, 120))

    # Rag stuffed in neck
    draw.rectangle([11, 6, 13, 8], fill=(210, 205, 195, 255))
    draw.point((12, 5), fill=(170, 165, 155, 255))

    # Burning flame on top: y 1 to 6
    flame_pixels = [
        (12, 1, (255, 255, 200, 255)),
        (11, 2, (255, 230, 70, 255)), (12, 2, (255, 255, 180, 255)), (13, 2, (255, 200, 50, 255)),
        (10, 3, (255, 140, 30, 240)), (11, 3, (255, 220, 60, 255)), (12, 3, (255, 240, 100, 255)), (13, 3, (255, 160, 30, 240)),
        (10, 4, (240, 80, 20, 220)), (11, 4, (255, 160, 30, 240)), (12, 4, (255, 200, 50, 255)), (13, 4, (240, 90, 20, 220)),
        (11, 5, (220, 50, 15, 200)), (12, 5, (240, 80, 20, 220)), (13, 5, (220, 50, 15, 200)),
    ]
    for px, py, pcol in flame_pixels:
        draw.point((px, py), fill=pcol)

    img.save(os.path.join(OUT_DIR, "molotov.png"))
    print("Generated molotov.png")

def gen_napalm_strike():
    img = Image.new("RGBA", (32, 40), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Shadow
    draw.ellipse([8, 35, 24, 39], fill=(0, 0, 0, 65))

    # Napalm canister bomb
    # Nose cone: y 4 to 10
    for y in range(4, 11):
        w = int((y - 4) * 0.9)
        for x in range(16 - w, 16 + w + 1):
            draw.point((x, y), fill=(255, 110, 30, 255) if x <= 16 else (200, 70, 15, 255))

    # Main canister: y 11 to 28
    for y in range(11, 29):
        for x in range(11, 22):
            if 18 <= y <= 21: # Black hazard ring
                draw.point((x, y), fill=(30, 30, 30, 255) if x <= 15 else (20, 20, 20, 255))
            else: # Industrial yellow-orange
                if x <= 13:
                    draw.point((x, y), fill=(255, 210, 40, 255))
                elif x <= 17:
                    draw.point((x, y), fill=(240, 160, 20, 255))
                else:
                    draw.point((x, y), fill=(190, 110, 10, 255))

    # Rear fins
    draw.polygon([(11, 24), (7, 30), (11, 30)], fill=(180, 100, 20, 255))
    draw.polygon([(21, 24), (25, 30), (21, 30)], fill=(130, 70, 10, 255))

    # Flaming propulsion trail
    for y in range(30, 37):
        pw = max(1, 3 - (y - 30))
        for x in range(16 - pw, 16 + pw + 1):
            draw.point((x, y), fill=(255, 180 - (y-30)*20, 40, 220))

    img.save(os.path.join(OUT_DIR, "napalm_strike.png"))
    print("Generated napalm_strike.png")

def gen_combat_machete():
    img = Image.new("RGBA", (32, 40), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Shadow
    draw.ellipse([8, 34, 24, 38], fill=(0, 0, 0, 50))

    # Diagonal blade from bottom-left to top-right
    # Handle: (9, 31) to (14, 25)
    for t in range(7):
        hx = 9 + t
        hy = 31 - t
        draw.line([(hx, hy+1), (hx+1, hy)], fill=(30, 35, 30, 255), width=3) # Olive/black rubber grip
        draw.point((hx, hy), fill=(55, 65, 50, 255)) # grip texture

    # Hand guard
    draw.line([(14, 27), (17, 23)], fill=(70, 75, 80, 255), width=2)

    # Blade: (16, 24) to (27, 7)
    # Serrated tactical spine on upper left side
    for i in range(18):
        bx = 15 + int(i * 0.7)
        by = 24 - i
        # Blade width
        draw.line([(bx, by), (bx + 4, by + 2)], fill=(120, 130, 140, 255), width=1) # dark steel core
        # Cutting razor edge (lower right)
        draw.point((bx + 4, by + 2), fill=(235, 245, 255, 255))
        # Spine teeth (serrations)
        if i % 3 == 0:
            draw.point((bx - 1, by), fill=(80, 85, 90, 255))

    # Curved machete tip
    draw.polygon([(26, 6), (28, 8), (27, 9)], fill=(240, 250, 255, 255))

    img.save(os.path.join(OUT_DIR, "combat_machete.png"))
    print("Generated combat_machete.png")

if __name__ == "__main__":
    gen_frag_grenade()
    gen_cluster_warhead()
    gen_riot_shield()
    gen_bio_barrier()
    gen_molotov()
    gen_napalm_strike()
    gen_combat_machete()
    print("All Zombie Tactical Arsenal assets generated successfully!")
