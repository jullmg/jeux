#!/usr/bin/env python3
"""Street View pictures of the neighbourhood, each with its address and its pin on a map.

Reads places.json, asks Google's official APIs (Street View Static, its free metadata
endpoint, Geocoding) and writes pictures, index.json and index.html (the map).
Standard library only. See README.md.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import sys
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

import maps

HERE = Path(__file__).resolve().parent
DEFAULT_OUT = HERE.parent.parent / "Charlotte" / "reference" / "streetview"

GEOCODE = "https://maps.googleapis.com/maps/api/geocode/json"
SV_IMAGE = "https://maps.googleapis.com/maps/api/streetview"
SV_META = "https://maps.googleapis.com/maps/api/streetview/metadata"

EARTH = 6371000.0
SIZE = "640x640"  # the API's maximum
PANO_RADIUS = 30  # metres: how far from a point on a walk we accept a panorama
BLOCK_MARGIN = 10.0  # metres from a crossing's centre line that a block's buildings start
DETAIL_FOV = 30
GOOGLE = "Google"  # copyright of the pictures taken by Google's own cars
SAME_BUILDING = 4.0  # metres: two civic numbers this close share a facade
FACADE_OFFSET = 14.0  # metres from the camera to the facade it looks at
COMPASS = ["nord", "nord-est", "est", "sud-est", "sud", "sud-ouest", "ouest", "nord-ouest"]


# ── Geometry ──────────────────────────────────────────────────────────────────

def distance(a: tuple[float, float], b: tuple[float, float]) -> float:
	la1, lo1, la2, lo2 = map(math.radians, (*a, *b))
	h = math.sin((la2 - la1) / 2) ** 2 + math.cos(la1) * math.cos(la2) * math.sin((lo2 - lo1) / 2) ** 2
	return 2 * EARTH * math.asin(math.sqrt(h))


def bearing(a: tuple[float, float], b: tuple[float, float]) -> float:
	la1, lo1, la2, lo2 = map(math.radians, (*a, *b))
	y = math.sin(lo2 - lo1) * math.cos(la2)
	x = math.cos(la1) * math.sin(la2) - math.sin(la1) * math.cos(la2) * math.cos(lo2 - lo1)
	return math.degrees(math.atan2(y, x)) % 360


def offset(a: tuple[float, float], heading: float, metres: float) -> tuple[float, float]:
	la1, lo1, h, d = math.radians(a[0]), math.radians(a[1]), math.radians(heading), metres / EARTH
	la2 = math.asin(math.sin(la1) * math.cos(d) + math.cos(la1) * math.sin(d) * math.cos(h))
	lo2 = lo1 + math.atan2(math.sin(h) * math.sin(d) * math.cos(la1), math.cos(d) - math.sin(la1) * math.sin(la2))
	return (math.degrees(la2), math.degrees(lo2))


def project(a: tuple[float, float], b: tuple[float, float], p: tuple[float, float]) -> tuple[float, float]:
	"""Metres of p along the line a→b and to its right (negative = left). Flat maths, fine over a block."""
	k = math.cos(math.radians(a[0])) * 111320.0
	ax, ay, px, py = (b[1] - a[1]) * k, (b[0] - a[0]) * 111320.0, (p[1] - a[1]) * k, (p[0] - a[0]) * 111320.0
	length = math.hypot(ax, ay) or 1.0
	return ((px * ax + py * ay) / length, (px * ay - py * ax) / length)


def between(a: tuple[float, float], b: tuple[float, float], t: float) -> tuple[float, float]:
	return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)  # fine over one block


def compass(heading: float) -> str:
	return COMPASS[int((heading % 360) / 45 + 0.5) % 8]


def slug(text: str) -> str:
	plain = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
	return "-".join("".join(c if c.isalnum() else " " for c in plain.lower()).split())


# ── Google ────────────────────────────────────────────────────────────────────

class Google:
	def __init__(self, key: str, cache_file: Path) -> None:
		self.key = key
		self.cache_file = cache_file
		self.cache: dict = json.loads(cache_file.read_text()) if cache_file.exists() else {}
		self.calls = {"geocode": 0, "metadata": 0, "image": 0}

	def _json(self, kind: str, url: str, params: dict) -> dict:
		query = urllib.parse.urlencode(params)
		cached = f"{url}?{query}"
		if cached in self.cache:
			return self.cache[cached]
		self.calls[kind] += 1
		with urllib.request.urlopen(f"{url}?{query}&key={self.key}", timeout=30) as reply:
			data = json.load(reply)
		if data.get("status") in ("REQUEST_DENIED", "OVER_QUERY_LIMIT", "OVER_DAILY_LIMIT", "INVALID_REQUEST"):
			sys.exit(f"Google refused ({data['status']}): {data.get('error_message', 'no message')}")
		self.cache[cached] = data
		self.cache_file.write_text(json.dumps(self.cache, ensure_ascii=False))
		return data

	def locate(self, query: str) -> dict | None:
		"""An address or an intersection ("A & B, city") → its first geocoding result."""
		results = self._json("geocode", GEOCODE, {"address": query, "language": "fr"}).get("results", [])
		return results[0] if results else None

	def address_at(self, point: tuple[float, float]) -> dict | None:
		"""The civic address nearest a point."""
		where = {"latlng": f"{point[0]:.7f},{point[1]:.7f}", "language": "fr"}
		results = self._json("geocode", GEOCODE, {**where, "result_type": "street_address|premise"}).get("results", [])
		if not results:
			results = self._json("geocode", GEOCODE, where).get("results", [])
		return results[0] if results else None

	def _pano_at(self, point: tuple[float, float], radius: float) -> dict | None:
		data = self._json("metadata", SV_META, {
			"location": f"{point[0]:.7f},{point[1]:.7f}", "radius": int(radius), "source": "outdoor"})
		return data if data.get("status") == "OK" else None

	def panorama(self, point: tuple[float, float], radius: float) -> dict | None:
		"""The nearest panorama taken by Google's own car: {pano_id, location, date, copyright}. Free of charge.

		Street View also serves pictures contributed by others (the city's SIRR pictures, users' photospheres), dark
		and from a different camera: they are refused. When the nearest one is such a picture, the surroundings are
		searched for the nearest Google one."""
		first = self._pano_at(point, radius)
		if first and GOOGLE in first.get("copyright", ""):
			return first
		found: dict[str, dict] = {}
		for metres in (15, 30, 50):
			for heading in range(0, 360, 45):
				pano = self._pano_at(offset(point, heading, metres), 20)
				if pano and GOOGLE in pano.get("copyright", ""):
					found[pano["pano_id"]] = pano
			if found:
				break
		return min(found.values(), key=lambda p: distance(point, (p["location"]["lat"], p["location"]["lng"])), default=None)

	def picture(self, pano: str, heading: float, pitch: float, fov: float, to: Path) -> bool:
		if to.exists():
			return True
		params = {"size": SIZE, "pano": pano, "heading": f"{heading:.1f}", "pitch": f"{pitch:.1f}",
			"fov": f"{fov:.0f}", "return_error_code": "true", "key": self.key}
		self.calls["image"] += 1
		try:
			with urllib.request.urlopen(f"{SV_IMAGE}?{urllib.parse.urlencode(params)}", timeout=60) as reply:
				to.parent.mkdir(parents=True, exist_ok=True)
				to.write_bytes(reply.read())
			return True
		except urllib.error.HTTPError as error:
			print(f"  ! no picture for {to.name}: HTTP {error.code}")
			return False


def spot(result: dict) -> tuple[float, float]:
	where = result["geometry"]["location"]
	return (where["lat"], where["lng"])


def part(result: dict | None, kind: str) -> str:
	for component in (result or {}).get("address_components", []):
		if kind in component["types"]:
			return component["long_name"]
	return ""


def resolve(google: Google, place: str | list, city: str) -> tuple[float, float]:
	"""A walk's end: [lat, lng], or an intersection / address to geocode."""
	if isinstance(place, list):
		return (float(place[0]), float(place[1]))
	found = google.locate(f"{place}, {city}")
	if not found:
		sys.exit(f"Cannot find \"{place}\": give it as [lat, lng] in places.json instead.")
	return spot(found)


