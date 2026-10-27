#!/usr/bin/env python3
import argparse
import math
import os

from PIL import Image, ImageDraw, ImageFont

SUPER = 4
BG_FILES = [("{name}@2x", 120), ("{name}@3x", 180), ("{name}Ipad", 76), ("{name}Ipad@2x", 152), ("{name}LargeIpad@2x", 167)]
NOTIF_FILES = [("{name}NotificationIcon", 20), ("{name}NotificationIcon@2x", 40), ("{name}NotificationIcon@3x", 60)]

WHITE = (255, 255, 255)


def color(hex_string):
    return tuple(int(hex_string[i:i + 2], 16) for i in (0, 2, 4))


class Palette:
    def __init__(self, top, bottom, accent=WHITE):
        self.top = color(top)
        self.bottom = color(bottom)
        self.accent = accent


class Variant:
    def __init__(self, name, top, bottom, emblem):
        self.name = name
        self.palette = Palette(top, bottom)
        self.emblem = emblem


def gradient(size, palette):
    image = Image.new("RGB", (size, size))
    top, bottom = palette.top, palette.bottom
    for y in range(size):
        t = y / max(1, size - 1)
        row = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        for x in range(size):
            image.putpixel((x, y), row)
    return image.convert("RGBA")


def font(size):
    candidates = [
        "arialbd.ttf", "arial.ttf",
        "C:/Windows/Fonts/arialbd.ttf", "C:/Windows/Fonts/seguisb.ttf",
        "/Library/Fonts/Arial Bold.ttf", "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    try:
        return ImageFont.load_default(size)
    except TypeError:
        return ImageFont.load_default()


def disc(draw, cx, cy, r, fill=None):
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill)


def ring(draw, cx, cy, r, w, fill):
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=fill, width=max(1, int(w)))


def rect(draw, x0, y0, x1, y1, fill, radius=0.0):
    draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=fill)


def polygon(draw, points, fill):
    draw.polygon(points, fill=fill)


def line(draw, x0, y0, x1, y1, w, fill):
    draw.line([x0, y0, x1, y1], fill=fill, width=max(1, int(w)))


def arc(draw, cx, cy, r, start, end, w, fill):
    draw.arc([cx - r, cy - r, cx + r, cy + r], start=start, end=end, fill=fill, width=max(1, int(w)))


def star(draw, cx, cy, r, points, inner_ratio, fill):
    coords = []
    for i in range(points * 2):
        radius = r if i % 2 == 0 else r * inner_ratio
        angle = math.pi * i / points - math.pi / 2
        coords.append((cx + radius * math.cos(angle), cy + radius * math.sin(angle)))
    polygon(draw, coords, fill)


def snowflake(draw, cx, cy, r, w, fill):
    for i in range(6):
        angle = math.pi * i / 3
        x1, y1 = cx + r * math.cos(angle), cy + r * math.sin(angle)
        line(draw, cx, cy, x1, y1, w, fill)
        for tip in (0.55, 0.8):
            for sign in (-1, 1):
                a = angle + sign * math.pi / 6
                bx, by = cx + r * tip * math.cos(angle), cy + r * tip * math.sin(angle)
                tx, ty = bx + r * 0.3 * math.cos(a), by + r * 0.3 * math.sin(a)
                line(draw, bx, by, tx, ty, w, fill)


def spiral(draw, cx, cy, r, turns, w, fill):
    steps = int(turns * 24)
    prev = None
    for i in range(steps + 1):
        t = i / steps
        angle = 2 * math.pi * turns * t
        radius = r * t
        point = (cx + radius * math.cos(angle), cy + radius * math.sin(angle))
        if prev is not None:
            line(draw, prev[0], prev[1], point[0], point[1], w, fill)
        prev = point


def letters(draw, cx, cy, size, text, fill):
    f = font(size)
    box = draw.textbbox((0, 0), text, font=f)
    draw.text((cx - (box[2] + box[0]) / 2, cy - (box[3] + box[1]) / 2), text, font=f, fill=fill)


