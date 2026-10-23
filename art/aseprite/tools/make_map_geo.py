"""Projects real geography into pixel data for the trail map (art/aseprite/scenes/trail_map.lua).

Sources (public domain):
  Natural Earth vector data, https://github.com/nvkelso/natural-earth-vector (geojson/):
    ne_50m_land, ne_10m_rivers_lake_centerlines, ne_10m_rivers_north_america, ne_10m_lakes
  Terrain Tiles on AWS (open data, Mapzen terrarium encoding; SRTM, GMTED, ETOPO1 and USGS NED),
    zoom 6 tiles saved as terr/6_<x>_<y>.png from
    https://s3.amazonaws.com/elevation-tiles-prod/terrarium/6/<x>/<y>.png

Usage: python3 make_map_geo.py <folder with those files> > ../data/map_geo.lua
The projection must match data/map.json, which places the stops for the game.
"""
import json
import math
import os
import sys

from PIL import Image, ImageDraw

SRC = sys.argv[1]
MAP = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../data/map.json")))
P = MAP["projection"]
W, H = P["width"], P["height"]
SX = W / (P["east"] - P["west"])
SY = SX / math.cos(math.radians(P["parallel"]))


def project(lon, lat):
    return ((lon - P["west"]) * SX, (P["north"] - lat) * SY)


def geo(name):
    return json.load(open(f"{SRC}/{name}.geojson"))["features"]


def lines_of(geometry):
    if geometry is None:
        return []
    if geometry["type"] in ("LineString",):
        return [geometry["coordinates"]]
    if geometry["type"] in ("MultiLineString", "Polygon"):
        return geometry["coordinates"]
    if geometry["type"] == "MultiPolygon":
        return [ring for poly in geometry["coordinates"] for ring in poly]
    return []


def in_frame(line, pad=1.0):
    return any(P["west"] - pad < x < P["east"] + pad and P["north"] - H / SY - pad < y < P["north"] + pad for x, y, *_ in line)


def mask_rle(img):
    rows = []
    for y in range(H):
        runs, x = [], 0
        while x < W:
            if img.getpixel((x, y)):
                start = x
                while x < W and img.getpixel((x, y)):
                    x += 1
                runs += [start, x - start]
            else:
                x += 1
        rows.append(runs)
    return rows


def polygon_mask(features, keep=lambda p: True):
    img = Image.new("1", (W, H), 0)
    draw = ImageDraw.Draw(img)
    for f in features:
        if not keep(f["properties"]) or f["geometry"] is None:
            continue
        g = f["geometry"]
        polys = [g["coordinates"]] if g["type"] == "Polygon" else g["coordinates"]
        for poly in polys:
            for i, ring in enumerate(poly):
                if not in_frame(ring, 3):
                    continue
                draw.polygon([project(x, y) for x, y, *_ in ring], fill=1 if i == 0 else 0)
    return img


# Major rivers draw two pixels wide; the rest are named tributaries an 1848 map would show.
MAJOR = {"Missouri", "Columbia", "Snake", "Platte", "North Platte", "Kansas", "Mississippi"}
RIVERS = MAJOR | {
    "South Platte", "Sweetwater", "Green", "Bear", "Willamette", "Big Blue", "Little Blue", "Republican",
    "S. Fork Republican", "Smoky Hill", "Solomon", "Arkansas", "Yellowstone", "Bighorn", "Wind", "Laramie",
    "Big Sandy", "Boise", "Owyhee", "Malheur", "Powder", "Grande Ronde", "John Day", "Deschutes", "Humboldt",
    "Sacramento", "Colorado", "Salmon", "Clearwater", "Clark Fork", "Niobrara", "Loup", "North Loup",
    "Cheyenne", "Yakima", "Klamath", "Umpqua", "Rogue", "Sevier", "Jordan", "Cowlitz", "Payette", "Big Wood",
    "Blackfoot", "Osage", "Grand", "Des Moines", "Iowa", "Platte", "Yampa", "Little Snake", "Gunnison",
    "Bitterroot", "Sun", "Marias", "Milk", "Musselshell", "Powder", "Tongue", "Belle Fourche", "White",
    "Elk Horn", "Big Sioux", "James", "Little Missouri", "Pit", "Feather", "San Joaquin", "Okanogan",
    "Spokane", "Pend Orielle", "Kootenay", "Flathead", "Madison", "Jefferson", "Gallatin", "Crooked",
    "Neosho", "Verdigris", "Duchesne", "Lodgepole", "Big Lost", "Bruneau", "Chehalis", "Trinity", "Eel",
}


