#!/usr/bin/env python3
"""
Procedural pixel art generator for Project Z-Survivor (Zombie World theme).
Outputs textures to assets/textures/ and sound effects to assets/audio/.
"""

import os
import math
import struct
import wave
import random
from PIL import Image, ImageDraw

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
TEXTURES_DIR = os.path.join(BASE_DIR, "assets", "textures")
AUDIO_DIR = os.path.join(BASE_DIR, "assets", "audio")

os.makedirs(TEXTURES_DIR, exist_ok=True)
os.makedirs(AUDIO_DIR, exist_ok=True)

# 1. Asphalt Urban Road Floor (64x64 Seamless Tile)
def gen_asphalt_floor():
    img = Image.new("RGBA", (64, 64), (28, 30, 34, 255))
    draw = ImageDraw.Draw(img)

    rng = random.Random(42)
    for x in range(64):
        for y in range(64):
            v = rng.randint(-6, 6)
            c = max(18, min(42, 30 + v))
            img.putpixel((x, y), (c, c + 2, c + 4, 255))

    crack_color = (14, 15, 18, 255)
    cracks = [
        [(8, 12), (14, 18), (22, 19), (28, 25)],
        [(44, 40), (50, 42), (54, 48), (60, 52)],
        [(36, 6), (40, 14), (45, 16)],
        [(4, 48), (10, 52), (16, 56)]
    ]
    for crack in cracks:
        for i in range(len(crack) - 1):
            draw.line([crack[i], crack[i+1]], fill=crack_color, width=1)

    yellow = (215, 175, 45, 230)
    yellow_dark = (160, 130, 30, 200)
    for dash_y in [(8, 24), (40, 56)]:
        y_start, y_end = dash_y
        for y in range(y_start, y_end):
            for x in range(30, 34):
                if rng.random() > 0.15:
                    col = yellow if (x == 31 or x == 32) else yellow_dark
                    img.putpixel((x, y), col)

    out_path = os.path.join(TEXTURES_DIR, "asphalt_floor.png")
    img.save(out_path)
    print(f"Generated: {out_path}")

# 2. SWAT / Tactical Survivor Hero (32x32)
def gen_hero_survivor():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    draw.ellipse([6, 26, 26, 31], fill=(0, 0, 0, 90))
    draw.rectangle([10, 22, 14, 27], fill=(25, 28, 35))
    draw.rectangle([18, 22, 22, 27], fill=(25, 28, 35))
    draw.rectangle([9, 27, 14, 30], fill=(15, 16, 20))
    draw.rectangle([18, 27, 23, 30], fill=(15, 16, 20))

    draw.rectangle([9, 13, 23, 22], fill=(38, 48, 56))
    draw.rectangle([11, 14, 21, 21], fill=(46, 58, 68))
    draw.rectangle([12, 16, 20, 17], fill=(22, 25, 30))
    draw.rectangle([13, 19, 15, 21], fill=(80, 75, 55))
    draw.rectangle([17, 19, 19, 21], fill=(80, 75, 55))

    draw.rectangle([10, 4, 22, 12], fill=(30, 36, 42))
    draw.rectangle([9, 7, 23, 11], fill=(24, 28, 34))
    draw.rectangle([12, 8, 20, 10], fill=(40, 180, 240, 240))
    draw.line([(13, 8), (15, 8)], fill=(160, 230, 255, 255))
    draw.rectangle([12, 11, 20, 13], fill=(210, 165, 140))

    draw.rectangle([6, 14, 9, 21], fill=(38, 48, 56))
    draw.rectangle([23, 14, 26, 21], fill=(38, 48, 56))
    draw.rectangle([22, 17, 30, 20], fill=(20, 22, 25))
    draw.rectangle([24, 20, 26, 23], fill=(15, 15, 18))
    draw.line([(29, 17), (29, 19)], fill=(80, 85, 95))

    out_path = os.path.join(TEXTURES_DIR, "hero_survivor.png")
    img.save(out_path)
    print(f"Generated: {out_path}")

