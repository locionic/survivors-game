#!/usr/bin/env python3
"""
Generates an energetic retro 8-bit battle theme loop (BGM) in 16-bit PCM WAV format.
Key: A Minor, Tempo: 135 BPM, Length: 8 bars (~14.22 seconds).
"""

import wave
import math
import struct
import random

SAMPLE_RATE = 44100
BPM = 135.0
BEAT_DUR = 60.0 / BPM
SIXTEENTH = BEAT_DUR / 4.0
TOTAL_BEATS = 64 # 16 bars of 4/4 (~28.44 seconds)
TOTAL_DURATION = TOTAL_BEATS * BEAT_DUR
NUM_SAMPLES = int(SAMPLE_RATE * TOTAL_DURATION)

def midi_to_freq(midi_note):
    return 440.0 * (2.0 ** ((midi_note - 69.0) / 12.0))

# Bassline pattern (A minor: A1=33, C2=36, D2=38, E2=40, F2=41, G2=43)
# 16 bars: Verse (8 bars) + Chorus (8 bars)
BASS_ROOTS = [
    # Verse
    33, 33, 41, 43, 33, 36, 38, 40,
    # Chorus (epic escalation: F -> G -> A -> C -> F -> D -> E -> E)
    41, 43, 33, 36, 41, 38, 40, 40
]

# Lead melody notes
LEAD_PATTERNS = [
    # Bar 1 (Verse)
    [(0, 57), (2, 60), (4, 62), (7, 64), (10, 67), (12, 69)],
    # Bar 2
    [(0, 69), (3, 67), (6, 64), (10, 62), (12, 60), (14, 62)],
    # Bar 3
    [(0, 65), (3, 69), (6, 72), (10, 69), (12, 65)],
    # Bar 4
    [(0, 67), (4, 71), (8, 69), (12, 67), (14, 64)],
    # Bar 5
    [(0, 57), (2, 60), (4, 64), (6, 69), (8, 72), (12, 69)],
    # Bar 6
    [(0, 72), (4, 71), (8, 67), (12, 64)],
    # Bar 7
    [(0, 62), (3, 65), (6, 69), (10, 65), (12, 62)],
    # Bar 8
    [(0, 64), (2, 67), (4, 71), (6, 74), (8, 76), (12, 64)],
    # Bar 9 (Chorus - soaring high melody)
    [(0, 65), (2, 69), (4, 72), (6, 76), (8, 77), (12, 76)],
    # Bar 10
    [(0, 74), (3, 72), (6, 71), (10, 69), (12, 71), (14, 72)],
    # Bar 11
    [(0, 69), (2, 72), (4, 76), (8, 79), (12, 76), (14, 74)],
    # Bar 12
    [(0, 72), (4, 76), (8, 74), (12, 71)],
    # Bar 13
    [(0, 77), (3, 76), (6, 74), (10, 72), (12, 69)],
    # Bar 14
    [(0, 74), (3, 71), (6, 69), (10, 67), (12, 69), (14, 71)],
    # Bar 15
    [(0, 76), (2, 79), (4, 81), (6, 79), (8, 76), (12, 74)],
    # Bar 16 (Turnaround resolution)
    [(0, 71), (4, 67), (8, 64), (12, 57)]
]

samples = [0.0] * NUM_SAMPLES

# 1. Synthesize Bassline (Pulse wave with decay envelope)
for bar in range(16):
    root = BASS_ROOTS[bar]
    for step in range(16): # 16 sixteenth notes per bar
        # Driving octave pattern (root, root, oct, root...)
        note = root + (12 if step % 2 == 1 else 0)
        freq = midi_to_freq(note)
        
        start_time = (bar * 16 + step) * SIXTEENTH
        start_sample = int(start_time * SAMPLE_RATE)
        note_samples = int(SIXTEENTH * 0.85 * SAMPLE_RATE)
        
        phase = 0.0
        for i in range(note_samples):
            idx = start_sample + i
            if idx >= NUM_SAMPLES:
                break
            phase += 2.0 * math.pi * freq / SAMPLE_RATE
            # 25% duty cycle pulse wave for classic chiptune bass
            p_val = math.sin(phase)
            val = 0.35 if (p_val > 0.5) else -0.35
            env = (1.0 - (i / note_samples)) ** 1.8
            samples[idx] += val * env * 0.45