def rivers():
    out = []
    for name in ("ne_10m_rivers_lake_centerlines", "ne_10m_rivers_north_america"):
        for f in geo(name):
            n = f["properties"].get("name")
            if n not in RIVERS:
                continue
            for line in lines_of(f["geometry"]):
                if not in_frame(line):
                    continue
                pts, last = [], None
                for x, y, *_ in line:
                    p = tuple(round(v) for v in project(x, y))
                    if p != last:
                        pts.append(p)
                        last = p
                if len(pts) > 1:
                    out.append((2 if n in MAJOR else 1, pts))
    return out


NATURAL = {"Great Salt Lake", "Utah Lake", "Bear Lake", "Yellowstone Lake", "Flathead Lake", "Lake Pend Oreille",
           "Lake Tahoe", "Upper Klamath Lake", "Goose Lake", "Pyramid Lake", "Malheur Lake", "Harney Lake",
           "Jackson Lake", "Coeur D'Alene Lake", "Lake Abert", "Honey Lake", "Mono Lake", "Clear Lake"}


def elevation():
    """Metres above sea level at each map pixel, sampled 2x2 and averaged, from zoom-6 terrarium tiles."""
    import numpy as np
    z, t = 6, 256
    n = 2 ** z
    tx0, tx1 = int((P["west"] + 180) / 360 * n), int((P["east"] + 180) / 360 * n)

    def ty(lat):
        r = math.radians(lat)
        return (1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2 * n

    ty0, ty1 = int(ty(P["north"])), int(ty(P["north"] - H / SY))
    mosaic = np.zeros(((ty1 - ty0 + 1) * t, (tx1 - tx0 + 1) * t))
    for x in range(tx0, tx1 + 1):
        for y in range(ty0, ty1 + 1):
            a = np.asarray(Image.open(f"{SRC}/terr/{z}_{x}_{y}.png").convert("RGB"), dtype=float)
            mosaic[(y - ty0) * t:(y - ty0 + 1) * t, (x - tx0) * t:(x - tx0 + 1) * t] = a[..., 0] * 256 + a[..., 1] + a[..., 2] / 256 - 32768
    e = np.zeros((H * 2, W * 2))
    for py in range(H * 2):
        fy = int((ty(P["north"] - (py + 0.5) / 2 / SY) - ty0) * t)
        for px in range(W * 2):
            fx = int(((P["west"] + (px + 0.5) / 2 / SX + 180) / 360 * n - tx0) * t)
            e[py, px] = mosaic[fy, fx]
    return e.reshape(H, 2, W, 2).mean(axis=(1, 3))


def tones():
    """Hill shading lit from the upper left, as tone numbers per pixel:
    1 lit slope, 2 plain, 3 high plain (above 1,600 m), 4 light shade, 5 shade, 6 deep shade."""
    import numpy as np
    from scipy.ndimage import gaussian_filter
    e = gaussian_filter(np.maximum(elevation(), 0), 0.7)
    gy, gx = np.gradient(e, 4300.0)  # a map pixel is about 4.3 km
    ex, alt = 5.0, math.radians(40)
    nz = 1 / np.sqrt(1 + (gx * ex) ** 2 + (gy * ex) ** 2)
    light = -gx * ex * nz * -math.cos(alt) / math.sqrt(2) + -gy * ex * nz * -math.cos(alt) / math.sqrt(2) + nz * math.sin(alt)
    d = light - math.sin(alt)
    out = np.where(e > 1600, 3, 2)
    out[d > 0.08] = 1
    out[d < -0.06] = 4
    out[d < -0.16] = 5
    out[d < -0.30] = 6
    return out


def lua_rows(rows):
    return "{\n" + ",\n".join("  {" + ",".join(map(str, r)) + "}" for r in rows) + "\n}"


land = polygon_mask(geo("ne_50m_land"))
lakes = polygon_mask(geo("ne_10m_lakes"), lambda p: p.get("name") in NATURAL)
lakes_na = polygon_mask(geo("ne_10m_lakes_north_america"), lambda p: p.get("name") in NATURAL)
for y in range(H):
    for x in range(W):
        if lakes_na.getpixel((x, y)):
            lakes.putpixel((x, y), 1)

print("-- Generated by art/aseprite/tools/make_map_geo.py from Natural Earth (public domain). Do not edit.")
print("local G = {}")
print(f"G.W, G.H = {W}, {H}")
print("G.land = " + lua_rows(mask_rle(land)))
print("G.lakes = " + lua_rows(mask_rle(lakes)))
print("G.rivers = {")
for weight, pts in rivers():
    print("  {" + str(weight) + ", {" + ",".join(f"{x},{y}" for x, y in pts) + "}},")
print("}")
# Each row of tones is run-length pairs: tone, length.
rows = []
for row in tones():
    runs, prev, count = [], None, 0
    for v in row:
        if v == prev:
            count += 1
        else:
            if prev is not None:
                runs += [int(prev), count]
            prev, count = v, 1
    rows.append(runs + [int(prev), count])
print("G.relief = " + lua_rows(rows))
print("return G")
