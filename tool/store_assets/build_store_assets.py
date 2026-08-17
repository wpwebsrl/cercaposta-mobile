#!/usr/bin/env python3
"""Compose and validate localized App Store screenshots.

The Flutter capture job writes deterministic, data-free application frames to
``store_assets/raw``. This script gives them a branded marketing treatment and
emits upload-ready RGB PNGs at Apple's accepted iPhone 6.9-inch and iPad
13-inch sizes. It deliberately performs no network access.
"""

from __future__ import annotations

import argparse
import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFilter, ImageFont


@dataclass(frozen=True)
class Device:
    raw_name: str
    output_name: str
    size: tuple[int, int]
    device_top: int
    max_screen: tuple[int, int]
    frame_radius: int
    frame_width: int
    title_size: int
    subtitle_size: int


@dataclass(frozen=True)
class Scene:
    slug: str
    title: dict[str, str]
    subtitle: dict[str, str]
    colors: tuple[str, str]
    accent: str


DEVICES = (
    Device(
        raw_name="iphone",
        output_name="iphone-6.9",
        size=(1320, 2868),
        device_top=520,
        max_screen=(1060, 2300),
        frame_radius=76,
        frame_width=14,
        title_size=86,
        subtitle_size=40,
    ),
    Device(
        raw_name="iphone",
        output_name="iphone-6.5",
        size=(1284, 2778),
        device_top=504,
        max_screen=(1030, 2228),
        frame_radius=74,
        frame_width=14,
        title_size=84,
        subtitle_size=39,
    ),
    Device(
        raw_name="ipad",
        output_name="ipad-13",
        size=(2064, 2752),
        device_top=370,
        max_screen=(1780, 2320),
        frame_radius=48,
        frame_width=14,
        title_size=76,
        subtitle_size=36,
    ),
)

SCENES = (
    Scene(
        slug="01_search",
        title={"it": "Trova ogni email\nin un lampo", "en": "Find every email\nin a flash"},
        subtitle={
            "it": "Parole, mittenti, date e significato: tutto in una ricerca.",
            "en": "Words, senders, dates, and meaning—all in one search.",
        },
        colors=("#EAFBF4", "#DCE8FF"),
        accent="#168A61",
    ),
    Scene(
        slug="02_chat",
        title={"it": "Chiedi al tuo archivio", "en": "Ask your archive"},
        subtitle={
            "it": "L’AI risponde indicando sempre le email da cui provengono le informazioni.",
            "en": "AI answers with clear references to the original emails.",
        },
        colors=("#EEEAFE", "#E5F7F0"),
        accent="#4F46E5",
    ),
    Scene(
        slug="03_email",
        title={
            "it": "Email e allegati,\nfinalmente insieme",
            "en": "Emails and attachments,\nfinally together",
        },
        subtitle={
            "it": "Leggi messaggi, consulta documenti e ritrova ogni dettaglio.",
            "en": "Read messages, open documents, and retrieve every detail.",
        },
        colors=("#E9F4FF", "#E8FAF2"),
        accent="#0B66C3",
    ),
    Scene(
        slug="04_followups",
        title={"it": "Non perdere una risposta", "en": "Never miss a reply"},
        subtitle={
            "it": "Sai subito chi deve rispondere e quali messaggi richiedono attenzione.",
            "en": "See who owes a reply and which messages need your attention.",
        },
        colors=("#FFF4DA", "#E7F8EF"),
        accent="#B66A00",
    ),
    Scene(
        slug="05_security",
        title={"it": "Accedi in modo sicuro", "en": "Secure access, your way"},
        subtitle={
            "it": "Password, passkey, Google, Apple e Face ID: scegli il metodo che preferisci.",
            "en": "Password, passkey, Google, Apple, and Face ID—choose what works for you.",
        },
        colors=("#E9F0FF", "#E8FAF2"),
        accent="#4038CE",
    ),
)


def _hex(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[index : index + 2], 16) for index in (0, 2, 4))