def eyes(draw, cx, cy, spread, r, fill):
    disc(draw, cx - spread, cy, r, fill=fill)
    disc(draw, cx + spread, cy, r, fill=fill)


def emblem_google(draw, s, p):
    letters(draw, s / 2, s / 2, int(s * 0.55), "G", WHITE)


def emblem_osu(draw, s, p):
    ring(draw, s / 2, s / 2, s * 0.26, s * 0.07, WHITE)
    disc(draw, s / 2, s / 2, s * 0.09, fill=WHITE)


def emblem_aurora(draw, s, p):
    for i, band in enumerate([(90, 255, 190), (120, 200, 255), (200, 140, 255)]):
        x0 = s * (0.18 + i * 0.16)
        rect(draw, x0, s * 0.14, x0 + s * 0.12, s * 0.86, band, radius=s * 0.06)


def emblem_amethyst(draw, s, p):
    polygon(draw, [(s * 0.5, s * 0.12), (s * 0.82, s * 0.42), (s * 0.68, s * 0.88), (s * 0.32, s * 0.88), (s * 0.18, s * 0.42)], WHITE)
    line(draw, s * 0.5, s * 0.12, s * 0.5, s * 0.88, s * 0.02, (230, 220, 255))
    line(draw, s * 0.18, s * 0.42, s * 0.82, s * 0.42, s * 0.02, (230, 220, 255))


def emblem_sunset(draw, s, p):
    disc(draw, s / 2, s * 0.58, s * 0.24, fill=WHITE)
    rect(draw, s * 0.1, s * 0.58, s * 0.9, s * 0.86, p.bottom, radius=0)
    line(draw, s * 0.1, s * 0.58, s * 0.9, s * 0.58, s * 0.03, WHITE)


def emblem_human(draw, s, p):
    disc(draw, s / 2, s * 0.38, s * 0.16, fill=WHITE)
    rect(draw, s * 0.22, s * 0.62, s * 0.78, s * 0.95, WHITE, radius=s * 0.16)


def emblem_jellyfish(draw, s, p):
    disc(draw, s / 2, s * 0.4, s * 0.28, fill=WHITE)
    rect(draw, s * 0.22, s * 0.4, s * 0.78, s * 0.5, WHITE)
    for x in (0.3, 0.5, 0.7):
        arc(draw, s * x, s * 0.75, s * 0.1, 0, 180, s * 0.03, WHITE)


def emblem_space(draw, s, p):
    star(draw, s * 0.25, s * 0.25, s * 0.06, 4, 0.3, WHITE)
    star(draw, s * 0.78, s * 0.2, s * 0.04, 4, 0.3, WHITE)
    star(draw, s * 0.8, s * 0.75, s * 0.05, 4, 0.3, WHITE)
    disc(draw, s * 0.5, s * 0.6, s * 0.22, fill=WHITE)
    disc(draw, s * 0.44, s * 0.54, s * 0.06, fill=(190, 190, 190))
    disc(draw, s * 0.8, s * 0.42, s * 0.06, fill=WHITE)


def emblem_cyberpunk(draw, s, p):
    accent = (255, 60, 160)
    for i, (x, h) in enumerate([(0.18, 0.35), (0.36, 0.6), (0.54, 0.45), (0.72, 0.7)]):
        rect(draw, s * x, s * (1 - h) - s * 0.08, s * x + s * 0.14, s * 0.9, WHITE if i % 2 == 0 else accent, radius=s * 0.01)
    rect(draw, s * 0.1, s * 0.9, s * 0.9, s * 0.95, accent)


def emblem_nasa(draw, s, p):
    disc(draw, s / 2, s / 2, s * 0.18, fill=WHITE)
    arc(draw, s / 2, s / 2, s * 0.36, -30, 210, s * 0.03, WHITE)
    disc(draw, s * 0.78, s * 0.32, s * 0.07, fill=WHITE)


def emblem_xp(draw, s, p):
    letters(draw, s / 2, s / 2, int(s * 0.5), "XP", WHITE)


