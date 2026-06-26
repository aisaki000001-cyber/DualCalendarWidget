#!/usr/bin/env python3
"""双月日历图标生成器 — 双交叠圆环 · 简约黑白配色"""

import struct, math, sys

W = 1024
C = W // 2

def write_png(path, width, height, pixels):
    import zlib
    def chunk(ctype, data):
        c = ctype + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xFFFFFFFF)
    raw = b''
    for y in range(height):
        raw += b'\x00'
        for x in range(width):
            r, g, b, a = pixels[y * width + x]
            raw += struct.pack('BBBB', r, g, b, a)
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    png = b'\x89PNG\r\n\x1a\n'
    png += chunk(b'IHDR', ihdr)
    png += chunk(b'IDAT', zlib.compress(raw))
    png += chunk(b'IEND', b'')
    with open(path, 'wb') as f:
        f.write(png)

def blend(bg, fg):
    sa = fg[3] / 255.0
    return tuple(int(bg[i] * (1 - sa) + fg[i] * sa) for i in range(3)) + (255,)

def draw():
    pixels = []
    bg   = (28, 28, 30, 255)      # macOS 深灰底
    ring = (255, 255, 255, 255)   # 白环
    dot  = (180, 180, 180, 255)   # 浅灰点

    R = 330
    overlap = 190
    stroke_w = 30

    for y in range(W):
        for x in range(W):
            d_left  = math.hypot(x - (C - overlap), y - C) - R
            d_right = math.hypot(x - (C + overlap), y - C) - R

            ring_left  = abs(abs(d_left)  - stroke_w/2) - stroke_w/2
            ring_right = abs(abs(d_right) - stroke_w/2) - stroke_w/2

            px = bg

            # 左环（后方）
            if ring_left < 0:
                a = min(255, int(255 * (1 + ring_left / 2)))
                px = blend(px, (ring[0], ring[1], ring[2], max(0, a)))

            # 右环（前方，略亮）
            if ring_right < 0:
                a = min(255, int(255 * (1 + ring_right / 2)))
                px = blend(px, (ring[0], ring[1], ring[2], max(0, a)))

            # 环内小圆点 — 代表日历日期
            for cx, cy, r, shade in [
                (C - overlap, C - 130, 30, 200),
                (C - overlap, C +  90, 24, 160),
                (C + overlap, C - 150, 30, 220),
                (C + overlap, C +  70, 24, 180),
                (C + overlap, C -  30, 20, 200),
            ]:
                dd = math.hypot(x - cx, y - cy) - r
                if dd < 2.5:
                    a = min(255, int(255 * (1 - dd / 2.5)))
                    px = blend(px, (shade, shade, shade, max(0, a)))

            pixels.append(px)

    return pixels

if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) > 1 else '/Users/aisaki/Desktop/icon.png'
    pixels = draw()
    write_png(out, W, W, pixels)
    print(f'✅ 图标已生成: {out}')
