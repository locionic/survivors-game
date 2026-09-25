#!/usr/bin/env python3
"""
Asset generator for Expansion 12.0:
Võ Học Bí Tịch & Thất Long Châu (Martial Arts Scrolls & Seven Dragon Pearls).
Synthesizes WAV audio & renders 32x32 pixel-art textures.
"""

import math
import os
import random
import struct
import wave
from PIL import Image, ImageDraw

AUDIO_DIR = "/home/renovibe79/survivors-game/assets/audio"
TEXTURE_DIR = "/home/renovibe79/survivors-game/assets/textures"
os.makedirs(AUDIO_DIR, exist_ok=True)
os.makedirs(TEXTURE_DIR, exist_ok=True)

SAMPLE_RATE = 44100

def write_wav(filename, samples):
    with wave.open(filename, 'w') as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        packed = bytearray()
        for s in samples:
            clamped = max(-1.0, min(1.0, s))
            val = int(clamped * 32767.0)
            packed.extend(struct.pack('<h', val))
        wav.writeframes(packed)
    print(f"Generated Audio: {filename}")

# 1. Dragon Wish (Celestial chime + majestic fanfare, 1.2s)
def gen_dragon_wish():
    duration = 1.2
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    # Pentatonic fanfare: C5, E5, G5, A5, C6, E6
    notes = [523.25, 659.25, 783.99, 880.0, 1046.50, 1318.51]
    phases = [0.0] * len(notes)
    for i in range(num_samples):
        progress = i / num_samples
        val = 0.0
        for idx, freq in enumerate(notes):
            start_offset = idx * 0.12
            if progress >= start_offset:
                note_prog = (progress - start_offset) / (1.0 - start_offset)
                phases[idx] += 2.0 * math.pi * freq / SAMPLE_RATE
                v = math.sin(phases[idx]) + 0.3 * math.sin(phases[idx] * 2.0)
                env = min(1.0, note_prog * 15.0) * (1.0 - note_prog) ** 1.4
                val += v * env * 0.22
        # Add deep bass drone
        drone_phase = 2.0 * math.pi * 130.81 * (i / SAMPLE_RATE)
        val += math.sin(drone_phase) * (1.0 - progress) ** 1.2 * 0.25
        samples.append(val)
    return samples

# 2. Qi Laser (Swift piercing laser beam, 0.20s)
def gen_qi_laser():
    duration = 0.20
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    for i in range(num_samples):
        progress = i / num_samples
        # Rapid downward frequency sweep from 2400Hz to 380Hz
        freq = 2400.0 * math.exp(-3.2 * progress)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        val = math.sin(phase) + 0.35 * math.sin(phase * 3.0)
        env = (1.0 - progress) ** 1.8
        samples.append(val * env * 0.45)
    return samples

# 3. Buddha Gong (Deep resonant bronze bell with long decay, 1.4s)
def gen_buddha_gong():
    duration = 1.4
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    harmonics = [174.61, 349.23, 523.25, 698.46, 880.0]
    weights = [0.45, 0.25, 0.18, 0.10, 0.06]
    phases = [0.0] * len(harmonics)
    for i in range(num_samples):
        progress = i / num_samples
        val = 0.0
        for idx, freq in enumerate(harmonics):
            phases[idx] += 2.0 * math.pi * freq / SAMPLE_RATE
            v = math.sin(phases[idx])
            env = min(1.0, progress * 40.0) * (1.0 - progress) ** (1.2 + idx * 0.4)
            val += v * weights[idx] * env
        # Slight metallic ring noise on strike
        if progress < 0.05:
            val += (random.random() * 2.0 - 1.0) * (1.0 - progress / 0.05) * 0.15
        samples.append(val * 0.7)
    return samples

# --- SPRITE GENERATION ---

# 1. Dragon Pearl (24x24): Glowing amber crystal orb with inner ruby star
def gen_dragon_pearl():
    img = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Outer golden aura glow
    draw.ellipse([2, 2, 21, 21], fill=(255, 180, 20, 60))
    draw.ellipse([3, 3, 20, 20], fill=(255, 140, 0, 200))
    # Inner orb body
    draw.ellipse([4, 4, 19, 19], fill=(255, 195, 30, 255))
    draw.ellipse([5, 5, 18, 18], fill=(255, 220, 70, 255))
    # Inner ruby red star (representing 7-star dragon pearl)
    draw.polygon([(11, 7), (13, 7), (12, 10)], fill=(220, 30, 30, 255))
    draw.polygon([(11, 16), (13, 16), (12, 13)], fill=(220, 30, 30, 255))
    draw.polygon([(7, 11), (7, 13), (10, 12)], fill=(220, 30, 30, 255))
    draw.polygon([(16, 11), (16, 13), (13, 12)], fill=(220, 30, 30, 255))
    draw.rectangle([11, 11, 13, 13], fill=(240, 40, 40, 255))
    # Specular glass reflection
    draw.ellipse([6, 6, 10, 10], fill=(255, 255, 255, 220))
    draw.point((7, 7), fill=(255, 255, 255, 255))
    img.save(f"{TEXTURE_DIR}/dragon_pearl.png")
    print("Generated: dragon_pearl.png")

