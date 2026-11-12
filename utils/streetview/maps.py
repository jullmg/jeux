"""Static maps of the pictures, for an AI agent (or a person) who can look at a PNG but not at index.html.

One map per street or range: OpenStreetMap tiles with, for every picture, a blue dot where the camera stood,
a line to the red dot on the facade it looks at, and that facade's civic number. North is up.
Needs Pillow (pip install pillow); without it capture.py skips the maps.
"""

from __future__ import annotations

import math
import urllib.request
from pathlib import Path

try:
	from PIL import Image, ImageDraw, ImageFont
except ImportError:  # the maps are optional
	Image = None

TILE = 256
MAX_SIDE = 1500  # pixels, longest side of a map
PAD = 70  # pixels of margin round the pictures
AGENT = "streetview-reference-tool/1.0 (personal reference maps)"
BLUE, RED = (29, 79, 145), (214, 48, 39)


def available() -> bool:
	return Image is not None


def world(lat: float, lng: float, zoom: int) -> tuple[float, float]:
	"""Web Mercator pixel of a point on the whole-world map at a zoom."""
	size = TILE * 2 ** zoom
	x = (lng + 180) / 360 * size
	y = (1 - math.asinh(math.tan(math.radians(lat))) / math.pi) / 2 * size
	return x, y


def tile(cache: Path, zoom: int, x: int, y: int):
	file = cache / f"{zoom}_{x}_{y}.png"
	if not file.exists():
		cache.mkdir(parents=True, exist_ok=True)
		request = urllib.request.Request(f"https://tile.openstreetmap.org/{zoom}/{x}/{y}.png", headers={"User-Agent": AGENT})
		with urllib.request.urlopen(request, timeout=30) as reply:
			file.write_bytes(reply.read())
	return Image.open(file).convert("RGB")


def font(size: int):
	for name in ("/System/Library/Fonts/Helvetica.ttc", "/Library/Fonts/Arial.ttf", "DejaVuSans-Bold.ttf"):
		try:
			return ImageFont.truetype(name, size)
		except OSError:
			continue
	return ImageFont.load_default(size)


def label(draw, at, text: str, face, fill=(0, 0, 0)) -> None:
	for dx in (-2, -1, 0, 1, 2):
		for dy in (-2, -1, 0, 1, 2):
			draw.text((at[0] + dx, at[1] + dy), text, font=face, fill=(255, 255, 255), anchor="mm")
	draw.text(at, text, font=face, fill=fill, anchor="mm")