# 2. Synthesize Lead Melody (Square wave with light vibrato and soft echo)
for bar in range(16):
    events = LEAD_PATTERNS[bar]
    for step, note in events:
        freq = midi_to_freq(note)
        start_time = (bar * 16 + step) * SIXTEENTH
        start_sample = int(start_time * SAMPLE_RATE)
        note_samples = int(SIXTEENTH * 2.2 * SAMPLE_RATE) # Legato sustain
        
        phase = 0.0
        for i in range(note_samples):
            idx = start_sample + i
            if idx >= NUM_SAMPLES:
                break
            # Vibrato
            vibrato = 1.0 + 0.015 * math.sin(i / SAMPLE_RATE * 35.0)
            phase += 2.0 * math.pi * (freq * vibrato) / SAMPLE_RATE
            sq = 0.3 if math.sin(phase) > 0 else -0.3
            env = min(1.0, (i / (SAMPLE_RATE * 0.01))) * ((1.0 - (i / note_samples)) ** 1.2)
            
            # Primary signal
            lead_val = sq * env * 0.32
            samples[idx] += lead_val
            
            # 16th note echo/delay
            echo_idx = idx + int(SIXTEENTH * 2.0 * SAMPLE_RATE)
            if echo_idx < NUM_SAMPLES:
                samples[echo_idx] += lead_val * 0.3

# 3. Drums / Percussion (Kick on 1 & 3, Snare on 2 & 4, Hi-hat on 16ths)
for beat in range(TOTAL_BEATS):
    beat_start = int(beat * BEAT_DUR * SAMPLE_RATE)
    
    # Kick on beats 0, 2 (within each bar: 0, 2, 4, 6...)
    if beat % 2 == 0:
        kick_dur = int(SAMPLE_RATE * 0.09)
        phase = 0.0
        for i in range(kick_dur):
            idx = beat_start + i
            if idx < NUM_SAMPLES:
                f = 130.0 * (1.0 - (i / kick_dur) * 0.8)
                phase += 2.0 * math.pi * f / SAMPLE_RATE
                env = (1.0 - i / kick_dur) ** 2.0
                samples[idx] += math.sin(phase) * env * 0.55
                
    # Snare on beats 1, 3
    else:
        snare_dur = int(SAMPLE_RATE * 0.12)
        random.seed(beat * 77)
        for i in range(snare_dur):
            idx = beat_start + i
            if idx < NUM_SAMPLES:
                noise = (random.random() * 2.0 - 1.0) * 0.4
                env = (1.0 - i / snare_dur) ** 2.5
                samples[idx] += noise * env * 0.45

    # Hi-hats on each eighth note
    for sub in [0, int(BEAT_DUR * 0.5 * SAMPLE_RATE)]:
        hh_start = beat_start + sub
        hh_dur = int(SAMPLE_RATE * 0.035)
        for i in range(hh_dur):
            idx = hh_start + i
            if idx < NUM_SAMPLES:
                noise = (random.random() * 2.0 - 1.0) * 0.2
                env = (1.0 - i / hh_dur) ** 3.0
                samples[idx] += noise * env * 0.25

# Normalize and export
out_path = "/home/renovibe79/survivors-game/assets/audio/bgm.wav"
with wave.open(out_path, 'w') as wav:
    wav.setnchannels(1)
    wav.setsampwidth(2)
    wav.setframerate(SAMPLE_RATE)
    
    packed = bytearray()
    max_amp = max(max(abs(s) for s in samples), 0.001)
    norm_factor = 0.85 / max_amp
    
    for s in samples:
        val = int(max(-1.0, min(1.0, s * norm_factor)) * 32767.0)
        packed.extend(struct.pack('<h', val))
        
    wav.writeframes(packed)

print(f"Generated BGM: {out_path} ({TOTAL_DURATION:.2f}s, {len(samples)} samples)")
