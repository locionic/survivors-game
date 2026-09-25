#!/usr/bin/env python3
"""
Generates authentic Eastern Martial Arts (Wuxia / Tiên Hiệp) orchestral soundtracks
using physical modeling (Karplus-Strong Guzheng) and acoustic synthesis (Bamboo Flute, Taiko Drums, Temple Bell).
Produces studio-grade 16-bit 44.1kHz Stereo WAV audio.
"""

import wave
import math
import struct
import random
import os

SAMPLE_RATE = 44100
OUT_DIR = "/home/renovibe79/survivors-game/assets/audio"
os.makedirs(OUT_DIR, exist_ok=True)

def midi_to_freq(m):
    return 440.0 * (2.0 ** ((m - 69.0) / 12.0))

# 1. Guzheng Plucked String (Karplus-Strong with damping & stereo spread)
def karplus_strong(freq, dur_sec, damp=0.991):
    L = max(2, int(SAMPLE_RATE / freq))
    buf = [random.uniform(-1.0, 1.0) for _ in range(L)]
    out = []
    n_samples = int(dur_sec * SAMPLE_RATE)
    for _ in range(n_samples):
        v = buf.pop(0)
        new_v = 0.5 * (v + buf[0]) * damp
        buf.append(new_v)
        out.append(v)
    return out

# 2. Dizi Bamboo Flute (Breathy harmonic resonator with vibrato)
def bamboo_flute(freq, dur_sec, amp=0.32):
    n_samples = int(dur_sec * SAMPLE_RATE)
    out = []
    phase = 0.0
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        if t < 0.07:
            env = t / 0.07
        elif t > dur_sec - 0.10:
            env = max(0.0, (dur_sec - t) / 0.10)
        else:
            env = 1.0
        # Gentle vibrato at 5.5Hz
        vib = math.sin(2.0 * math.pi * 5.5 * t) * (freq * 0.015)
        phase += 2.0 * math.pi * (freq + vib) / SAMPLE_RATE
        tone = (math.sin(phase) 
                + 0.35 * math.sin(2.0 * phase) 
                + 0.18 * math.sin(3.0 * phase)
                + 0.08 * math.sin(4.0 * phase))
        breath = (random.random() - 0.5) * 0.06
        out.append((tone + breath) * env * amp)
    return out

# 3. Taiko War Drum (Deep resonant impact)
def taiko_drum(amp=0.70, pitch_start=140.0, pitch_end=46.0):
    dur = 0.48
    n_samples = int(dur * SAMPLE_RATE)
    out = []
    phase = 0.0
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        p = t / dur
        f = pitch_end + (pitch_start - pitch_end) * math.exp(-22.0 * t)
        phase += 2.0 * math.pi * f / SAMPLE_RATE
        tone = math.sin(phase) + 0.25 * math.sin(2.0 * phase)
        noise = (random.random() - 0.5) * math.exp(-45.0 * t) * 0.6
        env = (1.0 - p) ** 2.2
        out.append((tone + noise) * env * amp)
    return out

# 4. Temple Bell / Gong (Inharmonic metallic resonance)
def temple_bell(freq=330.0, dur=3.0, amp=0.35):
    n_samples = int(dur * SAMPLE_RATE)
    out = []
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-1.8 * t)
        v = (math.sin(2.0 * math.pi * freq * t) 
             + 0.45 * math.sin(2.0 * math.pi * freq * 1.414 * t) 
             + 0.25 * math.sin(2.0 * math.pi * freq * 2.76 * t)
             + 0.15 * math.sin(2.0 * math.pi * freq * 4.12 * t))
        out.append(v * env * amp)
    return out

def add_track(mix_l, mix_r, sound, start_sample, pan=0.0):
    # pan: -1.0 (left) to 1.0 (right)
    gain_l = math.cos((pan + 1.0) * math.pi / 4.0)
    gain_r = math.sin((pan + 1.0) * math.pi / 4.0)
    for i, s in enumerate(sound):
        idx = start_sample + i
        if idx < len(mix_l):
            mix_l[idx] += s * gain_l
            mix_r[idx] += s * gain_r

def write_stereo_wav(filepath, mix_l, mix_r):
    max_val = 0.001
    for i in range(len(mix_l)):
        max_val = max(max_val, abs(mix_l[i]), abs(mix_r[i]))
    
    scale = 0.92 / max_val
    with wave.open(filepath, 'w') as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        packed = bytearray()
        for i in range(len(mix_l)):
            l_clamped = max(-1.0, min(1.0, mix_l[i] * scale))
            r_clamped = max(-1.0, min(1.0, mix_r[i] * scale))
            l_int = int(l_clamped * 32767.0)
            r_int = int(r_clamped * 32767.0)
            packed.extend(struct.pack('<hh', l_int, r_int))
        wav.writeframes(packed)
    print(f"Generated: {filepath} ({len(mix_l)} samples, {len(mix_l)/SAMPLE_RATE:.1f}s)")