def draw_map(shots: list[dict], title: str, cache: Path, out: Path) -> None:
	points = [(s["lat"], s["lng"]) for s in shots] + [(s["target_lat"], s["target_lng"]) for s in shots if "target_lat" in s]
	for zoom in range(19, 13, -1):
		xs, ys = zip(*(world(lat, lng, zoom) for lat, lng in points))
		width, height = max(xs) - min(xs) + 2 * PAD, max(ys) - min(ys) + 2 * PAD
		if max(width, height) <= MAX_SIDE:
			break
	width, height = max(width, 700), max(height, 500)
	left, top = (min(xs) + max(xs)) / 2 - width / 2, (min(ys) + max(ys)) / 2 - height / 2
	canvas = Image.new("RGB", (int(width), int(height)), (240, 238, 230))
	for tx in range(int(left // TILE), int((left + width) // TILE) + 1):
		for ty in range(int(top // TILE), int((top + height) // TILE) + 1):
			canvas.paste(tile(cache, zoom, tx, ty), (int(tx * TILE - left), int(ty * TILE - top)))
	canvas = Image.blend(canvas, Image.new("RGB", canvas.size, (255, 255, 255)), 0.25)  # pale, so the marks stand out
	draw = ImageDraw.Draw(canvas)
	where = lambda lat, lng: (world(lat, lng, zoom)[0] - left, world(lat, lng, zoom)[1] - top)
	small, big = font(15), font(20)

	for shot in shots:  # lines first, so every dot lies over them
		if "target_lat" in shot:
			draw.line([where(shot["lat"], shot["lng"]), where(shot["target_lat"], shot["target_lng"])], fill=(*BLUE, 255), width=1)
	for shot in shots:
		camera = where(shot["lat"], shot["lng"])
		if "target_lat" in shot:
			target = where(shot["target_lat"], shot["target_lng"])
			draw.ellipse([target[0] - 5, target[1] - 5, target[0] + 5, target[1] + 5], fill=RED, outline=(255, 255, 255))
			away = math.hypot(target[0] - camera[0], target[1] - camera[1]) or 1
			spot = (target[0] + (target[0] - camera[0]) / away * 22, target[1] + (target[1] - camera[1]) / away * 22)
			label(draw, spot, shot["number"] if shot["number"].isdigit() else "", small, RED)
		else:  # a view along the street: an arrow from the camera
			heading = math.radians(shot["heading"])
			tip = (camera[0] + math.sin(heading) * 34, camera[1] - math.cos(heading) * 34)
			draw.line([camera, tip], fill=BLUE, width=3)
			label(draw, (tip[0] + math.sin(heading) * 22, tip[1] - math.cos(heading) * 22), "→ " + shot["number"], small, BLUE)
		draw.ellipse([camera[0] - 5, camera[1] - 5, camera[0] + 5, camera[1] + 5], fill=BLUE, outline=(255, 255, 255))

	draw.rectangle([0, 0, 410, 66], fill=(255, 255, 255))
	draw.text((10, 8), title, font=big, fill=(0, 0, 0))
	draw.text((10, 38), "blue = camera, red = facade photographed (civic number). N is up.", font=small, fill=(60, 60, 60))
	cx, cy = width - 28, 34  # north arrow
	draw.polygon([(cx, cy - 22), (cx - 9, cy + 8), (cx, cy + 2), (cx + 9, cy + 8)], fill=(0, 0, 0))
	label(draw, (cx, cy + 20), "N", small)
	draw.text((width - 6, height - 5), "© OpenStreetMap contributors", font=small, fill=(60, 60, 60), anchor="rd")
	out.parent.mkdir(parents=True, exist_ok=True)
	canvas.save(out)


def make(shots: list[dict], folder: Path, slug) -> dict[str, str]:
	"""Draws one map per walk or range (and one of everything) into folder/maps; returns {group: file}."""
	if not available():
		print("No maps: Pillow is missing (pip install pillow).")
		return {}
	groups: dict[str, list[dict]] = {}
	for shot in shots:
		groups.setdefault(shot["walk"] or "Adresses demandées", []).append(shot)
	files: dict[str, str] = {}
	for old in (folder / "maps").glob("*.png"):  # maps of groups that are gone
		if not old.name.startswith("quartier"):
			old.unlink()
	for name, group in groups.items():
		file = Path("maps") / f"{slug(name)}.png"
		draw_map(group, name, folder / "tiles", folder / file)
		files[name] = file.as_posix()
	if len(groups) > 1:
		draw_map(shots, "Tout le quartier", folder / "tiles", folder / "maps" / "tout.png")
		files[""] = "maps/tout.png"
	return files


# ── The neighbourhood ─────────────────────────────────────────────────────────

AREA_ZOOMS = {"quartier.png": 16, "quartier_detail.png": 17}


def _bearing(a, b) -> float:
	la1, lo1, la2, lo2 = map(math.radians, (*a, *b))
	y = math.sin(lo2 - lo1) * math.cos(la2)
	x = math.cos(la1) * math.sin(la2) - math.sin(la1) * math.cos(la2) * math.cos(lo2 - lo1)
	return math.degrees(math.atan2(y, x)) % 360


def area_maps(corners: dict, block: list, home, shots: list[dict], names: dict, folder: Path) -> list[str]:
	"""Zoomed-out maps of the whole neighbourhood, turned so that Montréal's north (the way the streets are named,
	the game's and the town map's north) is up. corners: {"nw", "ne", "se", "sw"} → (lat, lng); block: the four
	corners of Charlotte's block; home: her house; names: {"north", "south", "west", "east"} street names."""
	if not available():
		return []
	# Montréal's north: from the south edge to the north edge of the area.
	up = (_bearing(corners["sw"], corners["nw"]) + _bearing(corners["se"], corners["ne"])) / 2
	made: list[str] = []
	for name, zoom in AREA_ZOOMS.items():
		points = [world(*corners[k], zoom) for k in ("nw", "ne", "se", "sw")]
		xs, ys = [p[0] for p in points], [p[1] for p in points]
		margin = 120
		left, top = min(xs) - margin, min(ys) - margin
		width, height = int(max(xs) - left + margin), int(max(ys) - top + margin)
		canvas = Image.new("RGB", (width, height), (240, 238, 230))
		for tx in range(int(left // TILE), int((left + width) // TILE) + 1):
			for ty in range(int(top // TILE), int((top + height) // TILE) + 1):
				canvas.paste(tile(folder / "tiles", zoom, tx, ty), (int(tx * TILE - left), int(ty * TILE - top)))
		canvas = Image.blend(canvas, Image.new("RGB", canvas.size, (255, 255, 255)), 0.2)
		# Turn it: a point at bearing `up` from the centre must end straight above it.
		turned = canvas.rotate(up, resample=Image.BICUBIC, expand=True, fillcolor=(240, 238, 230))
		c0 = (width / 2, height / 2)
		c1 = (turned.width / 2, turned.height / 2)
		t = math.radians(up)

		def at(lat: float, lng: float) -> tuple[float, float]:
			x, y = world(lat, lng, zoom)
			dx, dy = x - left - c0[0], y - top - c0[1]
			return (c1[0] + dx * math.cos(t) + dy * math.sin(t), c1[1] - dx * math.sin(t) + dy * math.cos(t))

		quad = [at(*corners[k]) for k in ("nw", "ne", "se", "sw")]
		pad = 90
		box = (int(min(p[0] for p in quad)) - pad, int(min(p[1] for p in quad)) - pad - 80,  # room for the title
			int(max(p[0] for p in quad)) + pad, int(max(p[1] for p in quad)) + pad)
		image = turned.crop(box)
		shift = lambda p: (p[0] - box[0], p[1] - box[1])
		layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
		draw = ImageDraw.Draw(layer)
		draw.polygon([shift(at(*p)) for p in block], fill=(255, 210, 63, 110), outline=(200, 140, 0, 255), width=3)
		for shot in shots:
			if "target_lat" in shot:
				x, y = shift(at(shot["target_lat"], shot["target_lng"]))
				draw.ellipse([x - 2.5, y - 2.5, x + 2.5, y + 2.5], fill=(*RED, 230))
		draw.line([shift(p) for p in quad + quad[:1]], fill=(*BLUE, 255), width=4)
		image = Image.alpha_composite(image.convert("RGBA"), layer).convert("RGB")
		draw = ImageDraw.Draw(image)
		big, small = font(22 if zoom > 16 else 17), font(15)
		hx, hy = shift(at(*home))
		draw.polygon([(hx + 11 * math.sin(math.radians(a * 36)) * (1 if a % 2 == 0 else 0.45),
			hy - 11 * math.cos(math.radians(a * 36)) * (1 if a % 2 == 0 else 0.45)) for a in range(10)], fill=RED, outline=(255, 255, 255))
		label(draw, (hx, hy - 22), "Chez Charlotte", small, RED)
		edges = {"north": ("nw", "ne"), "south": ("sw", "se"), "west": ("nw", "sw"), "east": ("ne", "se")}
		for side, (a, b) in edges.items():
			pa, pb = shift(at(*corners[a])), shift(at(*corners[b]))
			mid = ((pa[0] + pb[0]) / 2, (pa[1] + pb[1]) / 2)
			out = {"north": (0, -34), "south": (0, 34), "west": (-34, 0), "east": (34, 0)}[side]
			text = names[side]
			if side in ("west", "east"):  # written up along the edge
				face = big
				box_w = int(draw.textlength(text, font=face)) + 16
				strip = Image.new("RGBA", (box_w, 34), (0, 0, 0, 0))
				ImageDraw.Draw(strip).text((box_w / 2, 17), text, font=face, fill=BLUE, anchor="mm",
					stroke_width=3, stroke_fill=(255, 255, 255))
				strip = strip.rotate(90, expand=True)
				image.paste(strip, (int(mid[0] + out[0] - strip.width / 2), int(mid[1] - strip.height / 2)), strip)
			else:
				label(draw, (mid[0] + out[0], mid[1] + out[1]), text, big, BLUE)
		draw = ImageDraw.Draw(image)
		draw.rectangle([0, 0, 560, 74], fill=(255, 255, 255))
		draw.text((10, 8), "Le quartier de Charlotte", font=big, fill=(0, 0, 0))
		draw.text((10, 40), "Montréal north is up (as the streets are named, like the game). Yellow: her block.", font=small, fill=(60, 60, 60))
		draw.text((10, 57), "Blue: the area. Red dots: facades photographed. Star: her house.", font=small, fill=(60, 60, 60))
		w = image.width
		draw.polygon([(w - 40, 14), (w - 50, 44), (w - 40, 38), (w - 30, 44)], fill=(0, 0, 0))
		label(draw, (w - 40, 56), "N (Mtl)", small)
		tn = math.radians(-up)  # true north, for reference
		tip = (w - 130 + 18 * math.sin(tn), 30 - 18 * math.cos(tn))
		draw.line([(w - 130, 30), tip], fill=(120, 120, 120), width=3)
		draw.ellipse([tip[0] - 3, tip[1] - 3, tip[0] + 3, tip[1] + 3], fill=(120, 120, 120))
		label(draw, (w - 130, 62), "N vrai", small, (120, 120, 120))
		draw.text((image.width - 6, image.height - 5), "© OpenStreetMap contributors", font=small, fill=(60, 60, 60), anchor="rd")
		(folder / "maps").mkdir(parents=True, exist_ok=True)
		image.save(folder / "maps" / name)
		made.append(f"maps/{name}")
	return made