def emblem_psychosis(draw, s, p):
    spiral(draw, s / 2, s / 2, s * 0.34, 3.5, s * 0.05, WHITE)


def emblem_fish(draw, s, p):
    draw.ellipse([s * 0.1, s * 0.32, s * 0.66, s * 0.68], fill=WHITE)
    polygon(draw, [(s * 0.62, s * 0.5), (s * 0.86, s * 0.32), (s * 0.86, s * 0.68)], WHITE)
    disc(draw, s * 0.26, s * 0.46, s * 0.045, fill=(60, 60, 60))


def emblem_ice_age(draw, s, p):
    rect(draw, s * 0.22, s * 0.22, s * 0.78, s * 0.78, WHITE, radius=s * 0.12)
    rect(draw, s * 0.32, s * 0.32, s * 0.68, s * 0.68, (150, 220, 255), radius=s * 0.06)
    line(draw, s * 0.34, s * 0.32, s * 0.5, s * 0.22, s * 0.03, WHITE)


def emblem_nyan_cat(draw, s, p):
    rect(draw, s * 0.18, s * 0.3, s * 0.72, s * 0.72, WHITE, radius=s * 0.06)
    rect(draw, s * 0.72, s * 0.36, s * 0.86, s * 0.56, WHITE, radius=s * 0.04)
    eyes(draw, s * 0.4, s * 0.46, s * 0.11, s * 0.05, (40, 40, 40))
    for i in range(4):
        x0 = s * 0.02 + s * 0.09 * i
        rect(draw, x0, s * 0.86, x0 + s * 0.04, s * 0.92, (255, 200 - i * 25, 220))


def emblem_flappy(draw, s, p):
    accent = (120, 220, 90)
    rect(draw, s * 0.28, 0, s * 0.62, s * 0.34, accent, radius=s * 0.02)
    rect(draw, s * 0.28, s * 0.66, s * 0.62, s, accent, radius=s * 0.02)
    rect(draw, s * 0.24, s * 0.3, s * 0.66, s * 0.38, WHITE, radius=s * 0.02)
    rect(draw, s * 0.24, s * 0.62, s * 0.66, s * 0.7, WHITE, radius=s * 0.02)
    disc(draw, s * 0.76, s * 0.5, s * 0.09, fill=WHITE)


def emblem_invincible(draw, s, p):
    polygon(draw, [(s * 0.5, s * 0.14), (s * 0.82, s * 0.26), (s * 0.78, s * 0.6), (s * 0.5, s * 0.88), (s * 0.22, s * 0.6), (s * 0.18, s * 0.26)], WHITE)
    polygon(draw, [(s * 0.5, s * 0.26), (s * 0.7, s * 0.34), (s * 0.66, s * 0.56), (s * 0.5, s * 0.72), (s * 0.34, s * 0.56), (s * 0.3, s * 0.34)], p.bottom)


def emblem_sponge(draw, s, p):
    rect(draw, s * 0.2, s * 0.2, s * 0.8, s * 0.8, WHITE, radius=s * 0.1)
    for cx, cy in [(0.32, 0.35), (0.6, 0.28), (0.42, 0.6), (0.68, 0.62), (0.3, 0.72)]:
        disc(draw, s * cx, s * cy, s * 0.05, fill=(255, 220, 60))


def emblem_hamster(draw, s, p):
    disc(draw, s * 0.28, s * 0.3, s * 0.12, fill=WHITE)
    disc(draw, s * 0.72, s * 0.3, s * 0.12, fill=WHITE)
    disc(draw, s / 2, s * 0.55, s * 0.3, fill=WHITE)
    eyes(draw, s * 0.5, s * 0.52, s * 0.16, s * 0.06, (90, 60, 40))
    disc(draw, s * 0.5, s * 0.64, s * 0.05, fill=(255, 170, 190))


