import wave
import struct
import random
import math
import os

SAMPLE_RATE = 22050
DURATION = 15
OUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')

def clamp(v):
    return max(-32768, min(32767, int(v)))

def save_wav(filename, samples):
    path = os.path.join(OUT_DIR, filename)
    with wave.open(path, 'w') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        for s in samples:
            wf.writeframes(struct.pack('<h', clamp(s)))
    size_kb = os.path.getsize(path) / 1024
    print(f'  {filename}: {size_kb:.0f} KB')

print('Generating ambient sounds...')

# 白噪音
n = DURATION * SAMPLE_RATE
samples = [random.randint(-32767, 32767) for _ in range(n)]
save_wav('white_noise.wav', samples)

# 雨声 (低通滤波 + 随机滴答)
prev = 0.0
samples = []
for i in range(n):
    noise = random.randint(-32767, 32767)
    prev = prev * 0.88 + noise * 0.12
    s = prev
    if random.random() < 0.003:
        s += random.randint(8000, 28000) * (1.0 if random.random() > 0.5 else -1.0)
    samples.append(s)
save_wav('rain.wav', samples)

# 咖啡馆 (低频嗡嗡 + 偶尔杯碟声)
prev = 0.0
samples = []
for i in range(n):
    noise = random.randint(-32767, 32767)
    prev = prev * 0.9 + noise * 0.1
    s = prev * 0.3
    if random.random() < 0.001:
        freq = random.randint(2000, 6000)
        t = (i % (SAMPLE_RATE // 4)) / SAMPLE_RATE
        s += math.sin(2 * math.pi * freq * t) * 15000 * (1 - t * 4)
    samples.append(s)
save_wav('cafe.wav', samples)

# 森林 (柔和噪音 + 虫鸣鸟叫模拟)
prev = 0.0
samples = []
for i in range(n):
    noise = random.randint(-32767, 32767)
    prev = prev * 0.92 + noise * 0.08
    s = prev * 0.25
    t_mod = i % SAMPLE_RATE
    if t_mod < SAMPLE_RATE * 0.15:
        freq = 3000 + (t_mod / SAMPLE_RATE) * 2000
        s += math.sin(2 * math.pi * freq * t_mod / SAMPLE_RATE) * 8000 * (1 - t_mod / (SAMPLE_RATE * 0.15))
    if random.random() < 0.0003:
        freq2 = random.randint(4000, 7000)
        s += math.sin(2 * math.pi * freq2 * (t_mod / SAMPLE_RATE)) * 12000
    samples.append(s)
save_wav('forest.wav', samples)

print('Done!')
