#!/usr/bin/env python3
"""
Asset generator for Expansion 13.0: Game Feel & Retention Masterclass.
Synthesizes:
1. assets/audio/shield_break.wav (Crystal Qi Shield shattering effect)
2. assets/audio/boss_bgm.wav (Intense 150 BPM retro wuxia war drum & combat theme)
"""

import math
import os
import random
import struct
import wave

AUDIO_DIR = "/home/renovibe79/survivors-game/assets/audio"
os.makedirs(AUDIO_DIR, exist_ok=True)

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

# 1. Shield Break: Glass shattering crunch + high crystal resonance (0.45s)
def gen_shield_break():
    duration = 0.45
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    # Resonant crystal pitches: 1760Hz, 2637Hz, 3520Hz
    crystal_freqs = [1760.0, 2637.0, 3520.0]
    crystal_phases = [0.0, 0.0, 0.0]
    random.seed(1337)
    
    for i in range(num_samples):
        progress = i / num_samples
        # Initial crunch noise burst (first 0.08s)
        noise = (random.random() * 2.0 - 1.0) * math.exp(-35.0 * progress) * 0.7
        
        # Crystal harmonic ring-out
        crystal_val = 0.0
        for idx, freq in enumerate(crystal_freqs):
            crystal_phases[idx] += 2.0 * math.pi * freq / SAMPLE_RATE
            v = math.sin(crystal_phases[idx])
            crystal_env = math.exp(-12.0 * progress)
            crystal_val += v * crystal_env * 0.25
            
        # Low frequency punch
        sub_phase = 2.0 * math.pi * 90.0 * (i / SAMPLE_RATE)
        sub = math.sin(sub_phase) * math.exp(-22.0 * progress) * 0.4
        
        samples.append(noise + crystal_val + sub)
    return samples

# 2. Boss Battle BGM: 150 BPM, D Minor Wuxia War Drum & Pentatonic Synth Loop (~12.8s, 32 beats)
def gen_boss_bgm():
    bpm = 150.0
    beat_dur = 60.0 / bpm
    sixteenth = beat_dur / 4.0
    total_beats = 32 # 8 bars
    total_duration = total_beats * beat_dur
    num_samples = int(SAMPLE_RATE * total_duration)
    samples = [0.0] * num_samples
    
    def midi_to_freq(m):
        return 440.0 * (2.0 ** ((m - 69.0) / 12.0))
        
    # War Drum roots: D2 (38), D2 (38), Bb1 (34), C2 (36)
    roots = [38, 38, 34, 36, 38, 38, 41, 40]
    
    # 1. Driving Bass / Taiko War Drum
    for bar in range(8):
        root = roots[bar]
        for step in range(16):
            # Heavy driving gallop rhythm: 0, 3, 6, 8, 10, 12, 14
            if step in [0, 3, 6, 8, 10, 12, 14]:
                note = root if step in [0, 8] else root + 12
                freq = midi_to_freq(note)
                start_sample = int((bar * 16 + step) * sixteenth * SAMPLE_RATE)
                dur_samples = int(sixteenth * 1.2 * SAMPLE_RATE)
                phase = 0.0
                for i in range(dur_samples):
                    idx = start_sample + i
                    if idx >= num_samples:
                        break
                    phase += 2.0 * math.pi * freq / SAMPLE_RATE
                    # Punchy triangle/pulse wave
                    val = (math.sin(phase) + 0.3 * math.sin(phase * 2.0))
                    # Taiko drum noise crack
                    if i < 400:
                        val += (random.random() * 2.0 - 1.0) * 0.4
                    env = math.exp(-8.0 * (i / dur_samples))
                    samples[idx] += val * env * 0.40

    # 2. Heroic Wuxia Fast Melody (D Minor Pentatonic: D4=62, F4=65, G4=67, A4=69, C5=72, D5=74)
    melody_events = [
        # Bar 1
        [(0, 62), (2, 65), (4, 69), (6, 72), (8, 74), (12, 72)],
        # Bar 2
        [(0, 69), (3, 67), (6, 65), (8, 62), (10, 65), (12, 67)],
        # Bar 3
        [(0, 65), (2, 69), (4, 72), (8, 74), (12, 77)],
        # Bar 4
        [(0, 76), (4, 74), (8, 72), (12, 69)],
        # Bar 5
        [(0, 74), (2, 72), (4, 69), (6, 67), (8, 69), (12, 72)],
        # Bar 6
        [(0, 74), (4, 77), (8, 74), (12, 69)],
        # Bar 7
        [(0, 67), (2, 65), (4, 62), (8, 65), (12, 67)],
        # Bar 8
        [(0, 69), (3, 72), (6, 74), (8, 76), (10, 74), (12, 72)]
    ]
    
    for bar in range(8):
        for step, m_note in melody_events[bar]:
            freq = midi_to_freq(m_note)
            start_sample = int((bar * 16 + step) * sixteenth * SAMPLE_RATE)
            dur_samples = int(sixteenth * 2.5 * SAMPLE_RATE)
            phase = 0.0
            for i in range(dur_samples):
                idx = start_sample + i
                if idx >= num_samples:
                    break
                # Light vibrato
                vib = 1.0 + 0.015 * math.sin(i * 0.012)
                phase += 2.0 * math.pi * (freq * vib) / SAMPLE_RATE
                val = 0.4 if math.sin(phase) > 0 else -0.4
                env = (1.0 - (i / dur_samples)) ** 1.3
                samples[idx] += val * env * 0.32
                
    # Normalize
    max_val = max(abs(s) for s in samples)
    if max_val > 0.0:
        samples = [s / max_val * 0.85 for s in samples]
    return samples

if __name__ == "__main__":
    write_wav(f"{AUDIO_DIR}/shield_break.wav", gen_shield_break())
    write_wav(f"{AUDIO_DIR}/boss_bgm.wav", gen_boss_bgm())
    print("=== Expansion 13.0 audio generated successfully! ===")