def emblem_frog(draw, s, p):
    disc(draw, s * 0.35, s * 0.38, s * 0.16, fill=WHITE)
    disc(draw, s * 0.65, s * 0.38, s * 0.16, fill=WHITE)
    disc(draw, s * 0.35, s * 0.38, s * 0.08, fill=(40, 40, 40))
    disc(draw, s * 0.65, s * 0.38, s * 0.08, fill=(40, 40, 40))
    line(draw, s * 0.38, s * 0.68, s * 0.62, s * 0.68, s * 0.03, WHITE)


def emblem_guitar(draw, s, p):
    disc(draw, s * 0.44, s * 0.66, s * 0.24, fill=WHITE)
    disc(draw, s * 0.44, s * 0.66, s * 0.09, fill=(60, 40, 30))
    line(draw, s * 0.6, s * 0.5, s * 0.84, s * 0.16, s * 0.06, WHITE)
    rect(draw, s * 0.82, s * 0.08, s * 0.9, s * 0.2, WHITE, radius=s * 0.02)


def emblem_candy(draw, s, p):
    disc(draw, s / 2, s / 2, s * 0.22, fill=WHITE)
    disc(draw, s * 0.45, s * 0.45, s * 0.06, fill=(255, 150, 190))
    polygon(draw, [(s * 0.2, s * 0.5), (s * 0.06, s * 0.36), (s * 0.08, s * 0.62)], WHITE)
    polygon(draw, [(s * 0.8, s * 0.5), (s * 0.94, s * 0.36), (s * 0.92, s * 0.62)], WHITE)


def emblem_avatar(draw, s, p):
    rect(draw, s * 0.2, s * 0.16, s * 0.8, s * 0.84, WHITE, radius=s * 0.1)
    disc(draw, s * 0.5, s * 0.42, s * 0.11, fill=(90, 150, 240))
    rect(draw, s * 0.32, s * 0.6, s * 0.68, s * 0.78, (90, 150, 240), radius=s * 0.08)


def emblem_echpochmak(draw, s, p):
    polygon(draw, [(s * 0.5, s * 0.16), (s * 0.86, s * 0.84), (s * 0.14, s * 0.84)], WHITE)
    polygon(draw, [(s * 0.5, s * 0.4), (s * 0.7, s * 0.78), (s * 0.3, s * 0.78)], (255, 220, 170))
    disc(draw, s * 0.5, s * 0.55, s * 0.06, fill=(190, 90, 90))


def emblem_mole(draw, s, p):
    polygon(draw, [(s * 0.18, s * 0.86), (s * 0.36, s * 0.42), (s * 0.64, s * 0.42), (s * 0.82, s * 0.86)], WHITE)
    eyes(draw, s * 0.5, s * 0.6, s * 0.06, s * 0.045, (60, 40, 30))
    disc(draw, s * 0.5, s * 0.72, s * 0.05, fill=(255, 160, 160))


def emblem_editor(draw, s, p):
    line(draw, s * 0.28, s * 0.72, s * 0.62, s * 0.38, s * 0.09, WHITE)
    polygon(draw, [(s * 0.24, s * 0.76), (s * 0.32, s * 0.74), (s * 0.26, s * 0.66)], WHITE)
    line(draw, s * 0.58, s * 0.3, s * 0.7, s * 0.18, s * 0.05, WHITE)


def emblem_orbit(draw, s, p):
    disc(draw, s / 2, s / 2, s * 0.16, fill=WHITE)
    ring(draw, s / 2, s / 2, s * 0.3, s * 0.03, WHITE)
    disc(draw, s * 0.78, s * 0.36, s * 0.05, fill=WHITE)


def emblem_monet(draw, s, p):
    palette = [(66, 133, 244), (234, 67, 53), (251, 188, 5), (52, 168, 83)]
    for (cx, cy), base in zip([(0.38, 0.38), (0.62, 0.38), (0.38, 0.62), (0.62, 0.62)], palette):
        disc(draw, s * cx, s * cy, s * 0.15, fill=base)


def emblem_winter(draw, s, p):
    snowflake(draw, s / 2, s / 2, s * 0.34, s * 0.03, WHITE)


