"""Рисует иконку Капри 1024x1024 без внешних картинок."""
import math
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

SIZE = 1024
OUT = r"C:\capricorn-mybild\ios\Capri\Assets.xcassets\AppIcon.appiconset"
os.makedirs(OUT, exist_ok=True)


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


base = Image.new("RGB", (SIZE, SIZE), (10, 7, 19))
draw = ImageDraw.Draw(base)

top = (10, 7, 19)
bottom = (28, 11, 40)
for y in range(SIZE):
    draw.line([(0, y), (SIZE, y)], fill=lerp(top, bottom, y / SIZE))

glow = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
gdraw = ImageDraw.Draw(glow)
gdraw.ellipse([SIZE * 0.40, -SIZE * 0.25, SIZE * 1.25, SIZE * 0.60], fill=(255, 60, 138))
gdraw.ellipse([-SIZE * 0.25, SIZE * 0.45, SIZE * 0.65, SIZE * 1.20], fill=(112, 74, 250))
glow = glow.filter(ImageFilter.GaussianBlur(180))
base = Image.blend(base, Image.blend(base, glow, 0.55), 0.75)

# тонкая неоновая рамка
frame = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
fdraw = ImageDraw.Draw(frame)
fdraw.rounded_rectangle([26, 26, SIZE - 26, SIZE - 26], radius=210, outline=(255, 90, 160, 120), width=5)
frame = frame.filter(ImageFilter.GaussianBlur(2))
base = Image.alpha_composite(base.convert("RGBA"), frame).convert("RGB")

font_path = r"C:\Windows\Fonts\arialbd.ttf"
font = ImageFont.truetype(font_path, 660)
letter = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
ldraw = ImageDraw.Draw(letter)
text = "C"
box = ldraw.textbbox((0, 0), text, font=font)
tw, th = box[2] - box[0], box[3] - box[1]
pos = ((SIZE - tw) / 2 - box[0], (SIZE - th) / 2 - box[1] - 22)
ldraw.text(pos, text, font=font, fill=(255, 255, 255, 255))

shadow = letter.filter(ImageFilter.GaussianBlur(38))
shadow = shadow.point(lambda p: min(255, int(p * 1.1)))
tinted = Image.new("RGBA", (SIZE, SIZE), (255, 40, 130, 0))
tinted.putalpha(shadow.split()[3].point(lambda a: int(a * 0.75)))
base = Image.alpha_composite(base.convert("RGBA"), tinted)
base = Image.alpha_composite(base, letter)

# глаза-полоски: намёк на цифровую личность
eyes = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
edraw = ImageDraw.Draw(eyes)
for cx in (SIZE * 0.36, SIZE * 0.64):
    edraw.rounded_rectangle([cx - 62, 800, cx + 62, 818], radius=9, fill=(255, 80, 150, 220))
eyes = eyes.filter(ImageFilter.GaussianBlur(6))
base = Image.alpha_composite(base, eyes)

icon = base.convert("RGB")
icon.save(os.path.join(OUT, "icon-1024.png"), "PNG")
print("icon:", os.path.join(OUT, "icon-1024.png"))