# 3. Zombie Walker (32x32)
def gen_zombie_walker():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    draw.ellipse([6, 26, 26, 31], fill=(0, 0, 0, 90))
    draw.rectangle([11, 22, 15, 28], fill=(42, 48, 58))
    draw.rectangle([17, 22, 21, 27], fill=(38, 42, 50))
    draw.rectangle([10, 28, 14, 30], fill=(75, 95, 78))
    draw.rectangle([17, 27, 21, 29], fill=(68, 88, 72))

    draw.rectangle([9, 13, 23, 22], fill=(85, 75, 65))
    draw.rectangle([14, 15, 17, 19], fill=(55, 75, 58))
    draw.rectangle([12, 20, 20, 22], fill=(60, 52, 45))

    draw.rectangle([5, 14, 9, 18], fill=(75, 95, 78))
    draw.rectangle([2, 15, 5, 17], fill=(85, 110, 88))
    draw.rectangle([23, 14, 27, 18], fill=(75, 95, 78))
    draw.rectangle([27, 15, 30, 17], fill=(85, 110, 88))

    draw.rectangle([10, 4, 22, 13], fill=(80, 105, 82))
    draw.rectangle([10, 3, 22, 6], fill=(45, 40, 35))
    draw.point((9, 6), fill=(45, 40, 35))
    draw.point((22, 6), fill=(45, 40, 35))

    draw.rectangle([12, 7, 14, 9], fill=(245, 230, 90))
    draw.point((13, 8), fill=(255, 255, 220))
    draw.rectangle([17, 7, 19, 9], fill=(20, 25, 20))

    draw.rectangle([13, 11, 19, 13], fill=(30, 15, 15))
    draw.point((14, 11), fill=(220, 215, 195))
    draw.point((17, 11), fill=(220, 215, 195))
    draw.line([(15, 13), (15, 15)], fill=(150, 20, 20))

    out_path = os.path.join(TEXTURES_DIR, "zombie_walker.png")
    img.save(out_path)
    print(f"Generated: {out_path}")

# 4. Zombie Runner (32x32)
def gen_zombie_runner():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    draw.ellipse([5, 25, 27, 30], fill=(0, 0, 0, 100))
    draw.rectangle([8, 20, 13, 28], fill=(90, 30, 30))
    draw.rectangle([17, 18, 24, 25], fill=(70, 20, 20))
    draw.rectangle([21, 24, 26, 29], fill=(130, 50, 50))

    draw.rectangle([10, 11, 22, 20], fill=(140, 45, 45))
    draw.line([(11, 13), (19, 18)], fill=(180, 60, 60), width=2)

    draw.rectangle([4, 13, 9, 16], fill=(150, 50, 50))
    draw.rectangle([1, 13, 4, 15], fill=(220, 190, 180))
    draw.rectangle([22, 10, 28, 14], fill=(150, 50, 50))
    draw.rectangle([28, 9, 31, 12], fill=(220, 190, 180))

    draw.rectangle([12, 4, 21, 11], fill=(155, 55, 55))
    draw.rectangle([14, 6, 16, 7], fill=(255, 240, 100))
    draw.rectangle([18, 6, 20, 7], fill=(255, 60, 60))
    draw.rectangle([14, 9, 19, 11], fill=(40, 10, 10))

    out_path = os.path.join(TEXTURES_DIR, "zombie_runner.png")
    img.save(out_path)
    print(f"Generated: {out_path}")

