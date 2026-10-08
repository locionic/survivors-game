#!/usr/bin/env python3
"""
Generates high-res illustrated 2D game assets for SurvivorQuest using OmniFlash API.
"""

import os
import sys
import time
import json
import urllib.request
from PIL import Image
import rembg

API_URL = "http://100.124.202.25:8080"
OUTPUT_DIR = "/home/runner/survivors-game/assets/textures"
os.makedirs(OUTPUT_DIR, exist_ok=True)

ASSETS_TO_GENERATE = [
    # 1. Heroes
    {
        "filename": "player.png",
        "size": (64, 64),
        "prompt": "pixel art 2D game sprite of a noble heroic knight with blue hood, steel armor, cape and sword, front view, clean isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "hero_knight.png",
        "size": (64, 64),
        "prompt": "pixel art 2D game sprite of a noble armored knight hero in shining plate armor with cape, front view, clean isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "hero_mage.png",
        "size": (64, 64),
        "prompt": "pixel art 2D game sprite of an arcane wizard mage in violet celestial robes with magical crystal staff, front view, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "hero_pyro.png",
        "size": (64, 64),
        "prompt": "pixel art 2D game sprite of a battle pyromancer fire mage with crimson flaming robe and blazing embers, front view, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "hero_sorceress.png",
        "size": (64, 64),
        "prompt": "pixel art 2D game sprite of a celestial sorceress in glowing starlight silk dress, front view, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "hero_ranger.png",
        "size": (64, 64),
        "prompt": "pixel art 2D game sprite of an elven rogue ranger with green leather tunic and wooden recurve bow, front view, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "hero_beggar.png",
        "size": (64, 64),
        "prompt": "pixel art 2D game sprite of a legendary wuxia hermit martial artist with bamboo straw hat, gourd flask and wooden staff, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },

    # 2. Enemies & Bosses
    {
        "filename": "skeleton.png",
        "size": (64, 64),
        "prompt": "pixel art 2D game monster sprite of a spooky dungeon skeleton warrior with ancient rusty scimitar, front view, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "bat.png",
        "size": (48, 48),
        "prompt": "pixel art 2D game monster sprite of a dark purple vampire bat with spread wings, front view, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "necromancer.png",
        "size": (64, 64),
        "prompt": "pixel art 2D game monster sprite of an evil dark hooded necromancer summoning emerald soul flames, front view, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "behemoth.png",
        "size": (96, 96),
        "prompt": "pixel art 2D game monster sprite of a giant hulking horned stone ogre brute with spiked armor, front view, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "boss.png",
        "size": (128, 128),
        "prompt": "pixel art 2D game boss monster sprite of a dread dragon demon emperor with fiery horns, dark armored wings, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "demon_emperor.png",
        "size": (128, 128),
        "prompt": "pixel art 2D game boss monster sprite of a towering demon overlord with obsidian armor and crimson aura, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },

    # 3. Weapons & Projectiles
    {
        "filename": "dagger.png",
        "size": (48, 48),
        "prompt": "pixel art 2D icon of a sharp gleaming silver rogue throwing dagger, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "axe.png",
        "size": (48, 48),
        "prompt": "pixel art 2D icon of a heavy viking double-bladed battle throwing axe, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "fireball.png",
        "size": (48, 48),
        "prompt": "pixel art 2D game sprite of a roaring bright orange and yellow magic fireball projectile, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "shadow_bolt.png",
        "size": (48, 48),
        "prompt": "pixel art 2D game sprite of an ethereal dark purple void magic arcane bolt projectile, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "slash_arc.png",
        "size": (64, 64),
        "prompt": "pixel art 2D game effect of a glowing cyan sword slash wave arc, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "reapers_scythe.png",
        "size": (64, 64),
        "prompt": "pixel art 2D icon of an ornate death reaper scythe with curved obsidian blade and green soul glow, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "solar_shield.png",
        "size": (64, 64),
        "prompt": "pixel art 2D icon of a radiant glowing golden sun shield barrier with solar rays, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "apocalypse_meteor.png",
        "size": (64, 64),
        "prompt": "pixel art 2D game sprite of a burning cosmic meteor meteorite with flame trail, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },

    # 4. Pickups & Drops
    {
        "filename": "gem.png",
        "size": (32, 32),
        "prompt": "pixel art 2D game icon of a brilliant sparkling blue-cyan diamond EXP crystal gem, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "coin.png",
        "size": (32, 32),
        "prompt": "pixel art 2D game icon of a shiny embossed golden coin with star engraving, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "meat.png",
        "size": (32, 32),
        "prompt": "pixel art 2D game icon of a juicy roasted turkey drumstick meat, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "chest.png",
        "size": (48, 48),
        "prompt": "pixel art 2D game icon of an ornate wooden fantasy treasure chest banded with gold, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "super_magnet.png",
        "size": (48, 48),
        "prompt": "pixel art 2D game icon of a red and blue horseshoe magnet attracting sparkling golden sparks, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "nuke.png",
        "size": (48, 48),
        "prompt": "pixel art 2D game icon of a glowing holy gold cross relic emitting blinding radiant light rays, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },

    # 5. Shrines & Dungeon Props
    {
        "filename": "shrine_might.png",
        "size": (64, 80),
        "prompt": "pixel art 2D game prop of an ancient stone monolith rune obelisk with glowing red runes, isolated on plain background",
        "aspect": "portrait",
        "is_bg": False
    },
    {
        "filename": "shrine_speed.png",
        "size": (64, 80),
        "prompt": "pixel art 2D game prop of a wind altar stone monolith with glowing cyan speed runes, isolated on plain background",
        "aspect": "portrait",
        "is_bg": False
    },
    {
        "filename": "shrine_vault.png",
        "size": (64, 80),
        "prompt": "pixel art 2D game prop of an ancient stone treasure altar with glowing golden runes, isolated on plain background",
        "aspect": "portrait",
        "is_bg": False
    },
    {
        "filename": "fountain.png",
        "size": (64, 64),
        "prompt": "pixel art 2D game prop of an ornate stone fountain with clear bubbling healing water, isolated on plain background",
        "aspect": "square",
        "is_bg": False
    },
    {
        "filename": "brazier.png",
        "size": (48, 64),
        "prompt": "pixel art 2D game prop of a stone dungeon fire brazier with bright burning flame, isolated on plain background",
        "aspect": "portrait",
        "is_bg": False
    },
    {
        "filename": "pillar.png",
        "size": (48, 80),
        "prompt": "pixel art 2D game prop of a tall cracked ancient stone dungeon column pillar, isolated on plain background",
        "aspect": "portrait",
        "is_bg": False
    },

    # 6. Floors & Title
    {
        "filename": "dungeon_floor.png",
        "size": (128, 128),
        "prompt": "seamless top-down texture tile of dark fantasy cobblestone dungeon stone floor bricks, top-down game texture",
        "aspect": "square",
        "is_bg": True
    },
    {
        "filename": "snow_floor.png",
        "size": (128, 128),
        "prompt": "seamless top-down texture tile of frosty icy mountain snow ground with faint frozen stone patches, top-down game texture",
        "aspect": "square",
        "is_bg": True
    },
    {
        "filename": "title_bg.png",
        "size": (1280, 720),
        "prompt": "epic 2D fantasy game title screen background of a grand gothic fortress under a stormy twilight sky with floating glowing runes, 16:9 wallpaper",
        "aspect": "landscape",
        "is_bg": True
    }
]

def generate_image(prompt: str, aspect: str = "square") -> str:
    url = f"{API_URL}/generate/image"
    data = json.dumps({"prompt": prompt, "aspect": aspect, "count": 1}).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=120) as response:
            res_data = json.loads(response.read().decode("utf-8"))
            if res_data.get("success") and res_data.get("outputs"):
                out = res_data["outputs"][0]
                fn = out.get("filename")
                dl_url = f"{API_URL}/download/{fn}"
                return dl_url
    except Exception as e:
        print(f"Error generating image: {e}")
    return ""

def download_and_process(url: str, out_path: str, target_size: tuple, is_bg: bool = False):
    temp_path = out_path + ".temp.jpg"
    urllib.request.urlretrieve(url, temp_path)
    
    img = Image.open(temp_path)
    if is_bg:
        # Background textures: resize directly without rembg
        img = img.convert("RGBA")
        img = img.resize(target_size, Image.Resampling.LANCZOS)
        img.save(out_path, "PNG")
    else:
        # Sprites: remove background and crop to bounding box
        rgba = rembg.remove(img)
        bbox = rgba.getbbox()
        if bbox:
            cropped = rgba.crop(bbox)
            # Create square canvas maintaining aspect ratio
            max_side = max(cropped.width, cropped.height)
            square_img = Image.new("RGBA", (max_side, max_side), (0, 0, 0, 0))
            offset_x = (max_side - cropped.width) // 2
            offset_y = (max_side - cropped.height) // 2
            square_img.paste(cropped, (offset_x, offset_y), cropped)
            final_img = square_img.resize(target_size, Image.Resampling.LANCZOS)
            final_img.save(out_path, "PNG")
        else:
            rgba = rgba.resize(target_size, Image.Resampling.LANCZOS)
            rgba.save(out_path, "PNG")

    if os.path.exists(temp_path):
        os.remove(temp_path)
    print(f" Saved: {out_path} ({target_size[0]}x{target_size[1]})")

def main():
    print(f"Generating {len(ASSETS_TO_GENERATE)} assets for SurvivorQuest...")
    for idx, item in enumerate(ASSETS_TO_GENERATE):
        filename = item["filename"]
        out_path = os.path.join(OUTPUT_DIR, filename)
        print(f"[{idx+1}/{len(ASSETS_TO_GENERATE)}] Generating {filename}...")
        
        dl_url = generate_image(item["prompt"], item["aspect"])
        if dl_url:
            download_and_process(dl_url, out_path, item["size"], item["is_bg"])
        else:
            print(f"Failed to generate {filename}")
        time.sleep(1.0)
    print("\nAll assets generated successfully!")

if __name__ == "__main__":
    main()
