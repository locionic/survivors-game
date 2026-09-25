#!/usr/bin/env python3
"""
Generates stylized pixel-art textures for SurvivorQuest using PIL.
"""

from PIL import Image, ImageDraw
import os

OUT_DIR = "/home/renovibe79/survivors-game/assets/textures"
os.makedirs(OUT_DIR, exist_ok=True)

# 1. Dungeon Cobblestone Floor (64x64 Seamless Tile)
def gen_floor():
    img = Image.new("RGBA", (64, 64), (32, 34, 42, 255))
    draw = ImageDraw.Draw(img)
    
    # Grid of cobblestone bricks
    # Row 1
    bricks = [
        (2, 2, 30, 14, (48, 52, 62)),
        (34, 2, 62, 14, (44, 48, 58)),
        # Row 2 (offset)
        (2, 18, 14, 30, (42, 46, 56)),
        (18, 18, 46, 30, (52, 56, 68)),
        (50, 18, 62, 30, (46, 50, 60)),
        # Row 3
        (2, 34, 28, 46, (45, 49, 59)),
        (32, 34, 62, 46, (50, 54, 66)),
        # Row 4 (offset)
        (2, 50, 22, 62, (44, 48, 58)),
        (26, 50, 54, 62, (52, 56, 68)),
        (58, 50, 62, 62, (42, 46, 56)),
    ]
    
    for x1, y1, x2, y2, col in bricks:
        draw.rectangle([x1, y1, x2, y2], fill=col)
        # Top-left highlight
        draw.line([(x1, y1), (x2-1, y1)], fill=(col[0]+15, col[1]+15, col[2]+18))
        draw.line([(x1, y1), (x1, y2-1)], fill=(col[0]+15, col[1]+15, col[2]+18))
        # Bottom-right shadow
        draw.line([(x1+1, y2), (x2, y2)], fill=(col[0]-14, col[1]-14, col[2]-14))
        draw.line([(x2, y1+1), (x2, y2)], fill=(col[0]-14, col[1]-14, col[2]-14))
        
    img.save(f"{OUT_DIR}/dungeon_floor.png")
    print("Generated dungeon_floor.png")

# 2. Player: Hero Knight / Ranger (32x32)
def gen_player():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Shadow
    draw.ellipse([6, 26, 26, 31], fill=(0, 0, 0, 80))
    
    # Blue Hood / Cloak
    draw.rectangle([10, 4, 22, 14], fill=(30, 90, 180))
    draw.rectangle([8, 14, 24, 24], fill=(22, 70, 150))
    
    # Cloak Trim / Shoulders
    draw.rectangle([7, 12, 10, 20], fill=(18, 55, 120))
    draw.rectangle([22, 12, 25, 20], fill=(18, 55, 120))
    
    # Face Area (Shadow inside hood)
    draw.rectangle([12, 8, 20, 14], fill=(16, 20, 32))
    
    # Glowing Cyan Eyes
    draw.point((14, 10), fill=(80, 240, 255))
    draw.point((18, 10), fill=(80, 240, 255))
    
    # Steel Breastplate
    draw.rectangle([12, 15, 20, 21], fill=(180, 195, 210))
    draw.rectangle([14, 16, 18, 19], fill=(220, 235, 250))
    
    # Gold Belt Buckle
    draw.rectangle([11, 22, 21, 23], fill=(70, 50, 30))
    draw.rectangle([15, 22, 17, 24], fill=(240, 200, 60))
    
    # Boots
    draw.rectangle([11, 25, 14, 28], fill=(40, 30, 20))
    draw.rectangle([18, 25, 21, 28], fill=(40, 30, 20))
    
    img.save(f"{OUT_DIR}/player.png")
    print("Generated player.png")

# 3. Enemy Swarmer: Shadow Bat (24x24)
def gen_bat():
    img = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Wings
    draw.polygon([(1, 10), (7, 4), (11, 10), (7, 14)], fill=(90, 30, 120))
    draw.polygon([(23, 10), (17, 4), (13, 10), (17, 14)], fill=(90, 30, 120))
    draw.polygon([(3, 10), (7, 6), (11, 10)], fill=(130, 50, 170))
    draw.polygon([(21, 10), (17, 6), (13, 10)], fill=(130, 50, 170))
    
    # Body
    draw.ellipse([9, 7, 15, 17], fill=(45, 15, 60))
    
    # Ears
    draw.polygon([(9, 7), (8, 3), (11, 6)], fill=(70, 20, 95))
    draw.polygon([(15, 7), (16, 3), (13, 6)], fill=(70, 20, 95))
    
    # Red Eyes & Fangs
    draw.point((10, 10), fill=(255, 50, 70))
    draw.point((14, 10), fill=(255, 50, 70))
    draw.point((11, 14), fill=(255, 255, 255))
    draw.point((13, 14), fill=(255, 255, 255))
    
    img.save(f"{OUT_DIR}/bat.png")
    print("Generated bat.png")

