#!/usr/bin/env python3
"""
Expansion 14.0 Asset Generator:
Generates pixel art sprite for the 5th Hero:
Cái Bang Đệ Tử (Tiêu Lãng - Beggar Sect Disciple with Bamboo Staff & Wine Gourd).
"""

from PIL import Image, ImageDraw
import os

OUT_DIR = "/home/renovibe79/survivors-game/assets/textures"
os.makedirs(OUT_DIR, exist_ok=True)

def gen_hero_beggar():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Shadow
    draw.ellipse([6, 26, 26, 31], fill=(0, 0, 0, 80))
    
    # Patched Wuxia Robes (Linen brown, dark grey patches)
    draw.rectangle([9, 14, 23, 24], fill=(130, 95, 60))
    draw.rectangle([11, 15, 21, 24], fill=(155, 115, 75))
    # Robe patches (Cái Bang 9-patch identity)
    draw.rectangle([10, 16, 13, 19], fill=(85, 65, 45))
    draw.rectangle([18, 20, 21, 23], fill=(50, 80, 60)) # jade patch
    
    # Red martial sash / belt
    draw.rectangle([10, 21, 22, 22], fill=(180, 45, 35))
    
    # Wine Gourd (Hồ Lô Rượu) strapped at left hip
    draw.ellipse([6, 19, 10, 23], fill=(195, 145, 65))
    draw.ellipse([7, 17, 9, 20], fill=(175, 125, 50))
    draw.rectangle([7, 16, 9, 17], fill=(140, 30, 30)) # red cork
    
    # Head & Wild Hair
    draw.rectangle([11, 6, 21, 14], fill=(225, 185, 140)) # face
    draw.rectangle([9, 4, 23, 8], fill=(40, 35, 32)) # hair
    draw.rectangle([8, 8, 10, 13], fill=(40, 35, 32)) # side hair
    draw.rectangle([22, 8, 24, 13], fill=(40, 35, 32))
    
    # Wuxia Headband (Crimson cloth tie)
    draw.rectangle([9, 7, 23, 8], fill=(200, 40, 40))
    draw.line([(8, 8), (6, 12)], fill=(180, 35, 35), width=1) # fluttering ribbon
    
    # Eyes & confident grin
    draw.point((13, 10), fill=(20, 15, 15))
    draw.point((19, 10), fill=(20, 15, 15))
    draw.line([(14, 13), (18, 13)], fill=(140, 60, 50))
    
    # Bamboo Dog-Beating Staff (Đả Cẩu Bổng) held in right hand
    # Vibrant imperial emerald bamboo
    draw.line([(25, 3), (25, 27)], fill=(40, 180, 85), width=2)
    # Bamboo joints
    draw.point((24, 9), fill=(180, 240, 140))
    draw.point((25, 9), fill=(180, 240, 140))
    draw.point((24, 17), fill=(180, 240, 140))
    draw.point((25, 17), fill=(180, 240, 140))
    draw.point((24, 23), fill=(180, 240, 140))
    draw.point((25, 23), fill=(180, 240, 140))
    
    # Right hand holding staff
    draw.rectangle([23, 15, 25, 18], fill=(225, 185, 140))
    
    # Straw martial sandals / legs
    draw.rectangle([11, 25, 14, 28], fill=(110, 80, 50))
    draw.rectangle([18, 25, 21, 28], fill=(110, 80, 50))
    draw.line([(11, 28), (14, 28)], fill=(75, 55, 35))
    draw.line([(18, 28), (21, 28)], fill=(75, 55, 35))
    
    img.save(f"{OUT_DIR}/hero_beggar.png")
    print("Generated hero_beggar.png successfully!")

AUDIO_DIR = "/home/renovibe79/survivors-game/assets/audio"
os.makedirs(AUDIO_DIR, exist_ok=True)
import wave, math, struct, random

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
    print(f"Generated: {filename} ({len(samples)} samples)")

# Wine Drink Gulp & Chi Burst (0.35s)
def gen_wine_drink():
    duration = 0.35
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    for i in range(num_samples):
        progress = i / num_samples
        # Gulp sound (liquid pop) followed by rising Chi resonance
        if progress < 0.4:
            # Gulp resonance: downward liquid bubble
            p_sub = progress / 0.4
            freq = 320.0 * (1.0 - 0.4 * p_sub)
            phase += 2.0 * math.pi * freq / SAMPLE_RATE
            val = math.sin(phase) * (1.0 - p_sub * 0.3)
        else:
            # Chi surge: rising harmonics
            p_sub = (progress - 0.4) / 0.6
            freq = 280.0 + 340.0 * p_sub
            phase += 2.0 * math.pi * freq / SAMPLE_RATE
            val = (0.7 * math.sin(phase) + 0.3 * math.sin(phase * 2.0)) * (1.0 - p_sub)
        samples.append(val * 0.45)
    write_wav(f"{AUDIO_DIR}/wine_drink.wav", samples)

# Tournament Fanfare Gong (0.75s)
def gen_tournament_fanfare():
    duration = 0.75
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase1 = 0.0
    phase2 = 0.0
    phase3 = 0.0
    for i in range(num_samples):
        progress = i / num_samples
        # Resonant eastern bronze chime / fanfare: Pentatonic root & fifth
        freq1 = 523.25 # C5
        freq2 = 659.25 # E5
        freq3 = 783.99 # G5
        phase1 += 2.0 * math.pi * freq1 / SAMPLE_RATE
        phase2 += 2.0 * math.pi * freq2 / SAMPLE_RATE
        phase3 += 2.0 * math.pi * freq3 / SAMPLE_RATE
        
        env = (1.0 - progress) ** 1.8
        strike = math.exp(-25.0 * progress) * 0.5
        val = (0.5 * math.sin(phase1) + 0.3 * math.sin(phase2) + 0.2 * math.sin(phase3) + strike) * env
        samples.append(val * 0.5)
    write_wav(f"{AUDIO_DIR}/fanfare.wav", samples)

if __name__ == "__main__":
    gen_hero_beggar()
    gen_wine_drink()
    gen_tournament_fanfare()