# ── Shots ─────────────────────────────────────────────────────────────────────

class Capture:
	def __init__(self, google: Google, out: Path, options: argparse.Namespace) -> None:
		self.google = google
		self.out = out
		self.options = options
		self.shots: list[dict] = []

	def shoot(self, pano: dict, heading: float, street: str, number: str, mode: str, side: str,
			address: str = "", approx: bool = False, walk: dict | None = None, along: float = 0.0,
			target: tuple[float, float] | None = None) -> None:
		at = (pano["location"]["lat"], pano["location"]["lng"])
		folder = slug(street) or "divers"
		name = f"{number or 'sn'}_{folder}_{side}_{pano['pano_id'][:8]}"
		file = Path(folder) / f"{name}.jpg"
		if not self.google.picture(pano["pano_id"], heading, self.options.pitch, self.options.fov, self.out / file):
			return
		details: list[str] = []
		if self.options.detail and side != "along":
			# Six close-ups across and up the facade, for the bricks, doors and cornices. The API gives 640 px at most
			# per picture, so detail comes from a narrow view: 30 degrees is three times the pixels per degree of the 90.
			for row, pitch in enumerate((4.0, 26.0)):
				for column, turn in enumerate((-14.0, 0.0, 14.0)):
					close = Path(folder) / "detail" / f"{name}_r{row}c{column}.jpg"
					if self.google.picture(pano["pano_id"], (heading + turn) % 360, pitch, DETAIL_FOV, self.out / close):
						details.append(close.as_posix())
		self.shots.append({
			"file": file.as_posix(), "details": details, "street": street, "number": number,
			"address": address or f"{number} {street}".strip(), "approx": approx, "mode": mode, "side": side,
			"lat": round(at[0], 7), "lng": round(at[1], 7), "heading": round(heading, 1),
			"looking": compass(heading), "pano": pano["pano_id"], "date": pano.get("date", ""), "copyright": pano.get("copyright", ""),
			# For whoever draws the game from these: which walk, how far along it, which scene, our block or not.
			"walk": (walk or {}).get("name", ""), "along_m": round(along), "game": (walk or {}).get("game", ""),
			"our_side": bool(walk) and side == walk.get("our_side"),
			**({"target_lat": round(target[0], 7), "target_lng": round(target[1], 7)} if target else {}),
			"maps": "https://www.google.com/maps/@?api=1&map_action=pano&pano=%s&heading=%.0f" % (pano["pano_id"], heading),
		})
		print(f"  {file}  ({self.shots[-1]['address']}, vers le {compass(heading)}, {pano.get('date', '?')})")

	def address(self, query: str, city: str) -> None:
		"""One picture of a given address, the camera turned toward it."""
		found = self.google.locate(f"{query}, {city}")
		if not found:
			print(f"  ! address not found: {query}")
			return
		target = spot(found)
		pano = self.google.panorama(target, 60)
		if not pano:
			print(f"  ! no Street View near {query}")
			return
		at = (pano["location"]["lat"], pano["location"]["lng"])
		street = part(found, "route") or query
		self.shoot(pano, bearing(at, target), street, part(found, "street_number"), "address", "face",
			found.get("formatted_address", query), bool(found.get("partial_match")), target=target)

	def buildings(self, walk: dict, city: str) -> None:
		"""Every building of a street between two civic numbers: each number is looked up and photographed from the
		nearest panorama, the camera turned to its door. Numbers that don't exist (Google would invent a
		position) and numbers on the same facade as the one before are skipped."""
		low, high = walk["numbers"]
		parity = {"even": 0, "pair": 0, "odd": 1, "impair": 1}.get(walk.get("parity", ""))
		print(f"{walk['name']}")
		kept: list[tuple[float, float]] = []
		corners = None
		if walk.get("between"):
			# Only this block: from one cross street to the next, in that order (the game's left to right).
			corners = [resolve(self.google, f"{walk['street']} & {cross}", city) for cross in walk["between"]]
		found_at: list[tuple[int, dict, tuple[float, float], float, float]] = []
		for number in range(low, high + 1):
			if parity is not None and number % 2 != parity:
				continue
			found = self.google.locate(f"{number} {walk['street']}, {city}")
			if not found or part(found, "street_number") != str(number) or slug(walk["street"]) not in slug(part(found, "route")):
				continue
			target = spot(found)
			along, right = 0.0, 0.0
			if corners:
				along, right = project(corners[0], corners[1], target)
				# Inside the block, between the two crossings' curbs; the geocoder sometimes puts a number on the
				# far side of a street or on the next block, so also keep to the facades of one side, close to the road.
				if not BLOCK_MARGIN <= along <= distance(*corners) - BLOCK_MARGIN or not 8 <= abs(right) <= 32:
					continue
			found_at.append((number, found, target, along, right))
		if corners and found_at:
			side = sorted(f[4] for f in found_at)[len(found_at) // 2] > 0
			found_at = [f for f in found_at if (f[4] > 0) == side]
		for number, found, target, along, right in found_at:
			if any(distance(target, other) < SAME_BUILDING for other in kept):
				continue
			pano = self.google.panorama(target, 60)
			if not pano:
				print(f"  ! no Street View near {number}")
				continue
			kept.append(target)
			at = (pano["location"]["lat"], pano["location"]["lng"])
			self.shoot(pano, bearing(at, target), part(found, "route") or walk["street"], str(number), "range",
				("right" if right > 0 else "left") if corners else "face",
				found.get("formatted_address", ""), False, walk, max(along, 0), target)

	def walk(self, walk: dict, city: str) -> None:
		"""Every panorama along a street, looking at both sides (and down the street at its ends)."""
		if "numbers" in walk:
			return self.buildings(walk, city)
		start, end = resolve(self.google, walk["from"], city), resolve(self.google, walk["to"], city)
		step = float(walk.get("step", self.options.step))
		length, along = distance(start, end), bearing(start, end)
		if length < 20:
			sys.exit(f"{walk['name']}: its two ends are {length:.0f} m apart; give them as [lat, lng] in places.json.")
		print(f"{walk['name']}: {length:.0f} m, vers le {compass(along)}")
		panos: list[dict] = []
		for i in range(int(length / step) + 1):
			pano = self.google.panorama(between(start, end, min(1.0, i * step / length)), max(step, PANO_RADIUS))
			if pano and pano["pano_id"] not in [p["pano_id"] for p in panos]:
				panos.append(pano)
		if not panos:
			print("  ! no Street View here")
			return
		sides = {"left": along - 90, "right": along + 90}
		for pano in panos:
			at = (pano["location"]["lat"], pano["location"]["lng"])
			for side in walk.get("sides", ["left", "right"]):
				heading = sides[side] % 360
				seen = self.google.address_at(offset(at, heading, FACADE_OFFSET))
				self.shoot(pano, heading, part(seen, "route") or walk["name"], part(seen, "street_number"),
					"walk", side, (seen or {}).get("formatted_address", ""), True, walk, distance(start, at),
					offset(at, heading, FACADE_OFFSET))
		if walk.get("ends", True):
			self.shoot(panos[0], along, walk["name"], "debut", "walk", "along", f"{walk['name']}, depuis {walk['from']}", False, walk)
			self.shoot(panos[-1], (along + 180) % 360, walk["name"], "fin", "walk", "along", f"{walk['name']}, depuis {walk['to']}", False, walk, length)


def range_walk(r: dict) -> dict:
	"""{"street", "from", "to"[, "parity"]}: every building of a street between two civic numbers, as a walk."""
	side = {"even": " (pairs)", "pair": " (pairs)", "odd": " (impairs)", "impair": " (impairs)"}.get(r.get("parity", ""), "")
	return {"ends": False, **r, "name": r.get("name", f"{r['street']} {r['from']}–{r['to']}{side}"),
		"from": f"{r['from']} {r['street']}", "to": f"{r['to']} {r['street']}", "numbers": [int(r["from"]), int(r["to"])]}


# ── Main ──────────────────────────────────────────────────────────────────────

def api_key() -> str:
	key = os.environ.get("GOOGLE_MAPS_API_KEY", "")
	env = HERE / ".env"
	if not key and env.exists():
		for line in env.read_text().splitlines():
			if line.strip().startswith("GOOGLE_MAPS_API_KEY="):
				key = line.split("=", 1)[1].strip().strip("\"'")
	if not key:
		sys.exit("No API key: put GOOGLE_MAPS_API_KEY=… in utils/streetview/.env (see README.md).")
	return key


def area(google: Google, places: dict, out: Path, shots: list[dict]) -> list[str]:
	"""The zoomed-out maps of the neighbourhood named in places.json's "area"."""
	spec, city = places.get("area"), places.get("city", "")
	if not spec or not maps.available():
		return []
	corner = lambda a, b: resolve(google, f"{spec[a]} & {spec[b]}", city)
	corners = {"nw": corner("west", "north"), "ne": corner("east", "north"),
		"se": corner("east", "south"), "sw": corner("west", "south")}
	block = [resolve(google, q, city) for q in spec.get("block", [])]
	home = resolve(google, spec["home"], city) if spec.get("home") else corners["nw"]
	return maps.area_maps(corners, block, home, shots, {k: spec[k] for k in ("north", "south", "west", "east")}, out)


def write_index(out: Path, shots: list[dict], area_made: list[str] | None = None) -> None:
	shots.sort(key=lambda s: (s["walk"] == "", s["walk"], not s["our_side"], s["side"], s["along_m"], s["number"]))
	(out / "index.json").write_text(json.dumps(shots, ensure_ascii=False, indent="\t"))
	page = (HERE / "map_template.html").read_text().replace("/*SHOTS*/[]", json.dumps(shots, ensure_ascii=False))
	(out / "index.html").write_text(page)
	(out / "INDEX.md").write_text(guide(shots, maps.make(shots, out, slug), area_made or []))


def guide(shots: list[dict], maps_made: dict[str, str], area_made: list[str]) -> str:
	"""INDEX.md: the same index written for an AI agent (or a person) who will draw the game from the pictures."""
	lines = (HERE / "index_header.md").read_text().rstrip().splitlines() + [""]
	if area_made:
		lines += ["Maps of the whole neighbourhood, Montréal north up as in the game (Charlotte's block in yellow, her house a star): "
			+ ", ".join(f"`{m}`" for m in area_made) + ". Look at them first to see where a street or a building is.", ""]
	if maps_made.get(""):
		lines += [f"Map of everything: `{maps_made['']}` (look at it first).", ""]
	groups: dict[tuple, list[dict]] = {}
	for shot in shots:
		groups.setdefault((shot["walk"], shot["side"]), []).append(shot)
	walk = None
	for (name, side), group in groups.items():
		if name != walk:
			walk = name
			scene = f" (game scene: `{group[0]['game']}`)" if group[0]["game"] else ""
			lines += [f"## {name or 'Adresses demandées'}{scene}", ""]
			if maps_made.get(name or "Adresses demandées"):
				lines += [f"Map: `{maps_made[name or 'Adresses demandées']}`: where each building stands in the street and its surroundings.", ""]
		if name:
			ours = ", **Charlotte's block: what the game shows, left to right on screen**" if group[0]["our_side"] else ""
			what = "looking down the street from each end" if side == "along" else f"{side} side, camera facing {group[0]['looking']}"
			lines += [f"### {what}{ours}", ""]
		lines += ["| m along | address | picture | taken at | date | close-ups |", "|---:|---|---|---|---|---|"]
		for shot in group:
			address = shot["address"].split(",")[0] + (" (approx.)" if shot["approx"] else "")
			lines.append(f"| {shot['along_m'] if name else ''} | {address} | `{shot['file']}` | {shot['lat']}, {shot['lng']} "
				f"| {shot['date']} | {len(shot['details'])} |")
		lines.append("")
	return "\n".join(lines)


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
	parser.add_argument("--places", type=Path, default=HERE / "places.json", help="what to photograph")
	parser.add_argument("--out", type=Path, default=DEFAULT_OUT, help=f"output folder (default: {DEFAULT_OUT})")
	parser.add_argument("--street", help="one range, without editing places.json: the street…")
	parser.add_argument("--from", dest="first", type=int, help="…its first civic number…")
	parser.add_argument("--to", dest="last", type=int, help="…and its last")
	parser.add_argument("--parity", choices=["even", "odd"], help="one side of the range only")
	parser.add_argument("--between", nargs=2, metavar=("CROSS1", "CROSS2"), help="keep only the block between these two cross streets, in this order")
	parser.add_argument("--city", help="the city (default: the one in places.json)")
	parser.add_argument("--only", help="only the walks and addresses whose name contains this")
	parser.add_argument("--step", type=float, default=10, help="metres between pictures along a walk")
	parser.add_argument("--fov", type=float, default=90, help="field of view, degrees (120 at most)")
	parser.add_argument("--pitch", type=float, default=12, help="camera tilt up, degrees")
	parser.add_argument("--maps-only", action="store_true", help="redraw the maps, index and INDEX.md from index.json, no Google calls")
	parser.add_argument("--detail", action="store_true", help="also six narrow-view close-ups of each facade, 3x the resolution (7x the pictures)")
	options = parser.parse_args()

	places = json.loads(options.places.read_text())
	if options.maps_only:
		shots = json.loads((options.out / "index.json").read_text())
		google = Google(api_key(), options.out / "cache.json")
		write_index(options.out, shots, area(google, places, options.out, shots))
		return
	city = options.city or places.get("city", "")
	places["walks"] = places.get("walks", []) + [range_walk(r) for r in places.get("ranges", [])]
	if options.street:
		if options.first is None or options.last is None:
			parser.error("--street needs --from and --to")
		one = {"street": options.street, "from": options.first, "to": options.last}
		if options.between:
			one["between"] = options.between
		places = {"walks": [range_walk(one | ({"parity": options.parity} if options.parity else {}))]}
	options.out.mkdir(parents=True, exist_ok=True)
	google = Google(api_key(), options.out / "cache.json")
	capture = Capture(google, options.out, options)
	wanted = lambda name: not options.only or options.only.lower() in name.lower()

	for walk in places.get("walks", []):
		if wanted(walk["name"]):
			capture.walk(walk, city)
	addresses = [a for a in places.get("addresses", []) if wanted(a)]
	if addresses:
		print("Adresses")
	for query in addresses:
		capture.address(query, city)

	# A partial run (--only) keeps what the earlier runs found.
	index = options.out / "index.json"
	fresh = {s["file"] for s in capture.shots}
	kept = [s for s in json.loads(index.read_text()) if s["file"] not in fresh] if index.exists() else []
	write_index(options.out, kept + capture.shots, area(google, places, options.out, kept + capture.shots))
	print(f"\n{len(capture.shots)} pictures ({len(kept)} kept from before) → {options.out}")
	print(f"Map: {options.out / 'index.html'}")
	print("Calls made: %(geocode)d geocoding, %(metadata)d metadata (free), %(image)d images" % google.calls)


if __name__ == "__main__":
	main()