# 4. Enemy Tank: Armored Skeleton (28x28)
def gen_skeleton():
    img = Image.new("RGBA", (28, 28), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Shadow
    draw.ellipse([5, 23, 23, 27], fill=(0, 0, 0, 80))
    
    # Skull
    draw.rectangle([9, 5, 19, 13], fill=(215, 215, 205))
    # Eye Sockets (Dark with green embers)
    draw.rectangle([11, 8, 13, 10], fill=(20, 20, 20))
    draw.rectangle([16, 8, 18, 10], fill=(20, 20, 20))
    draw.point((12, 9), fill=(100, 255, 120))
    draw.point((17, 9), fill=(100, 255, 120))
    # Teeth
    draw.line([(11, 13), (17, 13)], fill=(40, 40, 40))
    
    # Iron Helmet
    draw.rectangle([8, 3, 20, 6], fill=(110, 120, 135))
    draw.polygon([(13, 1), (15, 1), (14, 4)], fill=(160, 175, 195))
    
    # Ribcage / Armor
    draw.rectangle([10, 14, 18, 20], fill=(175, 175, 165))
    draw.line([(10, 16), (18, 16)], fill=(30, 30, 30))
    draw.line([(11, 18), (17, 18)], fill=(30, 30, 30))
    
    # Rusty Wooden Shield
    draw.polygon([(3, 12), (8, 10), (8, 22), (3, 20)], fill=(120, 70, 35))
    draw.rectangle([4, 15, 7, 17], fill=(160, 170, 180)) # Shield boss
    
    # Bone Legs
    draw.line([(11, 21), (11, 25)], fill=(200, 200, 190), width=2)
    draw.line([(17, 21), (17, 25)], fill=(200, 200, 190), width=2)
    
    img.save(f"{OUT_DIR}/skeleton.png")
    print("Generated skeleton.png")

# 5. Elite Mini-Boss: Demon Minotaur Lord (48x48)
def gen_boss():
    img = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Giant Shadow
    draw.ellipse([8, 40, 40, 47], fill=(0, 0, 0, 120))
    
    # Massive Horns
    draw.polygon([(8, 6), (14, 12), (18, 16), (14, 18), (8, 12)], fill=(220, 190, 140))
    draw.polygon([(40, 6), (34, 12), (30, 16), (34, 18), (40, 12)], fill=(220, 190, 140))
    draw.point((8, 6), fill=(255, 230, 180))
    draw.point((40, 6), fill=(255, 230, 180))
    
    # Demon Face & Torso (Crimson Red with dark shades)
    draw.rectangle([16, 12, 32, 26], fill=(190, 35, 45))
    draw.rectangle([13, 24, 35, 38], fill=(150, 25, 35))
    
    # Shoulder Spikes
    draw.polygon([(10, 20), (14, 25), (10, 28)], fill=(70, 15, 20))
    draw.polygon([(38, 20), (34, 25), (38, 28)], fill=(70, 15, 20))
    
    # Magma Veins
    draw.line([(20, 26), (22, 33), (25, 35)], fill=(255, 170, 30), width=2)
    draw.line([(28, 26), (26, 31), (27, 36)], fill=(255, 170, 30), width=2)
    
    # Blazing Yellow Eyes & Fangs
    draw.rectangle([19, 16, 22, 19], fill=(255, 240, 60))
    draw.rectangle([26, 16, 29, 19], fill=(255, 240, 60))
    draw.polygon([(21, 23), (23, 26), (25, 23)], fill=(255, 255, 255))
    draw.polygon([(27, 23), (25, 26), (23, 23)], fill=(255, 255, 255))
    
    # Heavy Iron Belt & Loincloth
    draw.rectangle([16, 37, 32, 40], fill=(80, 85, 95))
    draw.rectangle([22, 37, 26, 41], fill=(240, 190, 40))
    
    # Massive Stompers
    draw.rectangle([15, 40, 20, 44], fill=(110, 20, 28))
    draw.rectangle([28, 40, 33, 44], fill=(110, 20, 28))
    
    img.save(f"{OUT_DIR}/boss.png")
    print("Generated boss.png")

# 6. Dagger Projectile (24x12)
def gen_dagger():
    img = Image.new("RGBA", (24, 12), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Steel blade
    draw.polygon([(8, 4), (22, 6), (8, 8)], fill=(225, 235, 245))
    draw.line([(8, 6), (21, 6)], fill=(255, 255, 255))
    # Crossguard
    draw.rectangle([6, 2, 8, 10], fill=(240, 190, 50))
    # Grip & Pommel
    draw.rectangle([2, 5, 6, 7], fill=(100, 60, 25))
    draw.rectangle([0, 4, 2, 8], fill=(240, 190, 50))
    img.save(f"{OUT_DIR}/dagger.png")
    print("Generated dagger.png")

# 7. XP Gem (16x16)
def gen_gem():
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Cyan Faceted Diamond
    draw.polygon([(8, 1), (14, 7), (8, 15), (2, 7)], fill=(20, 180, 240))
    draw.polygon([(8, 1), (12, 7), (8, 11), (4, 7)], fill=(120, 240, 255))
    draw.polygon([(6, 4), (8, 2), (8, 6), (5, 6)], fill=(255, 255, 255, 220)) # Specular highlight
    img.save(f"{OUT_DIR}/gem.png")
    print("Generated gem.png")

# 8. Golden Treasure Chest (28x24)
def gen_chest():
    img = Image.new("RGBA", (28, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Shadow
    draw.ellipse([2, 19, 26, 23], fill=(0, 0, 0, 90))
    # Chest Base
    draw.rectangle([3, 10, 25, 21], fill=(160, 90, 30))
    # Chest Lid
    draw.polygon([(2, 10), (6, 3), (22, 3), (26, 10)], fill=(200, 115, 40))
    # Gold bands
    draw.rectangle([5, 3, 8, 21], fill=(250, 205, 60))
    draw.rectangle([20, 3, 23, 21], fill=(250, 205, 60))
    # Keyhole Plate
    draw.rectangle([12, 11, 16, 16], fill=(250, 205, 60))
    draw.rectangle([13, 13, 15, 15], fill=(30, 20, 10))
    img.save(f"{OUT_DIR}/chest.png")
    print("Generated chest.png")

# 9. Gold Coin (16x16)
def gen_coin():
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Shadow
    draw.ellipse([2, 12, 14, 15], fill=(0, 0, 0, 70))
    # Outer gold rim
    draw.ellipse([2, 2, 14, 14], fill=(210, 150, 20))
    # Inner face
    draw.ellipse([3, 3, 13, 13], fill=(255, 215, 45))
    # Embossed cross/diamond
    draw.polygon([(8, 4), (10, 8), (8, 12), (6, 8)], fill=(225, 165, 20))
    # Shine highlight
    draw.point((5, 5), fill=(255, 255, 230))
    draw.point((6, 5), fill=(255, 255, 230))
    img.save(f"{OUT_DIR}/coin.png")
    print("Generated coin.png")

# 10. Fireball / Meteor (18x18)
def gen_fireball():
    img = Image.new("RGBA", (18, 18), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Outer fire flare
    draw.ellipse([1, 1, 16, 16], fill=(240, 60, 10, 210))
    # Mid-layer molten orange
    draw.ellipse([3, 3, 14, 14], fill=(255, 140, 20, 240))
    # Hot core
    draw.ellipse([5, 5, 12, 12], fill=(255, 235, 120, 255))
    # Corona specks
    draw.point((1, 8), fill=(255, 80, 20))
    draw.point((16, 9), fill=(255, 80, 20))
    draw.point((8, 1), fill=(255, 100, 20))
    draw.point((9, 16), fill=(255, 100, 20))
    img.save(f"{OUT_DIR}/fireball.png")
    print("Generated fireball.png")

# 11. Battleaxe (20x20)
def gen_axe():
    img = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Wooden shaft (diagonal)
    for i in range(16):
        draw.point((2 + i, 17 - i), fill=(120, 75, 30))
        draw.point((3 + i, 17 - i), fill=(95, 55, 20))
    # Double-headed steel blades
    # Left blade
    draw.polygon([(11, 4), (6, 1), (5, 6), (9, 9)], fill=(160, 175, 195))
    draw.line([(6, 1), (5, 6)], fill=(230, 240, 255)) # Sharp edge
    # Right blade
    draw.polygon([(13, 6), (17, 3), (18, 8), (14, 10)], fill=(160, 175, 195))
    draw.line([(17, 3), (18, 8)], fill=(230, 240, 255)) # Sharp edge
    # Central socket
    draw.rectangle([10, 5, 13, 8], fill=(70, 75, 85))
    img.save(f"{OUT_DIR}/axe.png")
    print("Generated axe.png")

# 12. Necromancer (32x32)
def gen_necromancer():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Shadow
    draw.ellipse([6, 26, 26, 31], fill=(0, 0, 0, 90))
    # Robes
    draw.polygon([(16, 6), (7, 28), (25, 28)], fill=(45, 18, 70))
    draw.polygon([(16, 7), (9, 28), (23, 28)], fill=(62, 26, 95))
    # Dark cowl
    draw.rectangle([11, 6, 21, 14], fill=(30, 10, 48))
    # Glowing evil eyes
    draw.point((13, 10), fill=(255, 40, 70))
    draw.point((18, 10), fill=(255, 40, 70))
    # Necromancy staff
    draw.line([(24, 28), (24, 6)], fill=(100, 65, 35), width=2)
    # Skull staff head
    draw.rectangle([22, 4, 27, 8], fill=(220, 215, 200))
    draw.point((23, 5), fill=(0, 0, 0))
    draw.point((25, 5), fill=(0, 0, 0))
    # Floating soul flame
    draw.ellipse([21, 0, 28, 4], fill=(70, 240, 120, 200))
    img.save(f"{OUT_DIR}/necromancer.png")
    print("Generated necromancer.png")

# 13. Shadow Bolt Projectile (14x14)
def gen_shadow_bolt():
    img = Image.new("RGBA", (14, 14), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Void energy ball
    draw.ellipse([1, 1, 12, 12], fill=(80, 15, 120, 210))
    draw.ellipse([3, 3, 10, 10], fill=(160, 40, 230, 240))
    draw.ellipse([5, 5, 8, 8], fill=(230, 170, 255, 255))
    img.save(f"{OUT_DIR}/shadow_bolt.png")
    print("Generated shadow_bolt.png")

# 14. Infernal Behemoth (48x48 Epic Boss)
def gen_behemoth():
    img = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Ground shadow
    draw.ellipse([6, 40, 42, 47], fill=(0, 0, 0, 110))
    # Massive Molten Demon Torso
    draw.rectangle([14, 14, 34, 38], fill=(45, 15, 18))
    draw.rectangle([12, 18, 36, 32], fill=(60, 20, 22))
    # Magma crack lines
    draw.line([(18, 16), (22, 28), (17, 36)], fill=(255, 100, 20), width=2)
    draw.line([(30, 16), (26, 26), (31, 35)], fill=(255, 140, 25), width=2)
    draw.line([(20, 24), (28, 24)], fill=(255, 220, 80), width=2) # Blazing core
    # Demonic Head & Great Horns
    draw.rectangle([17, 8, 31, 18], fill=(50, 15, 20))
    # Left Horn
    draw.polygon([(17, 10), (10, 2), (8, 6), (15, 14)], fill=(220, 60, 15))
    # Right Horn
    draw.polygon([(31, 10), (38, 2), (40, 6), (33, 14)], fill=(220, 60, 15))
    # Fiery Eyes & Maw
    draw.rectangle([19, 12, 22, 14], fill=(255, 240, 100))
    draw.rectangle([26, 12, 29, 14], fill=(255, 240, 100))
    draw.line([(20, 16), (28, 16)], fill=(255, 60, 20), width=1)
    # Spiked Shoulder Pauldrons
    draw.polygon([(8, 18), (14, 14), (14, 26)], fill=(30, 10, 12))
    draw.polygon([(40, 18), (34, 14), (34, 26)], fill=(30, 10, 12))
    img.save(f"{OUT_DIR}/behemoth.png")
    print("Generated behemoth.png")

# 15. Roasted Meat (18x18 Health Pickup)
def gen_meat():
    img = Image.new("RGBA", (18, 18), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Shadow
    draw.ellipse([3, 14, 15, 17], fill=(0, 0, 0, 70))
    # Roast Chicken drumstick
    draw.ellipse([4, 2, 16, 12], fill=(185, 95, 30))
    draw.ellipse([6, 3, 14, 10], fill=(220, 135, 45))
    # Crispy roasted glaze highlight
    draw.point((8, 5), fill=(255, 200, 120))
    draw.point((9, 5), fill=(255, 200, 120))
    # Bone sticking out
    draw.rectangle([1, 10, 5, 13], fill=(235, 235, 225))
    draw.ellipse([0, 9, 3, 14], fill=(235, 235, 225))
    img.save(f"{OUT_DIR}/meat.png")
    print("Generated meat.png")

# 16. Super Magnet (18x18 Vacuum Pickup)
def gen_super_magnet():
    img = Image.new("RGBA", (18, 18), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Shadow
    draw.ellipse([2, 14, 16, 17], fill=(0, 0, 0, 60))
    # U-shape Red Horseshoe
    draw.arc([2, 2, 15, 15], start=0, end=180, fill=(220, 35, 35), width=3)
    draw.line([(2, 8), (2, 4)], fill=(220, 35, 35), width=3)
    draw.line([(15, 8), (15, 4)], fill=(220, 35, 35), width=3)
    # Silver magnetic tips
    draw.rectangle([1, 2, 4, 4], fill=(210, 220, 235))
    draw.rectangle([14, 2, 17, 4], fill=(210, 220, 235))
    # Gold electric spark
    draw.point((9, 7), fill=(255, 235, 80))
    draw.point((8, 8), fill=(255, 235, 80))
    draw.point((10, 8), fill=(255, 235, 80))
    img.save(f"{OUT_DIR}/super_magnet.png")
    print("Generated super_magnet.png")

# 17. Holy Nuke Bomb (18x18 Screen Clear Pickup)
def gen_nuke():
    img = Image.new("RGBA", (18, 18), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Golden Holy Reliquary
    draw.ellipse([2, 2, 15, 15], fill=(220, 160, 20))
    draw.ellipse([3, 3, 14, 14], fill=(255, 215, 40))
    # Radiant Holy Cross
    draw.line([(8, 4), (8, 13)], fill=(255, 255, 240), width=2)
    draw.line([(4, 7), (13, 7)], fill=(255, 255, 240), width=2)
    # Four glowing gems on rim
    draw.point((4, 4), fill=(255, 50, 50))
    draw.point((13, 4), fill=(50, 150, 255))
    draw.point((4, 13), fill=(50, 230, 80))
    draw.point((13, 13), fill=(240, 80, 255))
    img.save(f"{OUT_DIR}/nuke.png")
    print("Generated nuke.png")

# 18. Fountain of Vitality (32x32 Landmark)
def gen_fountain():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Ground shadow
    draw.ellipse([2, 22, 30, 31], fill=(0, 0, 0, 80))
    # Outer stone basin
    draw.ellipse([4, 12, 28, 28], fill=(75, 82, 95))
    draw.ellipse([6, 14, 26, 26], fill=(50, 56, 68))
    # Sacred emerald/cyan water pool
    draw.ellipse([7, 15, 25, 25], fill=(20, 180, 200))
    draw.ellipse([9, 17, 23, 23], fill=(60, 230, 220))
    # Center water spout / pedestal
    draw.rectangle([14, 4, 18, 18], fill=(90, 100, 115))
    draw.ellipse([13, 2, 19, 8], fill=(120, 245, 255))
    # Water ripples & sparkles
    draw.point((11, 18), fill=(255, 255, 255))
    draw.point((21, 20), fill=(255, 255, 255))
    img.save(f"{OUT_DIR}/fountain.png")
    print("Generated fountain.png")

# 19. Altar of Might (32x32 Landmark)
def gen_altar_might():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Ground shadow
    draw.ellipse([4, 24, 28, 31], fill=(0, 0, 0, 85))
    # Stepped obsidian base
    draw.rectangle([5, 22, 27, 28], fill=(45, 30, 38))
    draw.rectangle([8, 16, 24, 22], fill=(60, 35, 48))
    # Inscribed warblade plunged into stone
    draw.rectangle([15, 6, 17, 17], fill=(220, 45, 55)) # Glowing crimson blade
    draw.line([(16, 4), (16, 16)], fill=(255, 200, 200), width=1) # Core shine
    # Crossguard & pommel
    draw.rectangle([12, 6, 20, 8], fill=(240, 180, 40))
    draw.rectangle([15, 2, 17, 6], fill=(110, 60, 25))
    draw.ellipse([14, 0, 18, 3], fill=(240, 180, 40))
    img.save(f"{OUT_DIR}/shrine_might.png")
    print("Generated shrine_might.png")

# 20. Shrine of Swiftness (32x32 Landmark)
def gen_shrine_speed():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Shadow
    draw.ellipse([6, 24, 26, 31], fill=(0, 0, 0, 80))
    # Stone plinth
    draw.rectangle([7, 22, 25, 28], fill=(60, 68, 80))
    # Golden wind/lightning obelisk spire
    draw.polygon([(16, 2), (10, 22), (22, 22)], fill=(210, 165, 30))
    draw.polygon([(16, 4), (12, 22), (20, 22)], fill=(255, 225, 75))
    # Lightning rune
    draw.line([(16, 7), (14, 13), (17, 13), (15, 19)], fill=(255, 255, 255), width=1)
    img.save(f"{OUT_DIR}/shrine_speed.png")
    print("Generated shrine_speed.png")

# 21. Vault of the Ancients (32x32 Landmark)
def gen_shrine_vault():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Shadow
    draw.ellipse([2, 24, 30, 31], fill=(0, 0, 0, 90))
    # Golden Arch Portal
    draw.rectangle([6, 12, 26, 28], fill=(120, 80, 25))
    draw.arc([6, 4, 26, 24], start=180, end=0, fill=(240, 190, 45), width=3)
    draw.line([(6, 14), (6, 28)], fill=(240, 190, 45), width=3)
    draw.line([(26, 14), (26, 28)], fill=(240, 190, 45), width=3)
    # Vault portal swirl
    draw.ellipse([10, 10, 22, 26], fill=(40, 20, 70))
    draw.ellipse([12, 12, 20, 24], fill=(220, 180, 40))
    img.save(f"{OUT_DIR}/shrine_vault.png")
    print("Generated shrine_vault.png")

# 22. Stone Column / Pillar (24x36 Environment Obstacle)
def gen_pillar():
    img = Image.new("RGBA", (24, 36), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Shadow
    draw.ellipse([2, 30, 22, 35], fill=(0, 0, 0, 85))
    # Plinth / Base
    draw.rectangle([4, 28, 20, 33], fill=(65, 70, 80))
    # Column shaft with flutes
    draw.rectangle([6, 6, 18, 28], fill=(85, 92, 105))
    draw.line([(9, 7), (9, 27)], fill=(65, 72, 85), width=1)
    draw.line([(12, 7), (12, 27)], fill=(105, 115, 130), width=1) # Highlight
    draw.line([(15, 7), (15, 27)], fill=(65, 72, 85), width=1)
    # Capital / Head
    draw.rectangle([3, 3, 21, 7], fill=(95, 102, 118))
    img.save(f"{OUT_DIR}/pillar.png")
    print("Generated pillar.png")

# 23. Stone Fire Brazier (20x24)
def gen_brazier():
    img = Image.new("RGBA", (20, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Shadow
    draw.ellipse([3, 20, 17, 23], fill=(0, 0, 0, 70))
    # Tripod Iron stand
    draw.line([(4, 21), (8, 13)], fill=(50, 52, 60), width=2)
    draw.line([(16, 21), (12, 13)], fill=(50, 52, 60), width=2)
    draw.line([(10, 22), (10, 13)], fill=(50, 52, 60), width=2)
    # Iron bowl
    draw.rectangle([5, 11, 15, 14], fill=(70, 72, 82))
    # Flame
    draw.polygon([(6, 12), (10, 2), (14, 12)], fill=(255, 100, 20))
    draw.polygon([(8, 12), (10, 5), (12, 12)], fill=(255, 220, 60))
    img.save(f"{OUT_DIR}/brazier.png")
    print("Generated brazier.png")

# 24. Ancient Sarcophagus / Tomb (28x22)
def gen_tomb():
    img = Image.new("RGBA", (28, 22), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Shadow
    draw.ellipse([2, 16, 26, 21], fill=(0, 0, 0, 80))
    # Stone coffin body
    draw.rectangle([4, 8, 24, 19], fill=(62, 66, 76))
    # Stone lid
    draw.polygon([(3, 9), (7, 4), (21, 4), (25, 9)], fill=(85, 90, 102))
    # Carved cross
    draw.line([(14, 5), (14, 8)], fill=(45, 48, 56), width=1)
    draw.line([(12, 6), (16, 6)], fill=(45, 48, 56), width=1)
    img.save(f"{OUT_DIR}/tomb.png")
    print("Generated tomb.png")

# 25. Hero: Ignis the Pyromancer (32x32)
def gen_hero_pyro():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Shadow
    draw.ellipse([6, 26, 26, 31], fill=(0, 0, 0, 80))
    # Fiery Crimson Robe
    draw.rectangle([9, 14, 23, 25], fill=(180, 40, 25))
    draw.rectangle([11, 15, 21, 25], fill=(220, 60, 30))
    # Robe Trim / Mantle (charred black & gold)
    draw.rectangle([7, 13, 10, 20], fill=(45, 20, 20))
    draw.rectangle([22, 13, 25, 20], fill=(45, 20, 20))
    # Fiery Red/Amber Hood & Hair
    draw.polygon([(11, 13), (16, 3), (21, 13)], fill=(240, 90, 20))
    draw.rectangle([10, 6, 22, 14], fill=(210, 50, 15))
    # Shadow face
    draw.rectangle([12, 8, 20, 14], fill=(25, 12, 12))
    # Glowing Fire Amber Eyes
    draw.point((14, 10), fill=(255, 210, 60))
    draw.point((18, 10), fill=(255, 210, 60))
    # Gold Runic Belt & Amulet
    draw.rectangle([11, 21, 21, 22], fill=(255, 190, 40))
    draw.point((16, 17), fill=(255, 230, 90))
    # Floating Ember Orb in hand
    draw.ellipse([5, 17, 8, 20], fill=(255, 120, 20))
    draw.point((6, 18), fill=(255, 240, 120))
    # Boots
    draw.rectangle([11, 25, 14, 28], fill=(50, 25, 20))
    draw.rectangle([18, 25, 21, 28], fill=(50, 25, 20))
    img.save(f"{OUT_DIR}/hero_pyro.png")
    print("Generated hero_pyro.png")

# 26. Hero: Zephyr the Wind Assassin (32x32)
def gen_hero_ranger():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Shadow
    draw.ellipse([6, 26, 26, 31], fill=(0, 0, 0, 80))
    # Dark Emerald Cowl & Rogue Cloak
    draw.rectangle([9, 14, 23, 24], fill=(20, 75, 45))
    draw.rectangle([11, 15, 21, 24], fill=(30, 110, 65))
    # Stealth Scarf / Cowl
    draw.rectangle([10, 5, 22, 13], fill=(16, 50, 32))
    # Wind Ninja Face Mask
    draw.rectangle([12, 10, 20, 14], fill=(12, 36, 24))
    # Glowing Jade Eyes
    draw.point((14, 9), fill=(70, 255, 150))
    draw.point((18, 9), fill=(70, 255, 150))
    # Crossed Dagger Sheaths on Back
    draw.line([(6, 9), (11, 15)], fill=(190, 210, 220), width=1)
    draw.line([(26, 9), (21, 15)], fill=(190, 210, 220), width=1)
    # Leather Belt & Pouch
    draw.rectangle([10, 21, 22, 22], fill=(90, 60, 35))
    draw.rectangle([13, 22, 15, 24], fill=(130, 90, 50))
    # Swift Leather Boots
    draw.rectangle([11, 25, 14, 28], fill=(25, 30, 25))
    draw.rectangle([18, 25, 21, 28], fill=(25, 30, 25))
    img.save(f"{OUT_DIR}/hero_ranger.png")
    print("Generated hero_ranger.png")

# 27. Hero: Morrigan the Void Mage (32x32)
def gen_hero_mage():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Shadow
    draw.ellipse([6, 26, 26, 31], fill=(0, 0, 0, 80))
    # Void Sorceress Robe (Deep Indigo & Violet)
    draw.rectangle([8, 14, 24, 25], fill=(42, 20, 70))
    draw.rectangle([11, 15, 21, 25], fill=(68, 30, 110))
    # Silver Runed Hem
    draw.line([(8, 25), (24, 25)], fill=(180, 160, 230))
    # Void Tiara / Horned Headdress
    draw.polygon([(9, 7), (12, 3), (15, 7)], fill=(90, 45, 140))
    draw.polygon([(23, 7), (20, 3), (17, 7)], fill=(90, 45, 140))
    draw.rectangle([10, 6, 22, 13], fill=(30, 15, 50))
    # Mystic Face Shadow
    draw.rectangle([12, 8, 20, 13], fill=(18, 8, 30))
    # Glowing Celestial Violet Eyes
    draw.point((14, 9), fill=(220, 120, 255))
    draw.point((18, 9), fill=(220, 120, 255))
    # Floating Arcane Crystal Core on Left
    draw.polygon([(4, 16), (6, 13), (8, 16), (6, 19)], fill=(190, 90, 255))
    draw.point((6, 16), fill=(255, 220, 255))
    # Arcane Amulet
    draw.point((16, 16), fill=(230, 180, 255))
    # Boots
    draw.rectangle([11, 25, 14, 28], fill=(30, 15, 45))
    draw.rectangle([18, 25, 21, 28], fill=(30, 15, 45))
    img.save(f"{OUT_DIR}/hero_mage.png")
    print("Generated hero_mage.png")

# 28. Evolved Daggers: Thousand Blades (24x12)
def gen_thousand_blade():
    img = Image.new("RGBA", (24, 12), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Luminous Golden Astral Blade with Cyan Core
    draw.polygon([(0, 6), (8, 2), (23, 5), (23, 7), (8, 10)], fill=(255, 215, 50))
    draw.polygon([(4, 6), (10, 4), (20, 6), (10, 8)], fill=(120, 240, 255))
    # Sparkle glints
    draw.point((22, 6), fill=(255, 255, 255))
    draw.point((6, 6), fill=(255, 255, 255))
    img.save(f"{OUT_DIR}/thousand_blade.png")
    print("Generated thousand_blade.png")

# 29. Evolved Shield: Solar Bulwark (28x28)
def gen_solar_shield():
    img = Image.new("RGBA", (28, 28), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Radiant Solar Corona rays
    center = (14, 14)
    draw.ellipse([2, 2, 26, 26], outline=(255, 160, 20), width=2)
    draw.ellipse([5, 5, 23, 23], fill=(255, 200, 40))
    draw.ellipse([8, 8, 20, 20], fill=(255, 240, 100))
    # Sun rays
    draw.line([(14, 0), (14, 4)], fill=(255, 220, 50), width=2)
    draw.line([(14, 24), (14, 28)], fill=(255, 220, 50), width=2)
    draw.line([(0, 14), (4, 14)], fill=(255, 220, 50), width=2)
    draw.line([(24, 14), (28, 14)], fill=(255, 220, 50), width=2)
    img.save(f"{OUT_DIR}/solar_shield.png")
    print("Generated solar_shield.png")

# 30. Evolved Fireball: Apocalypse Meteor (36x36)
def gen_apocalypse_meteor():
    img = Image.new("RGBA", (36, 36), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Magma outer glow
    draw.ellipse([2, 2, 34, 34], fill=(240, 50, 20, 180))
    draw.ellipse([5, 5, 31, 31], fill=(255, 110, 20))
    # Molten core
    draw.ellipse([10, 10, 26, 26], fill=(255, 210, 60))
    draw.ellipse([14, 14, 22, 22], fill=(255, 255, 200))
    # Cracked magma rock crust
    draw.polygon([(6, 12), (10, 8), (14, 12), (10, 16)], fill=(70, 25, 20))
    draw.polygon([(22, 10), (28, 14), (25, 20), (20, 16)], fill=(70, 25, 20))
    draw.polygon([(12, 24), (18, 22), (16, 28), (11, 28)], fill=(70, 25, 20))
    img.save(f"{OUT_DIR}/apocalypse_meteor.png")
    print("Generated apocalypse_meteor.png")

# 31. Evolved Axe: Reaper's Cleave (32x32)
def gen_reapers_scythe():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Ebony bone handle
    draw.line([(6, 28), (24, 6)], fill=(70, 65, 75), width=3)
    # Glowing Blood-Red Curved Scythe Blade
    draw.arc([4, 2, 30, 28], start=210, end=350, fill=(230, 30, 40), width=4)
    draw.polygon([(18, 5), (28, 6), (24, 12)], fill=(255, 80, 80))
    # Ethereal soul edge highlight
    draw.arc([5, 3, 29, 27], start=220, end=340, fill=(255, 180, 190), width=1)
    img.save(f"{OUT_DIR}/reapers_scythe.png")
    print("Generated reapers_scythe.png")

# 32. Evolved Thunder: Heaven's Wrath Sigil (28x28)
def gen_heavens_wrath():
    img = Image.new("RGBA", (28, 28), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Plasma lightning burst orb
    draw.ellipse([6, 6, 22, 22], fill=(100, 200, 255, 200))
    draw.ellipse([9, 9, 19, 19], fill=(220, 245, 255))
    # Electric lightning spikes
    draw.line([(14, 1), (14, 7)], fill=(255, 255, 255), width=2)
    draw.line([(14, 21), (14, 27)], fill=(255, 255, 255), width=2)
    draw.line([(1, 14), (7, 14)], fill=(255, 255, 255), width=2)
    draw.line([(21, 14), (27, 14)], fill=(255, 255, 255), width=2)
    draw.line([(4, 4), (9, 9)], fill=(180, 230, 255), width=2)
    draw.line([(24, 24), (19, 19)], fill=(180, 230, 255), width=2)
    draw.line([(4, 24), (9, 19)], fill=(180, 230, 255), width=2)
    draw.line([(24, 4), (19, 9)], fill=(180, 230, 255), width=2)
    img.save(f"{OUT_DIR}/heavens_wrath.png")
    print("Generated heavens_wrath.png")

# 33. Footstep Dust Puff (16x16)
def gen_dust_puff():
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse([3, 4, 13, 14], fill=(210, 200, 185, 160))
    draw.ellipse([5, 6, 11, 12], fill=(240, 235, 225, 200))
    img.save(f"{OUT_DIR}/dust_puff.png")
    print("Generated dust_puff.png")

# 34. Weapon Slash Arc (32x32)
def gen_slash_arc():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.arc([4, 4, 28, 28], start=180, end=290, fill=(255, 240, 180, 230), width=3)
    draw.arc([6, 6, 26, 26], start=190, end=280, fill=(255, 255, 255, 255), width=2)
    img.save(f"{OUT_DIR}/slash_arc.png")
    print("Generated slash_arc.png")

if __name__ == "__main__":
    gen_floor()
    gen_player()
    gen_bat()
    gen_skeleton()
    gen_boss()
    gen_dagger()
    gen_gem()
    gen_chest()
    gen_coin()
    gen_fireball()
    gen_axe()
    gen_necromancer()
    gen_shadow_bolt()
    gen_behemoth()
    gen_meat()
    gen_super_magnet()
    gen_nuke()
    gen_fountain()
    gen_altar_might()
    gen_shrine_speed()
    gen_shrine_vault()
    gen_pillar()
    gen_brazier()
    gen_tomb()
    gen_hero_pyro()
    gen_hero_ranger()
    gen_hero_mage()
    gen_thousand_blade()
    gen_solar_shield()
    gen_apocalypse_meteor()
    gen_reapers_scythe()
    gen_heavens_wrath()
    gen_dust_puff()
    gen_slash_arc()
    print("All sprites generated successfully!")

