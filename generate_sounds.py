#!/usr/bin/env python3
"""
Generates crisp 8-bit retro sound effects using standard library math & wave modules.
No external dependencies required.
"""

import wave
import math
import struct
import random

SAMPLE_RATE = 44100

def write_wav(filename, samples):
    with wave.open(filename, 'w') as wav:
        wav.setnchannels(1)        # Mono
        wav.setsampwidth(2)        # 16-bit PCM
        wav.setframerate(SAMPLE_RATE)
        
        packed = bytearray()
        for s in samples:
            # Clamp to -1.0 to 1.0
            clamped = max(-1.0, min(1.0, s))
            val = int(clamped * 32767.0)
            packed.extend(struct.pack('<h', val))
            
        wav.writeframes(packed)
    print(f"Generated: {filename} ({len(samples)} samples)")

# 1. Shoot sound: Rapid frequency drop from 880Hz down to 220Hz (0.12s)
def gen_shoot():
    duration = 0.12
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        progress = i / num_samples
        # Exponential frequency drop
        freq = 880.0 * math.exp(-2.5 * progress)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        
        # Square wave with soft harmonics
        val = 0.5 if (math.sin(phase) > 0) else -0.5
        # Linear envelope decay
        env = (1.0 - progress) ** 1.5
        samples.append(val * env * 0.4)
    return samples

# 2. Hit sound: Crunchy noise burst + pitch sweep (0.09s)
def gen_hit():
    duration = 0.09
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    random.seed(42)
    for i in range(num_samples):
        progress = i / num_samples
        freq = 240.0 * (1.0 - progress * 0.6)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        
        sine_part = math.sin(phase)
        noise = (random.random() * 2.0 - 1.0) * 0.4
        env = (1.0 - progress) ** 2.0
        samples.append((sine_part * 0.6 + noise) * env * 0.5)
    return samples

# 3. Gem collect sound: Two cheerful chime tones (C5 523Hz -> G5 784Hz) (0.14s)
def gen_gem():
    duration = 0.14
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        if t < 0.06:
            freq = 523.25 # C5
            env = 1.0 - (t / 0.06) * 0.3
        else:
            freq = 783.99 # G5
            rem = (t - 0.06) / 0.08
            env = (1.0 - rem) ** 1.8
            
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        # Triangle wave for warm bell-like chime
        tri = 2.0 * abs(2.0 * (phase / (2.0 * math.pi) - math.floor(phase / (2.0 * math.pi) + 0.5))) - 1.0
        samples.append(tri * env * 0.45)
    return samples

# 4. Level up fanfare: 4 fast ascending arpeggios (C5, E5, G5, C6) (0.36s)
def gen_level_up():
    notes = [523.25, 659.25, 783.99, 1046.50]
    note_dur = 0.09
    samples = []
    for note in notes:
        n_samples = int(SAMPLE_RATE * note_dur)
        phase = 0.0
        for i in range(n_samples):
            progress = i / n_samples
            phase += 2.0 * math.pi * note / SAMPLE_RATE
            # Blended square/sine
            sq = 0.4 if math.sin(phase) > 0 else -0.4
            si = math.sin(phase) * 0.5
            env = (1.0 - progress) ** 1.2
            samples.append((sq + si) * env * 0.4)
    return samples

# 5. Hurt sound: Punchy low impact drop (160Hz -> 50Hz) (0.18s)
def gen_hurt():
    duration = 0.18
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    for i in range(num_samples):
        progress = i / num_samples
        freq = 160.0 * (1.0 - progress * 0.7)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        sq = 0.6 if math.sin(phase) > 0 else -0.6
        env = (1.0 - progress) ** 1.6
        samples.append(sq * env * 0.5)
    return samples

# 6. Thunder sound: Heavy explosion rumble (80Hz -> 30Hz) + electric noise (0.42s)
def gen_thunder():
    duration = 0.42
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    random.seed(99)
    for i in range(num_samples):
        progress = i / num_samples
        freq = 110.0 * (1.0 - progress * 0.75)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        sine_part = math.sin(phase) * 0.6
        noise = (random.random() * 2.0 - 1.0) * (0.8 if progress < 0.2 else 0.3)
        env = (1.0 - progress) ** 1.8
        samples.append((sine_part + noise) * env * 0.6)
    return samples

# 7. Coin sound: Bright two-tone arcade chime (B5 987Hz -> E6 1318Hz) (0.13s)
def gen_coin():
    duration = 0.13
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 987.77 if t < 0.05 else 1318.51
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        val = 0.4 if math.sin(phase) > 0 else -0.4
        env = (1.0 - (i / num_samples)) ** 1.5
        samples.append(val * env * 0.4)
    return samples

# 8. Explosion sound: Heavy bass impact (160Hz -> 40Hz) + fiery noise blast (0.32s)
def gen_explosion():
    duration = 0.32
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    random.seed(77)
    for i in range(num_samples):
        progress = i / num_samples
        freq = 160.0 * (1.0 - progress * 0.75)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        sine = math.sin(phase) * 0.7
        noise = (random.random() * 2.0 - 1.0) * (0.9 if progress < 0.25 else 0.4)
        env = (1.0 - progress) ** 1.6
        samples.append((sine * 0.6 + noise * 0.4) * env * 0.65)
    return samples