def _mix(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(round(a[index] * (1 - t) + b[index] * t) for index in range(3))


def _gradient(size: tuple[int, int], start: str, end: str) -> Image.Image:
    width, height = size
    top = _hex(start)
    bottom = _hex(end)
    strip = Image.new("RGB", (1, height))
    strip.putdata(
        [_mix(top, bottom, y / max(height - 1, 1)) for y in range(height)]
    )
    return strip.resize((width, height), Image.Resampling.BILINEAR)


def _font_candidates(bold: bool) -> Iterable[Path]:
    windows = Path(os.environ.get("WINDIR", "C:/Windows")) / "Fonts"
    if bold:
        names = (
            "/System/Library/Fonts/SFNS.ttf",
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
            "/System/Library/Fonts/Helvetica.ttc",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
            str(windows / "segoeuib.ttf"),
            str(windows / "arialbd.ttf"),
        )
    else:
        names = (
            "/System/Library/Fonts/SFNS.ttf",
            "/System/Library/Fonts/Supplemental/Arial.ttf",
            "/System/Library/Fonts/Helvetica.ttc",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
            str(windows / "segoeui.ttf"),
            str(windows / "arial.ttf"),
        )
    return (Path(name) for name in names)


def _font(size: int, *, bold: bool = False) -> ImageFont.FreeTypeFont:
    for path in _font_candidates(bold):
        if path.exists():
            return ImageFont.truetype(str(path), size=size, index=0)
    raise RuntimeError("No suitable TrueType font found on this runner")


def _rounded(image: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, image.width - 1, image.height - 1),
        radius=radius,
        fill=255,
    )
    rounded = Image.new("RGBA", image.size, (0, 0, 0, 0))
    rounded.paste(image.convert("RGBA"), (0, 0), mask)
    return rounded


def _fit(image: Image.Image, bounds: tuple[int, int]) -> Image.Image:
    max_width, max_height = bounds
    scale = min(max_width / image.width, max_height / image.height)
    size = (round(image.width * scale), round(image.height * scale))
    return image.resize(size, Image.Resampling.LANCZOS)


def _wrap(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont, width: int) -> str:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = f"{current} {word}".strip()
        if current and draw.textbbox((0, 0), candidate, font=font)[2] > width:
            lines.append(current)
            current = word
        else:
            current = candidate
    if current:
        lines.append(current)
    return "\n".join(lines)


def _centered_text(
    draw: ImageDraw.ImageDraw,
    canvas_width: int,
    y: int,
    text: str,
    font: ImageFont.FreeTypeFont,
    fill: str,
    *,
    spacing: int,
) -> int:
    box = draw.multiline_textbbox((0, 0), text, font=font, spacing=spacing, align="center")
    width = box[2] - box[0]
    height = box[3] - box[1]
    draw.multiline_text(
        ((canvas_width - width) / 2, y - box[1]),
        text,
        font=font,
        fill=fill,
        spacing=spacing,
        align="center",
    )
    return y + height