# 5. Zombie Bloater (36x36)
def gen_zombie_bloater():
    img = Image.new("RGBA", (36, 36), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    draw.ellipse([4, 29, 32, 35], fill=(0, 0, 0, 110))
    draw.rectangle([10, 27, 16, 32], fill=(45, 60, 45))
    draw.rectangle([20, 27, 26, 32], fill=(45, 60, 45))

    draw.ellipse([6, 11, 30, 28], fill=(65, 95, 60))
    draw.ellipse([8, 13, 28, 27], fill=(80, 120, 75))
    draw.ellipse([10, 15, 14, 19], fill=(160, 240, 50))
    draw.point((12, 17), fill=(220, 255, 140))
    draw.ellipse([21, 18, 26, 23], fill=(175, 235, 45))
    draw.ellipse([14, 22, 19, 26], fill=(140, 210, 40))

    draw.rectangle([14, 5, 22, 12], fill=(70, 90, 65))
    draw.rectangle([15, 7, 17, 8], fill=(255, 240, 80))
    draw.rectangle([19, 7, 21, 8], fill=(180, 230, 60))
    draw.rectangle([16, 9, 20, 11], fill=(30, 45, 30))
    draw.line([(18, 11), (18, 14)], fill=(140, 230, 60), width=1)

    out_path = os.path.join(TEXTURES_DIR, "zombie_bloater.png")
    img.save(out_path)
    print(f"Generated: {out_path}")

# 6. Bullet (16x16)
def gen_bullet():
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse([2, 5, 14, 11], fill=(255, 170, 30, 100))
    draw.rectangle([4, 6, 12, 10], fill=(255, 220, 80, 220))
    draw.rectangle([6, 7, 11, 9], fill=(255, 255, 255, 255))
    out_path = os.path.join(TEXTURES_DIR, "bullet.png")
    img.save(out_path)
    print(f"Generated: {out_path}")

# 7. Bio-Vial (16x16)
def gen_bio_vial():
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([5, 4, 11, 13], fill=(60, 120, 110, 120))
    draw.rectangle([6, 7, 10, 12], fill=(40, 255, 120, 230))
    draw.line([(7, 8), (7, 11)], fill=(180, 255, 210, 240))
    draw.rectangle([5, 2, 11, 4], fill=(180, 190, 200, 255))
    draw.rectangle([6, 1, 10, 2], fill=(130, 140, 150, 255))
    out_path = os.path.join(TEXTURES_DIR, "bio_vial.png")
    img.save(out_path)
    print(f"Generated: {out_path}")

# 8. Gunshot & Zombie SFX
SAMPLE_RATE = 44100

def write_wav_file(filename, samples):
    full_path = os.path.join(AUDIO_DIR, filename)
    with wave.open(full_path, 'w') as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        packed = bytearray()
        for s in samples:
            clamped = max(-1.0, min(1.0, s))
            val = int(clamped * 32767.0)
            packed.extend(struct.pack('<h', val))
        wav.writeframes(packed)
    print(f"Generated Audio: {full_path}")

def gen_gunshot_sfx():
    duration = 0.22
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    rng = random.Random(101)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        progress = i / num_samples
        env = math.exp(-18.0 * progress)
        noise = (rng.random() * 2.0 - 1.0) * env
        pitch = 180.0 * (1.0 - progress * 0.8)
        thud = math.sin(2.0 * math.pi * pitch * t) * math.exp(-12.0 * progress) * 0.8
        sample = noise * 0.7 + thud * 0.6
        samples.append(sample)
    write_wav_file("gunshot.wav", samples)

def gen_shotgun_sfx():
    duration = 0.38
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    rng = random.Random(202)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        progress = i / num_samples
        env = math.exp(-9.0 * progress)
        noise = (rng.random() * 2.0 - 1.0) * env * 0.85
        pitch = 120.0 * math.exp(-4.0 * progress)
        sub = math.sin(2.0 * math.pi * pitch * t) * math.exp(-7.0 * progress) * 1.1
        sample = (noise * 0.6 + sub * 0.7)
        samples.append(sample)
    write_wav_file("shotgun.wav", samples)

def gen_zombie_groan_sfx():
    duration = 0.65
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    rng = random.Random(303)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        progress = i / num_samples
        env = math.sin(progress * math.pi) * 0.8
        tremolo = math.sin(2.0 * math.pi * 7.0 * t) * 15.0
        pitch = 95.0 + tremolo + (progress * 15.0)
        vocal = math.sin(2.0 * math.pi * pitch * t)
        vocal += 0.5 * math.sin(4.0 * math.pi * pitch * t)
        vocal += 0.25 * math.sin(6.0 * math.pi * pitch * t)
        noise = (rng.random() * 2.0 - 1.0) * 0.15
        sample = (vocal * 0.75 + noise) * env
        samples.append(sample)
    write_wav_file("zombie_groan.wav", samples)

def gen_zombie_hit_sfx():
    duration = 0.15
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    rng = random.Random(404)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        progress = i / num_samples
        env = math.exp(-22.0 * progress)
        pitch = 240.0 * math.exp(-15.0 * progress)
        squelch = math.sin(2.0 * math.pi * pitch * t)
        noise = (rng.random() * 2.0 - 1.0) * env * 0.5
        sample = (squelch * 0.6 + noise * 0.5) * env
        samples.append(sample)
    write_wav_file("zombie_hit.wav", samples)

if __name__ == "__main__":
    print("=== Generating Project Z-Survivor In-Game Assets ===")
    gen_asphalt_floor()
    gen_hero_survivor()
    gen_zombie_walker()
    gen_zombie_runner()
    gen_zombie_bloater()
    gen_bullet()
    gen_bio_vial()
    gen_gunshot_sfx()
    gen_shotgun_sfx()
    gen_zombie_groan_sfx()
    gen_zombie_hit_sfx()
    print("=== Assets successfully created! ===")