def emblem_sus(draw, s, p):
    rect(draw, s * 0.28, s * 0.26, s * 0.66, s * 0.82, WHITE, radius=s * 0.12)
    rect(draw, s * 0.56, s * 0.34, s * 0.84, s * 0.5, WHITE, radius=s * 0.06)
    rect(draw, s * 0.66, s * 0.36, s * 0.8, s * 0.46, (120, 200, 255), radius=s * 0.04)
    rect(draw, s * 0.3, s * 0.78, s * 0.44, s * 0.9, WHITE, radius=s * 0.04)


VARIANTS = [
    Variant("Google", "3C8CE7", "1A56C4", emblem_google),
    Variant("Osu", "FF7CA0", "D6316C", emblem_osu),
    Variant("Aurora", "16324F", "0B1220", emblem_aurora),
    Variant("Amethyst", "7C4DFF", "3A1E8C", emblem_amethyst),
    Variant("Sunset", "FF7E5F", "FEB47B", emblem_sunset),
    Variant("Human", "6A5AE0", "3A2E8C", emblem_human),
    Variant("Jellyfish", "8E44AD", "2C1A47", emblem_jellyfish),
    Variant("Space", "0B1D3A", "02040A", emblem_space),
    Variant("Cyberpunk", "0F0E2E", "1E0F3C", emblem_cyberpunk),
    Variant("Nasa", "0B3D91", "04071E", emblem_nasa),
    Variant("Xp", "4A55A2", "20255A", emblem_xp),
    Variant("Psychosis", "8A2BE2", "FF3E6C", emblem_psychosis),
    Variant("Fish", "1FA9C9", "0E5D77", emblem_fish),
    Variant("IceAge", "9AD0EC", "2E6E9E", emblem_ice_age),
    Variant("NyanCat", "2D2D4E", "12122A", emblem_nyan_cat),
    Variant("Flappy", "E8F5E0", "9CC27E", emblem_flappy),
    Variant("Invincible", "2E7D6B", "0E3D33", emblem_invincible),
    Variant("Sponge", "FFD54F", "F4A82B", emblem_sponge),
    Variant("Hamster", "E7B98A", "B57A46", emblem_hamster),
    Variant("Frog", "4CAF50", "1B5E20", emblem_frog),
    Variant("Guitar", "C86A2E", "6B3410", emblem_guitar),
    Variant("Candy", "FF9AC2", "E2558A", emblem_candy),
    Variant("Avatar", "1976D2", "0B3F70", emblem_avatar),
    Variant("Echpochmak", "D9905F", "8C4F22", emblem_echpochmak),
    Variant("Mole", "6D4C41", "2E1B14", emblem_mole),
    Variant("Editor", "546E7A", "263238", emblem_editor),
    Variant("Orbit", "3B1E54", "120B1C", emblem_orbit),
    Variant("Monet", "E9F0FF", "BCCFFF", emblem_monet),
    Variant("Winter", "1E4E8C", "0A1F3C", emblem_winter),
    Variant("Sus", "C22B2B", "5E0F0F", emblem_sus),
]


def render(size, variant, notification):
    canvas = size * SUPER
    if notification:
        image = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        variant.emblem(draw, canvas, variant.palette)
        return image.resize((size, size), Image.LANCZOS)
    image = gradient(canvas, variant.palette)
    draw = ImageDraw.Draw(image)
    variant.emblem(draw, canvas, variant.palette)
    return image.resize((size, size), Image.LANCZOS)


def main():
    parser = argparse.ArgumentParser(description="Generate exteraGram alternate app icon sets.")
    parser.add_argument("--output", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Telegram", "Telegram-iOS"))
    args = parser.parse_args()

    for variant in VARIANTS:
        out_dir = os.path.join(args.output, f"Extera{variant.name}.alticon")
        os.makedirs(out_dir, exist_ok=True)
        for file_pattern, size in BG_FILES + NOTIF_FILES:
            notification = "NotificationIcon" in file_pattern
            path = os.path.join(out_dir, file_pattern.format(name=f"Extera{variant.name}") + ".png")
            render(size, variant, notification).save(path)


if __name__ == "__main__":
    main()