# 9. Axe throw sound: Sharp swooshing pitch sweep up and down (0.16s)
def gen_axe():
    duration = 0.16
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    random.seed(33)
    for i in range(num_samples):
        progress = i / num_samples
        # Arc frequency 300Hz -> 750Hz -> 200Hz
        freq = 300.0 + 450.0 * math.sin(progress * math.pi)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        noise = (random.random() * 2.0 - 1.0) * 0.25
        sine = math.sin(phase) * 0.75
        env = math.sin(progress * math.pi) ** 1.2
        samples.append((sine + noise) * env * 0.45)
    return samples

# 10. Powerup sound: Triple arpeggio sparkle C5 -> E5 -> G5 -> C6 (0.28s)
def gen_powerup():
    duration = 0.28
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    notes = [523.25, 659.25, 783.99, 1046.50]
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        note_idx = min(3, int(t / (duration / 4.0)))
        freq = notes[note_idx]
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        val = math.sin(phase) * 0.5 + (0.3 if math.sin(phase * 2.0) > 0 else -0.3)
        env = (1.0 - (i / num_samples)) ** 1.2
        samples.append(val * env * 0.45)
    return samples

# 11. Boss Alarm: Ominous low siren / brass blast (0.65s)
def gen_boss_alarm():
    duration = 0.65
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase1 = 0.0
    phase2 = 0.0
    for i in range(num_samples):
        progress = i / num_samples
        freq1 = 130.0 + 15.0 * math.sin(progress * math.pi * 6.0)
        freq2 = 133.5 # Beating dissonance
        phase1 += 2.0 * math.pi * freq1 / SAMPLE_RATE
        phase2 += 2.0 * math.pi * freq2 / SAMPLE_RATE
        wave1 = 0.5 if math.sin(phase1) > 0 else -0.5
        wave2 = 0.5 if math.sin(phase2) > 0 else -0.5
        env = min(1.0, progress * 8.0) * (1.0 - progress) ** 1.1
        samples.append((wave1 + wave2) * 0.5 * env * 0.5)
    return samples

# 12. Shrine Activation: Celestial harmonic chime chord with shimmer (0.55s)
def gen_shrine_activate():
    duration = 0.55
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    # Major triad chime with octave shimmer: 659.25 (E5), 830.61 (G#5), 987.77 (B5), 1318.51 (E6)
    freqs = [659.25, 830.61, 987.77, 1318.51]
    phases = [0.0, 0.0, 0.0, 0.0]
    for i in range(num_samples):
        progress = i / num_samples
        s_val = 0.0
        for idx, f in enumerate(freqs):
            # slight vibrato / celestial sparkle
            current_f = f * (1.0 + 0.012 * math.sin(i * 0.008 + idx))
            phases[idx] += 2.0 * math.pi * current_f / SAMPLE_RATE
            # Sine wave + small overtone
            v = math.sin(phases[idx]) + 0.25 * math.sin(phases[idx] * 2.0)
            s_val += v * (0.3 - idx * 0.05)
        # Fast attack, exponential decay
        env = min(1.0, progress * 15.0) * (1.0 - progress) ** 1.3
        samples.append(s_val * env * 0.4)
    return samples

# 13. Slash sound: Sharp metallic blade swoosh (1500Hz -> 280Hz) + airy slice (0.16s)
def gen_slash():
    duration = 0.16
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    phase_metal = 0.0
    random.seed(55)
    for i in range(num_samples):
        progress = i / num_samples
        freq = 1500.0 * (1.0 - progress * 0.82)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        phase_metal += 2.0 * math.pi * 2350.0 / SAMPLE_RATE
        
        # Blade swoosh: sine + slight triangle
        swoosh = math.sin(phase) * 0.6
        # Metallic ring
        metal = math.sin(phase_metal) * (0.35 if progress < 0.3 else 0.0)
        # Air slice noise
        noise = (random.random() * 2.0 - 1.0) * (0.45 * (1.0 - progress))
        
        env = min(1.0, progress * 20.0) * ((1.0 - progress) ** 1.5)
        samples.append((swoosh + metal + noise) * env * 0.55)
    return samples

if __name__ == "__main__":
    base = "/home/renovibe79/survivors-game/assets/audio/"
    write_wav(base + "shoot.wav", gen_shoot())
    write_wav(base + "hit.wav", gen_hit())
    write_wav(base + "gem.wav", gen_gem())
    write_wav(base + "level_up.wav", gen_level_up())
    write_wav(base + "hurt.wav", gen_hurt())
    write_wav(base + "thunder.wav", gen_thunder())
    write_wav(base + "coin.wav", gen_coin())
    write_wav(base + "explosion.wav", gen_explosion())
    write_wav(base + "axe.wav", gen_axe())
    write_wav(base + "powerup.wav", gen_powerup())
    write_wav(base + "boss_alarm.wav", gen_boss_alarm())
    write_wav(base + "shrine_activate.wav", gen_shrine_activate())
    write_wav(base + "slash.wav", gen_slash())
    print("All audio generated successfully!")