def _decorate(canvas: Image.Image, scene: Scene, device: Device) -> None:
    width, height = canvas.size
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    accent = _hex(scene.accent)
    alpha = 34
    diameter = round(width * (0.62 if device.raw_name == "iphone" else 0.38))
    draw.ellipse(
        (-diameter // 3, height - diameter // 2, diameter * 2 // 3, height + diameter // 2),
        fill=(*accent, alpha),
    )
    draw.ellipse(
        (width - diameter // 2, -diameter // 3, width + diameter // 2, diameter * 2 // 3),
        fill=(79, 70, 229, 24),
    )
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=max(40, width // 22)))
    canvas.paste(Image.alpha_composite(canvas.convert("RGBA"), overlay).convert("RGB"))


def _brand_badge(canvas: Image.Image, icon: Image.Image, device: Device) -> None:
    width, _ = canvas.size
    badge_height = 78 if device.raw_name == "iphone" else 62
    icon_size = badge_height - 12
    font = _font(34 if device.raw_name == "iphone" else 28, bold=True)
    text = "CercaPosta"
    scratch = ImageDraw.Draw(canvas)
    text_width = scratch.textbbox((0, 0), text, font=font)[2]
    badge_width = icon_size + text_width + 46
    x = (width - badge_width) // 2
    y = 52 if device.raw_name == "iphone" else 30
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle(
        (x, y, x + badge_width, y + badge_height),
        radius=badge_height // 2,
        fill=(255, 255, 255),
        outline=(255, 255, 255),
        width=2,
    )
    icon_small = _rounded(icon.resize((icon_size, icon_size), Image.Resampling.LANCZOS), icon_size // 5)
    canvas.paste(icon_small, (x + 7, y + 6), icon_small)
    draw.text(
        (x + icon_size + 22, y + (badge_height - font.size) // 2 - 3),
        text,
        font=font,
        fill="#15231E",
    )


def _place_device(canvas: Image.Image, raw: Image.Image, device: Device) -> None:
    screen = _fit(raw.convert("RGB"), device.max_screen)
    border = device.frame_width
    outer_size = (screen.width + border * 2, screen.height + border * 2)
    x = (canvas.width - outer_size[0]) // 2
    y = device.device_top

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (x - 8, y + 18, x + outer_size[0] + 8, y + outer_size[1] + 32),
        radius=device.frame_radius + border,
        fill=(20, 35, 31, 90),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=30))
    canvas.paste(Image.alpha_composite(canvas.convert("RGBA"), shadow).convert("RGB"))

    frame = Image.new("RGBA", outer_size, (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle(
        (0, 0, outer_size[0] - 1, outer_size[1] - 1),
        radius=device.frame_radius + border,
        fill="#17201E",
    )
    rounded_screen = _rounded(screen, device.frame_radius)
    frame.paste(rounded_screen, (border, border), rounded_screen)
    canvas.paste(frame, (x, y), frame)


def compose(raw: Image.Image, icon: Image.Image, scene: Scene, locale: str, device: Device) -> Image.Image:
    canvas = _gradient(device.size, *scene.colors)
    _decorate(canvas, scene, device)
    _brand_badge(canvas, icon, device)
    draw = ImageDraw.Draw(canvas)

    title_font = _font(device.title_size, bold=True)
    subtitle_font = _font(device.subtitle_size)
    title_y = 152 if device.raw_name == "iphone" else 108
    title_end = _centered_text(
        draw,
        canvas.width,
        title_y,
        scene.title[locale],
        title_font,
        "#101C18",
        spacing=2,
    )
    subtitle = _wrap(
        draw,
        scene.subtitle[locale],
        subtitle_font,
        round(canvas.width * 0.82),
    )
    _centered_text(
        draw,
        canvas.width,
        title_end + (20 if device.raw_name == "iphone" else 12),
        subtitle,
        subtitle_font,
        "#40504A",
        spacing=8,
    )
    _place_device(canvas, raw, device)
    return canvas.convert("RGB")


def _contact_sheet(files: list[Path], destination: Path, label: str) -> None:
    previews: list[Image.Image] = []
    for path in files:
        image = Image.open(path).convert("RGB")
        preview_height = 520
        preview_width = round(image.width * preview_height / image.height)
        previews.append(image.resize((preview_width, preview_height), Image.Resampling.LANCZOS))
    gap = 24
    margin = 36
    label_font = _font(34, bold=True)
    width = margin * 2 + sum(image.width for image in previews) + gap * (len(previews) - 1)
    height = 600
    sheet = Image.new("RGB", (width, height), "#F3F5F4")
    draw = ImageDraw.Draw(sheet)
    draw.text((margin, 18), label, font=label_font, fill="#102019")
    x = margin
    for image in previews:
        sheet.paste(image, (x, 68))
        x += image.width + gap
    destination.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(destination, "JPEG", quality=90, optimize=True)


def build(raw_root: Path, output_root: Path, icon_path: Path) -> None:
    icon = Image.open(icon_path).convert("RGB")
    manifest: dict[str, object] = {"locales": {}}
    for locale in ("it", "en"):
        locale_manifest: dict[str, object] = {}
        for device in DEVICES:
            files: list[Path] = []
            entries: list[dict[str, object]] = []
            destination = output_root / locale / device.output_name
            destination.mkdir(parents=True, exist_ok=True)
            for scene in SCENES:
                source = raw_root / locale / device.raw_name / f"{scene.slug}.png"
                if not source.exists():
                    raise FileNotFoundError(f"Missing Flutter capture: {source}")
                output = destination / f"{scene.slug.replace('_', '-')}.png"
                final = compose(Image.open(source), icon, scene, locale, device)
                final.save(output, "PNG", optimize=True)
                files.append(output)
                entries.append(
                    {
                        "file": str(output.relative_to(output_root)).replace("\\", "/"),
                        "title": scene.title[locale].replace("\n", " "),
                        "subtitle": scene.subtitle[locale],
                        "width": final.width,
                        "height": final.height,
                    }
                )
            _contact_sheet(
                files,
                output_root / "review" / f"{locale}-{device.output_name}.jpg",
                f"CercaPosta · {locale.upper()} · {device.output_name}",
            )
            locale_manifest[device.output_name] = entries
        manifest["locales"][locale] = locale_manifest
    (output_root / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def validate(output_root: Path) -> None:
    failures: list[str] = []
    for locale in ("it", "en"):
        for device in DEVICES:
            folder = output_root / locale / device.output_name
            files = sorted(folder.glob("*.png"))
            if len(files) != len(SCENES):
                failures.append(f"{folder}: expected {len(SCENES)} PNGs, found {len(files)}")
            for path in files:
                with Image.open(path) as image:
                    if image.size != device.size:
                        failures.append(f"{path}: {image.size}, expected {device.size}")
                    if image.mode != "RGB":
                        failures.append(f"{path}: mode {image.mode}, expected RGB (no alpha)")
    if failures:
        raise SystemExit("App Store asset validation failed:\n- " + "\n- ".join(failures))
    print(f"Validated {len(SCENES) * len(DEVICES) * 2} upload-ready screenshots")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw", type=Path, default=Path("store_assets/raw"))
    parser.add_argument("--output", type=Path, default=Path("store_assets/output"))
    parser.add_argument("--icon", type=Path, default=Path("assets/icon/app_icon.png"))
    args = parser.parse_args()
    build(args.raw, args.output, args.icon)
    validate(args.output)


if __name__ == "__main__":
    main()