# ----------------------------------------------------
# A. BGM: "Giang Hồ Hành Khúc" (Heroic Wuxia Battle Theme)
# 16 Bars, 126 BPM, Key of A Minor Pentatonic
# ----------------------------------------------------
def build_wuxia_bgm():
    random.seed(1337)
    BPM = 126.0
    BEAT = 60.0 / BPM
    SIXTEENTH = BEAT / 4.0
    BAR = BEAT * 4.0
    TOTAL_BARS = 16
    TOTAL_SAMPLES = int(BAR * TOTAL_BARS * SAMPLE_RATE)
    
    mix_l = [0.0] * TOTAL_SAMPLES
    mix_r = [0.0] * TOTAL_SAMPLES
    
    # Bell at opening and midpoint
    add_track(mix_l, mix_r, temple_bell(220.0, 3.5, 0.4), 0, pan=0.0)
    add_track(mix_l, mix_r, temple_bell(220.0, 3.5, 0.4), int(BAR * 8 * SAMPLE_RATE), pan=0.0)
    
    # Taiko Drum Pattern across 16 bars
    taiko = taiko_drum(amp=0.65)
    taiko_light = taiko_drum(amp=0.38, pitch_start=160.0, pitch_end=60.0)
    
    for bar in range(TOTAL_BARS):
        b_start = bar * BAR
        # Martial galloping rhythm: 1, 2, 2.5, 3, 4, 4.5
        drum_steps = [0, 4, 6, 8, 12, 14]
        for st in drum_steps:
            t = b_start + st * SIXTEENTH
            s_idx = int(t * SAMPLE_RATE)
            if st in (0, 8):
                add_track(mix_l, mix_r, taiko, s_idx, pan=random.uniform(-0.1, 0.1))
            else:
                add_track(mix_l, mix_r, taiko_light, s_idx, pan=random.uniform(-0.25, 0.25))
    
    # Guzheng Melody & Arpeggios (Pentatonic: A3, C4, D4, E4, G4, A4, C5, D5, E5)
    # A3=57, C4=60, D4=62, E4=64, G4=67, A4=69, C5=72, D5=74, E5=76
    guzheng_notes = [
        # Bars 1-4 (Intro Cascade)
        (0, 57, 0.8), (2, 60, 0.8), (4, 64, 0.8), (6, 67, 0.8), (8, 69, 1.2), (12, 72, 1.0),
        (16, 69, 0.8), (18, 67, 0.8), (20, 64, 0.8), (24, 62, 0.8), (28, 60, 1.0),
        (32, 57, 0.8), (34, 62, 0.8), (36, 64, 0.8), (40, 67, 1.0), (44, 69, 1.2),
        (48, 72, 0.6), (50, 74, 0.6), (52, 76, 1.5), (58, 74, 0.8), (60, 72, 1.2),
        
        # Bars 5-8 (Verse Chords & Runs)
        (64, 57, 1.0), (66, 60, 0.6), (68, 64, 0.6), (72, 67, 0.8), (76, 69, 1.2),
        (80, 64, 0.8), (84, 62, 0.8), (88, 60, 1.0), (92, 57, 1.2),
        (96, 60, 0.6), (98, 64, 0.6), (100, 67, 0.8), (104, 72, 1.0), (108, 69, 1.2),
        (112, 74, 0.6), (114, 72, 0.6), (116, 69, 0.8), (120, 67, 0.8), (124, 64, 1.2),
        
        # Bars 9-12 (Chorus High Energy)
        (128, 69, 0.5), (130, 72, 0.5), (132, 76, 0.8), (136, 79, 1.2), (140, 76, 0.8),
        (144, 74, 0.6), (146, 72, 0.6), (148, 69, 0.8), (152, 67, 0.8), (156, 64, 1.0),
        (160, 67, 0.5), (162, 69, 0.5), (164, 72, 0.8), (168, 76, 1.2), (172, 79, 1.0),
        (176, 81, 0.8), (180, 79, 0.8), (184, 76, 1.0), (188, 72, 1.2),
        
        # Bars 13-16 (Resolve & Loop Turnaround)
        (192, 69, 0.8), (196, 67, 0.8), (200, 64, 0.8), (204, 62, 1.0),
        (208, 60, 0.8), (212, 57, 1.2), (216, 55, 1.0), (220, 57, 1.5),
        # Waterfall cascade into loop
        (240, 76, 0.3), (242, 74, 0.3), (244, 72, 0.3), (246, 69, 0.3),
        (248, 67, 0.3), (250, 64, 0.3), (252, 62, 0.3), (254, 60, 0.3)
    ]
    
    for step, midi, dur in guzheng_notes:
        t = step * SIXTEENTH
        s_idx = int(t * SAMPLE_RATE)
        f = midi_to_freq(midi)
        # Karplus-strong string pluck
        plk = karplus_strong(f, dur * 1.4, damp=0.992)
        pan = -0.35 if (step % 4 < 2) else 0.35
        add_track(mix_l, mix_r, plk, s_idx, pan=pan)
        
    # Bamboo Flute Melodic Line (Bars 5 to 16)
    flute_notes = [
        # Bar 5-6 (Heroic entry)
        (64, 69, 1.8), (72, 72, 1.6), (80, 76, 2.4),
        # Bar 7-8
        (96, 74, 1.2), (102, 72, 1.0), (108, 69, 1.5), (116, 67, 2.0),
        # Bar 9-10 (Climax Chorus)
        (128, 76, 1.6), (136, 79, 1.8), (144, 81, 2.8),
        # Bar 11-12
        (160, 79, 1.4), (168, 76, 1.4), (176, 74, 1.8), (184, 72, 2.2),
        # Bar 13-14 (Slowing descent)
        (192, 69, 2.0), (202, 67, 1.5), (208, 64, 2.2), (218, 60, 2.0),
        # Bar 15-16 (Long sustained tonic note A4)
        (224, 69, 3.8)
    ]
    
    for step, midi, dur in flute_notes:
        t = step * SIXTEENTH
        s_idx = int(t * SAMPLE_RATE)
        f = midi_to_freq(midi)
        fl = bamboo_flute(f, dur, amp=0.36)
        add_track(mix_l, mix_r, fl, s_idx, pan=0.0) # Center lead
        
    write_stereo_wav(f"{OUT_DIR}/bgm.wav", mix_l, mix_r)

