#!/usr/bin/env python3
"""Generate the Lull AppIcon at 1024x1024.

Visual: midnight gradient background with a soft warm-lamp glow centered
in the upper third — the brand's bedside-lamp motif. No text, no rounded
corners (App Store requires square + no alpha).
"""
import os
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
out = "/Users/augis/Desktop/toos/14_LULL/Lull/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

# 1. Midnight vertical gradient.
img = Image.new("RGB", (SIZE, SIZE), (15, 20, 41))  # midnight #0F1429
top = (9, 12, 27)        # night-deep
bot = (28, 35, 66)       # night-soft
for y in range(SIZE):
    t = y / (SIZE - 1)
    r = int(top[0] * (1 - t) + bot[0] * t)
    g = int(top[1] * (1 - t) + bot[1] * t)
    b = int(top[2] * (1 - t) + bot[2] * t)
    for x in range(SIZE):
        img.putpixel((x, y), (r, g, b))

# 2. Warm lamp glow — radial gradient, centered slightly above middle.
#    Built on a separate RGBA layer so we can compose with screen blend.
glow = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
draw = ImageDraw.Draw(glow)
cx, cy = SIZE // 2, int(SIZE * 0.42)
max_r = int(SIZE * 0.55)
# Concentric soft circles, fading to black (so screen-blend turns into add).
for r in range(max_r, 0, -1):
    t = r / max_r
    # color profile: bright honey center → amber → midnight at the edge
    rr = int(232 * (1 - t)**1.5)
    gg = int(192 * (1 - t)**1.7)
    bb = int(135 * (1 - t)**2.0)
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(rr, gg, bb))
glow = glow.filter(ImageFilter.GaussianBlur(radius=20))

# 3. Tight bright lamp core — small, sharp.
core = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
cd = ImageDraw.Draw(core)
core_r = int(SIZE * 0.045)
for r in range(core_r, 0, -1):
    t = r / core_r
    rr = int(255 * (1 - 0.1 * t))
    gg = int(232 * (1 - 0.2 * t))
    bb = int(170 * (1 - 0.3 * t))
    cd.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(rr, gg, bb))
core = core.filter(ImageFilter.GaussianBlur(radius=3))

# 4. Compose: screen-blend glow on top of midnight, then add core.
def screen(a, b):
    """SCREEN blend: 1 - (1-a)*(1-b)"""
    import numpy as np
    A = np.asarray(a, dtype=float) / 255.0
    B = np.asarray(b, dtype=float) / 255.0
    out = 1.0 - (1.0 - A) * (1.0 - B)
    return Image.fromarray((out * 255).clip(0, 255).astype("uint8"))

img = screen(img, glow)
img = screen(img, core)

# 5. Subtle starfield — a few dim points scattered in the lower half.
import random
random.seed(42)
sd = ImageDraw.Draw(img)
for _ in range(70):
    x = random.randint(0, SIZE - 1)
    y = random.randint(int(SIZE * 0.55), SIZE - 1)
    s = random.choice([1, 1, 1, 2, 2, 3])
    a = random.randint(40, 110)
    sd.ellipse([x - s, y - s, x + s, y + s], fill=(244, 240, 232, a))

# 6. Save without alpha (required by App Store).
img.convert("RGB").save(out, "PNG", optimize=True)
print(f"wrote {out} ({os.path.getsize(out):,} bytes)")