# 2. Scroll Gold: Dịch Cân Kinh (24x24)
def gen_scroll_gold():
    img = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Outer aura
    draw.ellipse([1, 1, 22, 22], fill=(255, 215, 0, 50))
    # Golden wooden scroll rods
    draw.rectangle([3, 4, 6, 19], fill=(180, 120, 30, 255))
    draw.rectangle([17, 4, 20, 19], fill=(180, 120, 30, 255))
    draw.rectangle([2, 3, 7, 5], fill=(220, 170, 50, 255))
    draw.rectangle([2, 18, 7, 20], fill=(220, 170, 50, 255))
    draw.rectangle([16, 3, 21, 5], fill=(220, 170, 50, 255))
    draw.rectangle([16, 18, 21, 20], fill=(220, 170, 50, 255))
    # Parchment body
    draw.rectangle([6, 5, 17, 18], fill=(250, 240, 200, 255))
    # Chinese calligraphy character (Golden Lion / Gong 卍)
    draw.line([(9, 8), (14, 8)], fill=(160, 40, 20, 255), width=1)
    draw.line([(11, 8), (11, 15)], fill=(160, 40, 20, 255), width=1)
    draw.line([(9, 12), (14, 12)], fill=(160, 40, 20, 255), width=1)
    draw.line([(9, 15), (14, 15)], fill=(160, 40, 20, 255), width=1)
    # Red ribbon seal
    draw.rectangle([10, 16, 13, 19], fill=(210, 30, 30, 255))
    img.save(f"{TEXTURE_DIR}/scroll_gold.png")
    print("Generated: scroll_gold.png")

# 3. Scroll Sword: Lục Mạch Thần Kiếm (24x24)
def gen_scroll_sword():
    img = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Cyan aura
    draw.ellipse([1, 1, 22, 22], fill=(0, 200, 255, 60))
    # Dark steel rods
    draw.rectangle([3, 4, 6, 19], fill=(40, 70, 110, 255))
    draw.rectangle([17, 4, 20, 19], fill=(40, 70, 110, 255))
    # Azure parchment body
    draw.rectangle([6, 5, 17, 18], fill=(210, 240, 255, 255))
    # Glowing spirit sword emblem
    draw.line([(11, 7), (11, 15)], fill=(0, 150, 240, 255), width=2)
    draw.line([(9, 13), (14, 13)], fill=(0, 100, 180, 255), width=1)
    draw.point((11, 6), fill=(255, 255, 255, 255))
    # Blue ribbon seal
    draw.rectangle([10, 16, 13, 19], fill=(0, 120, 220, 255))
    img.save(f"{TEXTURE_DIR}/scroll_sword.png")
    print("Generated: scroll_sword.png")

# 4. Scroll Tai Chi: Thái Cực Đồ (24x24)
def gen_scroll_taichi():
    img = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Mystic purple-white aura
    draw.ellipse([1, 1, 22, 22], fill=(200, 160, 255, 50))
    # Wooden rods
    draw.rectangle([3, 4, 6, 19], fill=(90, 60, 40, 255))
    draw.rectangle([17, 4, 20, 19], fill=(90, 60, 40, 255))
    # Silk parchment body
    draw.rectangle([6, 5, 17, 18], fill=(245, 242, 235, 255))
    # Yin-Yang circle
    draw.ellipse([8, 8, 15, 15], fill=(20, 20, 25, 255))
    draw.chord([8, 8, 15, 15], 90, 270, fill=(245, 245, 250, 255))
    draw.ellipse([10, 8, 13, 11], fill=(20, 20, 25, 255))
    draw.ellipse([10, 12, 13, 15], fill=(245, 245, 250, 255))
    draw.point((11, 9), fill=(255, 255, 255, 255))
    draw.point((11, 14), fill=(0, 0, 0, 255))
    img.save(f"{TEXTURE_DIR}/scroll_taichi.png")
    print("Generated: scroll_taichi.png")

# 5. Sword Spirit: Vạn Kiếm & Lục Mạch Projectile (16x32)
def gen_sword_spirit():
    img = Image.new("RGBA", (16, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Translucent cyan outer glow
    draw.polygon([(7, 2), (11, 8), (11, 23), (7, 27), (4, 23), (4, 8)], fill=(0, 220, 255, 75))
    # Blade core
    draw.polygon([(7, 4), (10, 9), (9, 22), (7, 24), (6, 22), (5, 9)], fill=(120, 240, 255, 230))
    # Center white energy beam
    draw.line([(7, 5), (7, 23)], fill=(255, 255, 255, 255), width=1)
    # Crossguard
    draw.rectangle([(3, 24), (12, 26)], fill=(255, 215, 0, 240))
    # Hilt & Pommel
    draw.line([(7, 27), (7, 30)], fill=(180, 140, 30, 255), width=2)
    draw.ellipse([(6, 30), (9, 32)], fill=(255, 215, 0, 255))
    img.save(f"{TEXTURE_DIR}/sword_spirit.png")
    print("Generated: sword_spirit.png")

if __name__ == "__main__":
    write_wav(f"{AUDIO_DIR}/dragon_wish.wav", gen_dragon_wish())
    write_wav(f"{AUDIO_DIR}/qi_laser.wav", gen_qi_laser())
    write_wav(f"{AUDIO_DIR}/buddha_gong.wav", gen_buddha_gong())
    gen_dragon_pearl()
    gen_scroll_gold()
    gen_scroll_sword()
    gen_scroll_taichi()
    gen_sword_spirit()
    print("=== All Expansion 12.0 assets generated successfully! ===")
