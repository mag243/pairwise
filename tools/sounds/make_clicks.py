#!/usr/bin/env python3
"""Make the sounds of a join and a parting: short mechanical clicks (ADR 0055).

A click is a burst of noise and a few short resonances, as of a small metal part
that hits another. A join is a light click and a firmer one, as a latch that
goes home. A parting is the same the other way round, higher and lighter.
The noise is seeded, so the same files come out every time.

Usage: tools/sounds/make_clicks.py
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
PEAK = 0.5
OUT = Path(__file__).resolve().parents[2] / "Apps/PairwiseMac/Resources"


def click(at, strength, tones, decay, noise_decay, rng, samples):
    """Adds one click at `at` seconds: resonances as (frequency, share) and a burst of noise."""
    start = int(at * RATE)
    length = int(decay * 8 * RATE)
    previous = 0.0
    for index in range(length):
        if start + index >= len(samples):
            break
        time = index / RATE
        tone = sum(
            share * math.sin(2 * math.pi * frequency * time) for frequency, share in tones
        ) * math.exp(-time / decay)
        white = rng.uniform(-1, 1)
        # The difference of two samples keeps the high end, which sounds like a hard edge.
        noise = (white - previous) * 0.5 * math.exp(-time / noise_decay)
        previous = white
        samples[start + index] += strength * (tone + noise)


def write(name, samples):
    top = max(abs(value) for value in samples)
    frames = b"".join(
        struct.pack("<h", int(value / top * PEAK * 32767)) for value in samples
    )
    with wave.open(str(OUT / name), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(frames)
    print(f"{name}: {len(samples) / RATE * 1000:.0f} ms")


def join():
    rng = random.Random(1)
    samples = [0.0] * int(0.09 * RATE)
    click(0.0, 0.35, [(3100, 0.6), (5200, 0.4)], 0.003, 0.0015, rng, samples)
    click(0.022, 1.0, [(1250, 0.7), (2600, 0.5), (4300, 0.25)], 0.006, 0.002, rng, samples)
    return samples


def part():
    rng = random.Random(2)
    samples = [0.0] * int(0.07 * RATE)
    click(0.0, 0.7, [(1900, 0.5), (3600, 0.5)], 0.004, 0.0015, rng, samples)
    click(0.016, 0.4, [(3400, 0.6), (6000, 0.4)], 0.0025, 0.001, rng, samples)
    return samples


if __name__ == "__main__":
    write("PairJoin.wav", join())
    write("PairPart.wav", part())