# ----------------------------------------------------
# B. BOSS BGM: "Ma Hoàng Xuất Thế" (Frantic Boss Battle)
# 16 Bars, 142 BPM, Fast Driving Double-Time Taiko & Aggressive Guzheng
# ----------------------------------------------------
def build_boss_bgm():
    random.seed(777)
    BPM = 142.0
    BEAT = 60.0 / BPM
    SIXTEENTH = BEAT / 4.0
    BAR = BEAT * 4.0
    TOTAL_BARS = 16
    TOTAL_SAMPLES = int(BAR * TOTAL_BARS * SAMPLE_RATE)
    
    mix_l = [0.0] * TOTAL_SAMPLES
    mix_r = [0.0] * TOTAL_SAMPLES
    
    # Heavy Gong at Bar 1 and 9
    add_track(mix_l, mix_r, temple_bell(180.0, 3.2, 0.55), 0, pan=0.0)
    add_track(mix_l, mix_r, temple_bell(180.0, 3.2, 0.55), int(BAR * 8 * SAMPLE_RATE), pan=0.0)
    
    # Aggressive Rapid Taiko (16th note rolls and accents)
    taiko_heavy = taiko_drum(amp=0.85, pitch_start=180.0, pitch_end=42.0)
    taiko_fast = taiko_drum(amp=0.45, pitch_start=200.0, pitch_end=65.0)
    
    for bar in range(TOTAL_BARS):
        b_start = bar * BAR
        for st in range(16):
            t = b_start + st * SIXTEENTH
            s_idx = int(t * SAMPLE_RATE)
            if st in (0, 4, 8, 12):
                add_track(mix_l, mix_r, taiko_heavy, s_idx, pan=0.0)
            elif st % 2 == 1:
                add_track(mix_l, mix_r, taiko_fast, s_idx, pan=random.uniform(-0.35, 0.35))
                
    # Frantic D Minor Pentatonic Guzheng shred
    # D3=50, F3=53, G3=55, A3=57, C4=60, D4=62, F4=65, G4=67, A4=69, C5=72, D5=74
    boss_notes = []
    scale = [50, 53, 55, 57, 60, 62, 65, 67, 69, 72, 74]
    for bar in range(TOTAL_BARS):
        for st in range(0, 16, 2):
            idx = (bar * 8 + st // 2) % len(scale)
            note = scale[idx]
            boss_notes.append((bar * 16 + st, note, 0.45))
            
    for step, midi, dur in boss_notes:
        t = step * SIXTEENTH
        s_idx = int(t * SAMPLE_RATE)
        f = midi_to_freq(midi)
        plk = karplus_strong(f, dur, damp=0.985)
        add_track(mix_l, mix_r, plk, s_idx, pan=random.uniform(-0.4, 0.4))
        
    write_stereo_wav(f"{OUT_DIR}/boss_bgm.wav", mix_l, mix_r)

if __name__ == "__main__":
    print("=== Generating Authentic Wuxia Soundtracks ===")
    build_wuxia_bgm()
    build_boss_bgm()
    print("=== All Soundtracks Generated Successfully! ===")
