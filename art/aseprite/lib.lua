-- Shared pixel-art kit for the Aseprite scene scripts in art/aseprite/scenes/.
-- Scenes load it with: local K = dofile(app.params.kit)
-- Every mark lands on the integer grid with a named palette colour; no antialiasing.
local K = {}

K.HEX = {
  -- game palette
  ink="302b2c", deep="45372f", wood="76503c", rust="a16b43", ochre="c18d4d",
  gold="ddb461", sand="ecd097", cream="f6e7bc", white="fff4d4", sage="8d9b53",
  grass="667c44", leaf="425e3b", pine="2c493f", teal="47796b", haze="84b3a1",
  sky="548db3", blue="37688e", light_blue="8db8c3",
  -- added shades
  sky_top="4a7fa6", mist="b7d2c6", brick_dk="6e3a2c", brick="94503a", brick_lt="b4694a",
  roof_dk="3a302c", roof="52423a", roof_lt="6a574a", dirt_dk="9a6a44", clap_sh="cfb98e",
  appearance_hair="594537", far_hill="9fbfae", shadow="8a5e3e", skin="e0a878", skin_dk="b77f58",
  red="9e3f33", ox_dk="5a3a2a", ox="7d5536", ox_lt="a77a4f", ox_white="e8dcc0",
  stone_lt="dcd5bc", stone="bfb79c", stone_dk="908a72", stone_ink="66614f",
  silt_lt="c4b08a", silt="a38b64", silt_dk="7f6b4c",
  storm_dk="3b414c", storm="555d68", storm_lt="7b8389",
  -- trail map
  dune="e2c286", sea="9cc2c2", sea_line="7ba6ae",
}
local col = {}
for k, h in pairs(K.HEX) do
  col[k] = app.pixelColor.rgba(tonumber(h:sub(1,2),16), tonumber(h:sub(3,4),16), tonumber(h:sub(5,6),16), 255)
end
col.ground_shadow = app.pixelColor.rgba(0x45, 0x37, 0x2f, 0x66)
col.wagon_shadow  = app.pixelColor.rgba(0x45, 0x37, 0x2f, 0x88)

K.col = col

local W, H, spr, img
local px, rect, dither, blend, line, ellipse, poly, rnd -- bound after the primitives below
local seed = 1

-- Start a new scene canvas. Layers are added bottom to top with K.layer.
function K.canvas(w, h, rng_seed)
  W, H = w, h
  seed = rng_seed or 1
  spr = Sprite(w, h, ColorMode.RGB)
  return spr
end

-- Deterministic random integer in [0, n), so a scene rebuilds pixel for pixel.
function K.rnd(n) seed = (seed * 1103515245 + 12345) % 2147483648; return seed % n end

function K.layer(name, fn)
  local l = (#spr.layers == 1 and spr.layers[1].name == "Layer 1") and spr.layers[1] or spr:newLayer()
  l.name = name
  img = Image(W, H, ColorMode.RGB)
  fn()
  spr:newCel(l, spr.frames[1], img, Point(0, 0))
end

-- The colour already painted at (x, y) on the current layer, as a palette name or nil.
function K.at(x, y)
  local v = img:getPixel(x, y)
  for name, c in pairs(col) do if c == v then return name end end
end

-- Season: build.sh --seasons reruns location scenes with season=winter or season=autumn.
-- The tree helpers draw bare or turned trees themselves; K.save then repaints the ground,
-- far hills and sky and lays snow on the tops of evergreens and roofs, and writes
-- <name>_<season>.png. Spring and summer are the plain pictures.
K.season = app.params.season
if K.season == "" then K.season = nil end
-- Autumn differs along the road, so each scene script belongs to a region (build.sh passes the
-- script name as `scene`):
--   tallgrass  Missouri and eastern Kansas: bluestem copper and wine-red, Indian grass orange,
--              oaks russet, hickory and cottonwood gold
--   plains     the Platte and high plains: short grass cured to straw with a grey-green cast,
--              cottonwoods and willows bright gold along the rivers
--   sage       Sweetwater, Green River, Snake River, eastern Oregon: sagebrush stays silver-green,
--              rabbitbrush in yellow bloom, grass bleached straw, cottonwoods gold
--   mountain   Bear River, Blue Mountains, Cascades: conifers dark with gold aspen and (in the
--              Blues) western larch among them, meadows straw and rust
--   west       west of the Cascades: autumn rains green the grass again, maples yellow
local REGION = {}
for _, n in ipairs({"elm_grove", "wakarusa", "kansas_river", "big_vermilion", "big_blue", "jail_county", "little_blue"}) do REGION[n] = "tallgrass" end
for _, n in ipairs({"platte", "fort_kearny", "fort_kearny_early", "jail_army", "south_platte", "ash_hollow", "courthouse_rock",
    "chimney_rock", "scotts_bluff", "fort_laramie", "deer_creek", "north_platte"}) do REGION[n] = "plains" end
for _, n in ipairs({"horseshoe_creek", "bear_river", "blue_mountains", "grande_ronde", "barlow_pass", "laurel_hill",
    "fandango_pass"}) do REGION[n] = "mountain" end
-- the oak valleys of the Applegate road: grass cured to straw, oaks turning brown and gold
for _, n in ipairs({"rogue_valley", "umpqua_valley"}) do REGION[n] = "plains" end
-- river crossings added later: the Laramie ford on the Platte plains, the Weber and the White
-- River in the mountains, the Bear River of Hensley's cutoff in sage country
REGION.laramie_ford = "plains"; REGION.weber_river = "mountain"; REGION.white_river = "mountain"; REGION.bear_river_ford = "sage"
for _, n in ipairs({"eagle_creek", "oregon_city", "columbia_raft", "south_willamette"}) do REGION[n] = "west" end
-- the southern Cascades of the Applegate road: mountain meadows, but fir and pine with no larch
for _, n in ipairs({"green_springs", "canyon_creek"}) do REGION[n] = "cascade" end
-- the scrolling travel layers: prairie and river sets serve Kansas and the Platte (build.sh also
-- makes an "autumn_east" tallgrass version of them), desert is sage country, mountains and
-- forest are the high timber
for _, n in ipairs({"prairie", "river", "travel_ground", "travel_horizon"}) do REGION[n] = "plains" end
REGION.travel_desert = "sage"; REGION.travel_mountains = "mountain"; REGION.travel_forest = "mountain"
K.region = (app.params.region ~= "" and app.params.region) or REGION[app.params.scene or ""] or "sage"
-- the file suffix: the season, or a regional variant such as autumn_east
local TAG = (app.params.tag ~= "" and app.params.tag) or K.season
local SEASON_MAP = {
  winter = {grass="white", sage="stone_lt", haze="mist",
            far_hill="stone_lt"},
  autumn = {grass={"silt_lt", "silt_lt", "sand"}, sage="ochre", haze="far_hill"},
}
local AUTUMN_MAP = {
  tallgrass = {grass={"rust", "rust", "rust", "ochre", "ochre", "brick_lt", "silt", "gold", "brick"}, sage={"ochre", "silt_lt", "rust"}, haze="far_hill"},
  plains = {grass={"silt_lt", "silt_lt", "sand", "sage", "clap_sh", "silt"}, sage={"silt_lt", "sage", "sage"}, haze="far_hill"},
  sage = {grass={"silt_lt", "sand", "clap_sh"}, sage={"sage", "silt_lt", "clap_sh", "silt_lt"}, haze="far_hill"},
  mountain = {grass={"silt_lt", "sage", "ochre", "silt_lt", "rust"}, sage={"ochre", "silt_lt"}, haze="far_hill"},
  cascade = {grass={"silt_lt", "sage", "ochre", "silt_lt", "rust"}, sage={"ochre", "silt_lt"}, haze="far_hill"},
  west = {grass={"grass", "grass", "grass", "grass", "leaf", "sage", "grass", "ochre"}},
}
local CAPPED = {pine=true, leaf=true, ink=true, roof=true, roof_lt=true, roof_dk=true}
local OPEN = {sky=true, sky_top=true, light_blue=true, mist=true, haze=true, far_hill=true,
              storm=true, storm_lt=true, stone_lt=true, white=true, cream=true}
-- A scene can add its own recolours for a band of rows, for colours the shared tables leave
-- alone because they mean something else elsewhere (teal is water in a river picture but a
-- wooded ridge in a travel layer): K.season_extra = {{season="winter", region=nil, y0=100,
-- y1=150, map={leaf="white"}}, ...}. The first matching entry wins over the tables.
K.season_extra = {}
-- With K.flat_snow, snow settles only where a top edge runs level (branch tiers, ridge tops),
-- not down every sloping edge, which reads as a white outline round a fir.
K.flat_snow = false
local function seasonal(image, season)
  local name_of = {}
  for n, c in pairs(col) do name_of[c] = n end
  local src = image:clone()
  local map = (season == "autumn") and AUTUMN_MAP[K.region] or SEASON_MAP[season]
  local function at(x, y)
    if x < 0 or y < 0 or x >= W or y >= H then return nil end
    return name_of[src:getPixel(x, y)]
  end
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local n = at(x, y)
      local t = n and map[n]
      for _, e in ipairs(K.season_extra) do
        if n and e.season == season and (not e.region or e.region == K.region)
            and y >= (e.y0 or 0) and y < (e.y1 or H) and e.map[n] then
          t = e.map[n]; break
        end
      end
      if type(t) == "table" then
        -- patches a few pixels wide (staggered like tufts), with a sprinkle of single pixels,
        -- so the mix reads as grass rather than hatching or gravel
        local function scramble(a, b)
          local v = ((a * 374761393 + b * 668265263) ~ (a * b * 1274126177)) & 0x7fffffff
          return ((v ~ (v >> 13)) * 1103515245) & 0x7fffffff
        end
        local cy = y // 2
        local cx = (x + (cy % 2) * 3) // 6
        local pick = scramble(cx, cy) >> 8
        local dot = scramble(x, y) >> 8
        if dot % 6 == 0 then pick = dot >> 3 end
        t = t[pick % #t + 1]
      end
      -- west of the Cascades: bigleaf maple gold and vine maple red among the firs and along
      -- the forest edge
      if season == "autumn" and K.region == "west" and (n == "pine" or n == "leaf") then
        -- whole crowns, not specks: cells of a few pixels picked at random, each one tree
        local cx, cy = (x + (y // 3 % 2) * 2) // 4, y // 3
        local v = ((cx * 2654435761 + cy * 40503) ~ (cy * 97 + cx)) & 0xffff
        local edge = at(x, y + 3) == "grass" or at(x, y + 4) == "grass" or at(x, y + 3) == "sage"
        if (v % 9 == 0) or (edge and v % 3 == 0) then
          local inner = ((x * 13 + y * 7) % 5)
          t = (v % 4 == 0) and "brick_lt" or "gold"
          if inner == 0 then t = (t == "gold") and "ochre" or "brick" end
        end
      end
      if season == "autumn" and (K.region == "sage" or K.region == "plains") and n == "haze" and y > H * 0.5 and (x * 31 + y * 17) % 7 < 2 then t = "gold" end
      -- lone dark speckles in the grass go with the ground rather than staying green
      if (n == "leaf" or n == "pine") and y > H * 0.45 then
        local same = 0
        for _, d in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do
          local m = at(x + d[1], y + d[2]); if m == "leaf" or m == "pine" or m == "ink" then same = same + 1 end
        end
        if same == 0 then t = (season == "winter") and "white" or "silt" end
      end
      -- (on a single layer, transparent above means open sky behind)
      local function open(m) return m == nil or OPEN[m] end
      if season == "winter" and n and CAPPED[n] and open(at(x, y - 1))
          and not (K.flat_snow and (open(at(x - 1, y)) or open(at(x + 1, y))
            or not open(at(x - 1, y - 1)) or not open(at(x + 1, y - 1)))) then
        t = "white"
        if not K.flat_snow and (x * 7 + y * 3) % 5 < 2 and at(x, y + 1) == n then image:drawPixel(x, y + 1, col.white) end
      end
      if t then image:drawPixel(x, y, col[t]) end
    end
  end
end

-- Autumn crown colours (dark, mid, light, tip) for the region: russet oak country in the east,
-- yellow cottonwood, aspen and maple elsewhere.
function K.autumn_leaves()
  if K.region == "tallgrass" then return "brick", "rust", "ochre", "gold" end
  return "ochre", "gold", "sand", "cream"
end

-- Leaf colours for a broadleaf crown drawn by hand in a scene: the summer colours as given, a
-- turned set in autumn, and in winter a grey haze of bare twigs.
function K.leaves(dk, md, lt)
  if K.season == "autumn" then return K.autumn_leaves() end
  if K.season == "winter" then return "ox", "storm_lt", "stone_dk" end
  return dk, md, lt
end

-- Write <out>/<name>.png (flattened) and <out>/<name>.aseprite (layered).
function K.save(name)
  local out = app.params.out or "."
  if K.season then
    local image = Image(spr) -- the flattened picture; the layered sprite stays for save_layers
    seasonal(image, K.season)
    image:saveAs(out .. "/" .. name .. "_" .. TAG .. ".png")
    print("built " .. name .. "_" .. TAG .. " (" .. W .. "x" .. H .. ")")
    return
  end
  spr:saveAs(out .. "/" .. name .. ".aseprite")
  spr:saveCopyAs(out .. "/" .. name .. ".png")
  print("built " .. name .. " (" .. W .. "x" .. H .. ", " .. #spr.layers .. " layers)")
end

-- Also write chosen layers on their own: names maps layer name -> output name (<out>/<name>.png).
function K.save_layers(names)
  local out = app.params.out or "."
  local shown = {}
  for _, l in ipairs(spr.layers) do shown[l] = l.isVisible end
  for layer_name, file in pairs(names) do
    for _, l in ipairs(spr.layers) do l.isVisible = (l.name == layer_name) end
    if K.season then
      local image = Image(spr)
      seasonal(image, K.season)
      -- a layer the season leaves alone (sky, clouds) gets no copy: the game falls back to
      -- the plain one
      local plain = app.fs.isFile(out .. "/" .. file .. ".png") and Image{fromFile = out .. "/" .. file .. ".png"}
      if plain and plain:isEqual(image) then
        print("same " .. file .. " in " .. TAG)
      else
        image:saveAs(out .. "/" .. file .. "_" .. TAG .. ".png")
        print("built " .. file .. "_" .. TAG .. " (layer " .. layer_name .. ")")
      end
    else
      spr:saveCopyAs(out .. "/" .. file .. ".png")
      print("built " .. file .. " (layer " .. layer_name .. ")")
    end
  end
  for _, l in ipairs(spr.layers) do l.isVisible = shown[l] end
end

---------------------------------------------------------------- primitives
-- With K.wrap set, marks past the left or right edge come round the other side, so a layer
-- tiles seamlessly when the travel view scrolls it.
K.wrap = false
function K.px(x, y, c)
  if K.wrap then x = x % W end
  if x >= 0 and y >= 0 and x < W and y < H then img:drawPixel(x, y, col[c]) end
end
function K.rect(x, y, w, h, c)
  for yy = y, y + h - 1 do for xx = x, x + w - 1 do px(xx, yy, c) end end
end
function K.dither(x, y, w, h, a, b)
  for yy = y, y + h - 1 do for xx = x, x + w - 1 do px(xx, yy, ((xx + yy) % 2 == 0) and a or b) end end
end
function K.blend(x, y, w, a, b)
  -- three rows: 25%, 50%, 75% of b over a
  for xx = x, x + w - 1 do
    px(xx, y, (xx % 4 == 0) and b or a)
    px(xx, y + 1, ((xx + y) % 2 == 0) and b or a)
    px(xx, y + 2, ((xx + 2) % 4 == 0) and a or b)
  end
end
function K.line(x0, y0, x1, y1, c)
  -- endpoints a fractional distance apart would never meet and loop forever: snap those to the grid
  if (x1 - x0) % 1 ~= 0 or (y1 - y0) % 1 ~= 0 then
    x0, y0, x1, y1 = math.floor(x0 + 0.5), math.floor(y0 + 0.5), math.floor(x1 + 0.5), math.floor(y1 + 0.5)
  end
  local dx, dy = math.abs(x1 - x0), -math.abs(y1 - y0)
  local sx, sy = x0 < x1 and 1 or -1, y0 < y1 and 1 or -1
  local err = dx + dy
  while true do
    px(x0, y0, c)
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * err
    if e2 >= dy then err = err + dy; x0 = x0 + sx end
    if e2 <= dx then err = err + dx; y0 = y0 + sy end
  end
end
function K.ellipse(cx, cy, rx, ry, c)
  for y = -ry, ry do for x = -rx, rx do
    if (x*x)/(rx*rx + 0.5) + (y*y)/(ry*ry + 0.5) <= 1 then px(cx + x, cy + y, c) end
  end end
end
function K.poly(pts, c)
  local miny, maxy = math.huge, -math.huge
  for _, p in ipairs(pts) do miny = math.min(miny, p[2]); maxy = math.max(maxy, p[2]) end
  for y = math.floor(miny), math.ceil(maxy) do
    local xs = {}
    for i = 1, #pts do
      local a, b = pts[i], pts[i % #pts + 1]
      if (a[2] <= y + 0.5 and b[2] > y + 0.5) or (b[2] <= y + 0.5 and a[2] > y + 0.5) then
        xs[#xs+1] = a[1] + (y + 0.5 - a[2]) * (b[1] - a[1]) / (b[2] - a[2])
      end
    end
    table.sort(xs)
    for i = 1, #xs - 1, 2 do
      for x = math.ceil(xs[i] - 0.5), math.floor(xs[i+1] - 0.5) do px(x, y, c) end
    end
  end
end

px, rect, dither, blend, line, ellipse, poly, rnd = K.px, K.rect, K.dither, K.blend, K.line, K.ellipse, K.poly, K.rnd

---------------------------------------------------------------- sky
-- Puffy cumulus lit from above: blue underside, cream body, white crown.
function K.cloud(x, y, s)
  local puffs = {{0,4,9,4},{8,1,9,6},{18,-1,11,8},{29,2,9,6},{37,5,7,3}}
  for _, p in ipairs(puffs) do ellipse(x + p[1]*s, y + p[2], math.floor(p[3]*s), p[4], "light_blue") end
  for _, p in ipairs(puffs) do ellipse(x + p[1]*s - 1, y + p[2] - 2, math.max(2, math.floor(p[3]*s) - 2), math.max(1, p[4] - 2), "cream") end
  for _, p in ipairs(puffs) do ellipse(x + p[1]*s - 3, y + p[2] - 3, math.max(1, math.floor(p[3]*s) - 6), math.max(1, p[4] - 4), "white") end
  rect(x - 8, y + 7, math.floor(46*s), 1, "light_blue")
end

---------------------------------------------------------------- landscape helpers
-- Sky in banded ramps down to `bottom`, with clouds given as {{x, y, scale}, ...}.
-- Vary the cloud list per scene so pictures do not repeat one another.
function K.sky(w, bottom, clouds, haze)
  local bands = {{"sky_top", 0}, {"sky", 0.3}, {"light_blue", 0.62}, {haze or "mist", 0.86}}
  for i, b in ipairs(bands) do
    local y0 = math.floor(b[2] * bottom)
    local y1 = (i < #bands) and math.floor(bands[i + 1][2] * bottom) or bottom
    rect(0, y0, w, y1 - y0, b[1])
    if i < #bands then K.blend(0, y1 - 1, w, b[1], bands[i + 1][1]) end
  end
  for _, c in ipairs(clouds or {}) do K.cloud(c[1], c[2], c[3]) end
end

-- Catmull-Rom through pts ({x, y, w} each), n steps per span, for smooth bends.
function K.smooth(pts, n)
  n = n or 6
  local out = {}
  for i = 1, #pts - 1 do
    local p0, p1, p2, p3 = pts[math.max(1, i - 1)], pts[i], pts[i + 1], pts[math.min(#pts, i + 2)]
    for s = 0, n - 1 do
      local t = s / n
      local t2, t3 = t * t, t * t * t
      local q = {}
      for k = 1, 3 do
        q[k] = 0.5 * ((2 * p1[k]) + (-p0[k] + p2[k]) * t + (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t2 + (-p0[k] + 3 * p1[k] - 3 * p2[k] + p3[k]) * t3)
      end
      out[#out + 1] = q
    end
  end
  out[#out + 1] = pts[#pts]
  return out
end

-- A strip whose centre follows pts = {{x, y, half_width}, ...}; widths taper with distance.
function K.ribbon(pts, c, grow)
  grow = grow or 0
  for i = 1, #pts - 1 do
    local a, b = pts[i], pts[i + 1]
    local dx, dy = b[1] - a[1], b[2] - a[2]
    local len = math.max(0.001, math.sqrt(dx * dx + dy * dy))
    local nx, ny = -dy / len, dx / len
    local wa, wb = a[3] + grow, b[3] + grow
    poly({{a[1] + nx * wa, a[2] + ny * wa}, {b[1] + nx * wb, b[2] + ny * wb},
          {b[1] - nx * wb, b[2] - ny * wb}, {a[1] - nx * wa, a[2] - ny * wa}}, c)
    ellipse(math.floor(b[1] + 0.5), math.floor(b[2] + 0.5), math.max(0, math.floor(wb)), math.max(0, math.floor(wb * 0.6)), c)
  end
end

-- A river along pts: gravel bank, deep edges, lighter channel and broken sun glints.
-- `bank` may be false for water against rock.
function K.river(pts, bank, glints)
  if bank ~= false then K.ribbon(pts, bank or "sand", 2) end
  K.ribbon(pts, "blue", 0)
  local inner = {}
  for i, q in ipairs(pts) do inner[i] = {q[1], q[2], q[3] * 0.62} end
  K.ribbon(inner, "sky_top", 0)
  for i = 1, #pts - 1 do
    local a, b = pts[i], pts[i + 1]
    local steps = math.floor(math.max(math.abs(b[1] - a[1]), math.abs(b[2] - a[2])) / 3)
    for s = 0, steps - 1 do
      if K.rnd(3) == 0 then
        local t = s / math.max(1, steps)
        local w = a[3] + (b[3] - a[3]) * t
        local cx = a[1] + (b[1] - a[1]) * t + (K.rnd(100) / 100 - 0.5) * w
        local cy = a[2] + (b[2] - a[2]) * t
        local len = math.max(1, math.floor(w / 4))
        rect(math.floor(cx), math.floor(cy), len, 1, (K.rnd(3) == 0) and (glints or "white") or "light_blue")
      end
    end
  end
end

-- Hill or ridge silhouette: for x in [x0, x1] the top is base - height(x), filled down to `floor`.
-- Faces turned to the upper-left light get `lit` on their crest; faces turned away get `shade`.
function K.ridge(x0, x1, base, floor, height, fill, lit, shade)
  for x = x0, x1 do
    local top = math.floor(base - height(x) + 0.5)
    local slope = height(x + 1) - height(x - 1)
    for y = top, floor do px(x, y, fill) end
    if slope > 0.15 and lit then px(x, top, lit); px(x, top + 1, lit)
    elseif slope < -0.15 and shade then for y = top, math.min(floor, top + 3) do px(x, y, shade) end
    elseif lit then px(x, top, lit) end
  end
end

-- Distant snowy range: hazy blue rock, lit faces to the upper left, and snow on everything
-- higher than `snow` pixels above `base`, white where lit and pale blue in shade.
function K.peaks(x0, x1, base, floor, height, snow)
  for x = x0, x1 do
    local top = math.floor(base - height(x) + 0.5)
    local slope = height(x + 1) - height(x - 1)
    for y = top, floor do
      local c = (slope > 0) and "mist" or "far_hill"
      if slope == 0 then c = "far_hill" end
      if y > top + 3 then c = (slope > 0) and "far_hill" or "haze" end
      if base - y > snow + math.floor(2 * math.sin(x / 3)) then
        c = (slope > 0) and "white" or "light_blue"
        if (x + y) % 5 == 0 then c = (slope > 0) and "mist" or "far_hill" end
      end
      px(x, y, c)
    end
  end
end

-- Eroded clay-and-sandstone butte of the North Platte country (Courthouse, Jail, Chimney's
-- base, Scotts Bluff). b = {cx, crown, top, shoulder, base, foot, seed, cap}: a crown
-- `crown` px either side of cx at y=top, near-vertical walls down to y=shoulder, then a concave
-- apron reaching `foot` px either side at y=base. Light comes from the upper left: west faces
-- are bright, east faces in shade, with vertical rills in the walls and gullies in the apron.
-- Returns the top y for each column so callers can stack details on it.
function K.butte(b)
  local seed0 = b.seed or 1
  local wall = math.max(3, math.floor((b.shoulder - b.top) * 0.42))
  local function n(x, k) return math.sin(x * 0.37 * k + seed0) + 0.6 * math.sin(x * 0.11 * k + seed0 * 2.3) end
  local tops = {}
  for x = b.cx - b.foot, b.cx + b.foot do
    local dx = math.abs(x - b.cx)
    local y
    if dx <= b.crown then
      y = b.top + math.floor(4 * (dx / b.crown) ^ 4 + 0.8 * n(x, 1) + 0.5)
    elseif dx <= b.crown + wall then
      local t = (dx - b.crown) / wall
      y = b.top + 3 + math.floor(t ^ 1.4 * (b.shoulder - b.top - 3) + 1.5 * n(x, 2))
    else
      local t = math.min(1, (dx - b.crown - wall) / math.max(1, b.foot - b.crown - wall))
      y = b.shoulder + math.floor((b.base - b.shoulder) * (1 - (1 - t) ^ 2) + 1.2 * n(x, 1.7) + 0.5)
    end
    tops[x] = math.min(y, b.base)
  end
  for x = b.cx - b.foot, b.cx + b.foot do
    local top = tops[x]
    local slope = (tops[x + 3] or b.base) - (tops[x - 3] or b.base)
    local side = (slope < -2) and "lit" or ((slope > 2) and "shade" or "front")
    if x > b.cx + b.crown then side = (slope > 0) and "shade" or side end
    local rill = (K.rnd(4) == 0) and (top + 2 + K.rnd(b.shoulder - b.top + 6))
    local reach = math.max(0, 1 - (math.abs(x - b.cx) / (b.crown + wall)) ^ 2)
    local edge = b.shoulder + 2 + math.floor(reach * 7 + 1.5 * n(x, 3))
    for y = top, b.base do
      local c
      if y < edge or (y < edge + 3 and (x + y) % 2 == 0 and y - edge < K.rnd(3)) then
        c = ({lit = "cream", front = "sand", shade = "clap_sh"})[side]
        local bed = y - b.top + math.floor(n(x, 0.5))
        if (bed == 7 or bed == 15 or bed == 21) and K.rnd(3) > 0 then c = ({lit = "sand", front = "clap_sh", shade = "ochre"})[side] end
        if rill and y <= rill then c = ({lit = "sand", front = "clap_sh", shade = "ochre"})[side] end
        if y <= top + 1 and side ~= "shade" then c = b.cap or "white" end
      else
        c = ({lit = "gold", front = "ochre", shade = "rust"})[side]
        if K.rnd(17) == 0 then c = "clap_sh" end
      end
      px(x, y, c)
    end
  end
  -- gullies fanning down the apron from the foot of the walls
  for k = -b.foot, b.foot, 6 + seed0 % 3 do
    local x0 = b.cx + math.floor(k * (b.crown + wall) / b.foot)
    local x1 = b.cx + k
    local y0 = b.shoulder + 1
    for s = 0, 20 do
      local t = s / 20
      local x = math.floor(x0 + (x1 - x0) * t + 0.5)
      local y = math.floor(y0 + (b.base - y0) * t * t + 0.5)
      if tops[x] and y > tops[x] + 1 and y < b.base - 1 then
        px(x, y, (x < b.cx) and "ochre" or "dirt_dk")
        if x < b.cx then px(x - 1, y, "gold") end
      end
    end
  end
  return tops
end

-- Low grey-green sagebrush clump.
function K.sage(x, y)
  rect(x - 3, y - 1, 7, 2, "teal")
  rect(x - 2, y - 3, 5, 2, "haze")
  px(x - 1, y - 4, "far_hill"); px(x + 1, y - 3, "far_hill"); px(x - 3, y - 2, "haze")
  px(x + 3, y, "pine"); px(x - 3, y, "pine")
end

-- Rounded willow or brush clump along a creek.
function K.willow(x, y, s)
  s = s or 1
  if K.season == "winter" then
    -- a thicket of bare red-brown withes
    for i = -5, 5, 2 do line(x + i // 2, y, math.floor(x + i * s), math.floor(y - 6 * s) - (i % 3), (i % 4 == 1) and "brick" or "ox") end
    px(math.floor(x - 4 * s), math.floor(y - 6 * s), "white"); px(math.floor(x + 2 * s), math.floor(y - 7 * s), "white")
    return
  end
  local dark, mid, lit, tip = "pine", "leaf", "grass", "sage"
  if K.season == "autumn" then dark, mid, lit, tip = "rust", "ochre", "gold", "sand"; if K.region == "tallgrass" then dark, mid, lit, tip = "brick", "rust", "ochre", "gold" end end
  ellipse(x, y - 3 * s, 6 * s, 4 * s, dark)
  ellipse(x - 1, y - 4 * s, 5 * s, 3 * s, mid)
  ellipse(x - 2, y - 5 * s, 3 * s, 2 * s, lit)
  px(x - 3 * s, y - 6 * s, tip)
end
function K.basalt(x, y, w, h, rim)
  rect(x, y, w, h, "roof")
  for xx = x, x + w - 1 do
    local col = (xx - x) % 5
    if col == 0 then for yy = y + 2, y + h - 1 do px(xx, yy, "roof_dk") end
    elseif col == 1 then for yy = y + 2, y + h - 1 do if (yy + xx) % 7 ~= 0 then px(xx, yy, "roof_lt") end end end
    if K.rnd(4) == 0 then px(xx, y + 2 + K.rnd(math.max(1, h - 2)), "ink") end
  end
  rect(x, y, w, 2, rim or "rust")
  rect(x, y + 2, w, 1, "deep")
end

---------------------------------------------------------------- buildings
-- Light comes from the upper left: left faces lit, right-hand side walls in shade.
function K.windows(x, y, w, n, wall_dk, shutter)
  -- n evenly spaced 5x7 sash windows across width w
  local gap = math.floor((w - n * 5) / (n + 1))
  for i = 0, n - 1 do
    local wx = x + gap + i * (5 + gap)
    rect(wx - 1, y - 1, 7, 9, wall_dk)
    rect(wx, y, 5, 7, "blue")
    rect(wx, y, 2, 3, "light_blue")
    rect(wx + 2, y, 1, 7, "cream")
    rect(wx, y + 3, 5, 1, "cream")
    rect(wx - 1, y + 7, 7, 1, "sand")
    if shutter then rect(wx - 3, y, 2, 7, shutter); rect(wx + 6, y, 2, 7, shutter) end
  end
end

function K.bricks(x, y, w, h)
  rect(x, y, w, h, "brick")
  for yy = y + 1, y + h - 1, 3 do
    rect(x, yy, w, 1, "brick_dk")
    local off = ((yy - y) % 6 == 1) and 0 or 3
    for xx = x + off, x + w - 1, 6 do px(xx, yy + 1, "brick_dk") end
  end
  for i = 1, w * h / 18 do px(x + rnd(w), y + rnd(h), "brick_lt") end
end

function K.clapboard(x, y, w, h, base, line_c)
  rect(x, y, w, h, base)
  for yy = y + 2, y + h - 1, 3 do rect(x, yy, w, 1, line_c) end
end

function K.side_wall(x, y, depth, h, fill, line_c)
  -- receding right-hand wall in shade (light comes from the left)
  poly({{x, y}, {x + depth, y - 4}, {x + depth, y + h - 3}, {x, y + h}}, fill)
  if line_c then
    for yy = y + 3, y + h - 2, 3 do line(x, yy, x + depth - 1, yy - 3, line_c) end
  end
end

function K.hip_roof(x, y, w, depth, rise)
  poly({{x - 3, y}, {x + 7, y - rise}, {x + w - 7 + depth, y - rise - 3}, {x + w + depth + 2, y - 3}, {x + w + 3, y}}, "roof")
  -- shingle courses
  for yy = y - rise + 2, y - 1, 2 do
    for xx = x - 3, x + w + depth + 2 do
      if img:getPixel(xx, yy) == col.roof and (xx + yy) % 4 == 0 then px(xx, yy, "roof_dk") end
    end
  end
  -- lit left hip and eave line
  line(x - 3, y, x + 7, y - rise, "roof_lt")
  line(x - 2, y, x + 7, y - rise + 1, "roof_lt")
  rect(x - 3, y, w + 6, 1, "roof_dk")
  rect(x - 3, y + 1, w + 6, 1, "ink")
end

function K.gable_roof(x, y, w, rise)
  K.hip_roof(x, y, w, 0, rise)
end

function K.window(x, y, w, h)
  rect(x, y, w, h, "deep")
  rect(x + 1, y + 1, w - 2, h - 2, "blue")
  rect(x + 1, y + 1, math.max(1, math.floor((w - 2) / 2)), math.max(1, math.floor((h - 2) / 2)), "light_blue")
  rect(x + math.floor(w / 2), y + 1, 1, h - 2, "cream")
  rect(x + 1, y + math.floor(h / 2), w - 2, 1, "cream")
  rect(x, y + h, w, 1, "sand")
end

function K.chimney(x, y, h)
  rect(x, y - h, 4, h, "brick")
  rect(x + 3, y - h, 1, h, "brick_dk")
  rect(x - 1, y - h - 1, 6, 2, "brick_dk")
end

function K.door(x, y, h)
  rect(x - 1, y - h - 1, 8, h + 1, "sand")
  rect(x, y - h, 6, h, "deep")
  rect(x + 1, y - h + 1, 2, h - 2, "wood")
  rect(x + 3, y - h + 1, 2, h - 2, "wood")
  px(x + 4, y - h / 2, "gold")
end

function K.sign(x, y, w, ground, letters)
  rect(x, y, w, 6, "deep")
  rect(x + 1, y + 1, w - 2, 4, ground)
  -- suggestion of lettering
  for i = 0, letters - 1 do
    local lx = x + 3 + i * 3
    if lx < x + w - 3 then rect(lx, y + 2, 2, 2, "deep") end
  end
end


---------------------------------------------------------------- trees
function K.elm(x, y, s)
  rect(x - 1, y - 14 * s, 3, 14 * s, "deep")
  px(x - 1, y - 6 * s, "wood"); line(x, y - 9 * s, x - 6 * s, y - 16 * s, "deep"); line(x + 1, y - 11 * s, x + 7 * s, y - 18 * s, "deep")
  local clumps = {{-7,-17,6,5},{6,-19,7,5},{0,-23,8,6},{-4,-27,6,4},{5,-27,5,4}}
  if K.season == "winter" then
    -- bare crown: limbs forking up into a fine grey haze of twigs, snow along the big limbs
    -- (no K.rnd here, so the winter picture keeps every other random mark where summer has it)
    local f = math.floor
    line(x, f(y - 14 * s), f(x - 2 * s), f(y - 25 * s), "deep"); line(x, f(y - 14 * s), f(x + 3 * s), f(y - 28 * s), "deep")
    for k, c in ipairs(clumps) do
      local cx, cy, rw, rh = f(x + c[1] * s), f(y + c[2] * s), f(c[3] * s), f(c[4] * s)
      line(x, f(y - 12 * s), cx, cy, "deep")
      for i = 1, 3 do line(cx, cy, cx + (i - 2) * rw // 2 * 2, cy - rh, "ox") end
      for i = 1, rw * 2 do px(cx - rw + (i * 7 + k * 3) % (rw * 2 + 1), cy - (i * 5 + k) % (rh + 2), "storm_lt") end
    end
    line(x - 1, f(y - 10 * s), f(x - 6 * s), f(y - 17 * s), "white"); line(x + 1, f(y - 12 * s), f(x + 6 * s), f(y - 19 * s), "white")
    return
  end
  local dark, mid, lit, tip = "pine", "leaf", "grass", "sage"
  if K.season == "autumn" then dark, mid, lit, tip = K.autumn_leaves() end
  for _, c in ipairs(clumps) do ellipse(x + c[1] * s, y + c[2] * s, c[3] * s, c[4] * s, dark) end
  for _, c in ipairs(clumps) do ellipse(x + c[1] * s - 1, y + c[2] * s - 1, c[3] * s - 2, c[4] * s - 2, mid) end
  for _, c in ipairs(clumps) do ellipse(x + c[1] * s - 2, y + c[2] * s - 2, math.max(1, c[3] * s - 5), math.max(1, c[4] * s - 4), lit) end
  for _, c in ipairs(clumps) do px(x + c[1] * s - 3, y + c[2] * s - 3, tip) end
end
function K.conifer(x, y, h, coat_dk, coat_mid, coat_lt)
  coat_dk  = coat_dk  or "ink"
  coat_mid = coat_mid or "pine"
  coat_lt  = coat_lt  or "leaf"
  -- mountain autumn: a western larch or aspen turned gold among the evergreens, now and then
  if K.season == "autumn" and K.region == "mountain" and coat_mid == "pine" and (x * 7 + h * 3) % 5 == 0 then
    coat_dk, coat_mid, coat_lt = "rust", "ochre", "gold"
  end
  local trunk_h = math.max(3, math.floor(h * 0.22))
  rect(x - 1, y - trunk_h, 3, trunk_h + 1, "deep")
  px(x - 1, y - trunk_h + 1, "wood")
  px(x + 1, y - trunk_h + 1, "ink")
  local tiers = math.max(3, math.floor(h / 6))
  for t = 1, tiers do
    local frac = (t - 1) / tiers
    local ty = y - trunk_h - math.floor(frac * (h - trunk_h))
    local tier_h = math.max(4, math.floor((h - trunk_h) / tiers) + 2)
    local half_w = math.max(2, math.floor((1.0 - frac * 0.72) * (h * 0.34)))
    -- Shaded right/under boughs
    poly({{x, ty - tier_h}, {x + half_w + 1, ty}, {x - half_w, ty}}, coat_dk)
    -- Mid foliage body
    poly({{x, ty - tier_h}, {x + half_w - 1, ty - 1}, {x - half_w, ty - 1}}, coat_mid)
    -- Sunlit left boughs
    poly({{x, ty - tier_h}, {x + 1, ty - 1}, {x - half_w, ty - 1}}, coat_lt)
    if t < tiers then px(x - math.max(1, math.floor(half_w * 0.5)), ty - 2, "grass") end
    if K.season == "winter" then
      -- snow loaded on the sunlit boughs of each tier
      line(x, ty - tier_h, x - half_w + 1, ty - 2, "white")
      line(x + 1, ty - tier_h + 1, x + half_w - 2, ty - 2, "mist")
    end
  end
  px(x, y - h - 1, (K.season == "winter") and "white" or coat_lt)
end

-- Rounded sandstone/granite boulder with ground shadow and upper-left highlight.
function K.boulder(bx, by, rx, ry)
  K.shadow(bx - rx, by + ry, rx * 2 + 2)
  ellipse(bx, by, rx, ry, "rust")
  ellipse(bx - 1, by - 1, math.max(1, rx - 1), math.max(1, ry - 1), "ochre")
  ellipse(bx - 2, by - 1, math.max(1, rx - 3), math.max(1, ry - 2), "sand")
  rect(bx - rx + 1, by + ry - 1, rx * 2 - 1, 1, "deep")
end

---------------------------------------------------------------- wagons, stock, people
function K.shadow(x, y, w)
  for xx = x, x + w - 1 do px(xx, y, "shadow"); if (xx % 2 == 0) then px(xx, y + 1, "dirt_dk") end end
end

function K.wheel(cx, cy, r)
  ellipse(cx, cy, r, r, "deep")
  ellipse(cx, cy, r - 1, r - 1, "ochre")
  ellipse(cx, cy, r - 2, r - 2, "ink")
  -- spokes
  for a = 0, 7 do
    local ang = a * math.pi / 4
    line(cx, cy, cx + math.floor((r - 1) * math.cos(ang) + 0.5), cy + math.floor((r - 1) * math.sin(ang) + 0.5), "wood")
  end
  ellipse(cx, cy, 1, 1, "deep")
  px(cx - r + 1, cy - 2, "sand")
end

K.OX_ROWS = {
"....................h..h..",
"...................hh..hh.",
"....oooooo....ooo..ooohoo.",
"..oollllllooollllooodlllo.",
".ollmmmmmmlllllllllodlelo.",
".ommmmmmmmmmmmmllllodlllo.",
"oommmmmwwwmmmmmmmmmmddddlo",
"odmmmmmwwwwmmmmmmmmmddddko",
"odmmmmmmwwmmmmmmmmmmddddo.",
".oddmmmmmmmmmmmmmmmddddo..",
".o.oddddddddddddddddddo...",
"...oooddo.......ooddooo...",
"...o.mo.d.......o.mo.d....",
"...o.mo.d.......o.mo.d....",
"...o.do.d.......o.do.d....",
"...o.oo.o.......o.oo.o....",
}
K.OX_COATS = {
  light = {o="ink", d="ox_dk", m="ox", l="ox_lt", w="ox_white", h="cream", e="ink", k="deep"},
  dark  = {o="ink", d="deep", m="ox_dk", l="ox", w="ox_white", h="cream", e="ink", k="ink"},
  red   = {o="ink", d="ox_dk", m="rust", l="ochre", w="ox_white", h="cream", e="ink", k="deep"},
}
function K.ox(x, y, facing, coat, pale)
  -- 26x16 hand-pixelled sprite; (x, y) = rump at ground level; facing 1 = right
  local map = K.OX_COATS[coat]
  for r, row in ipairs(K.OX_ROWS) do
    for c = 1, #row do
      local ch = row:sub(c, c)
      if ch == "w" and not pale then ch = "m" end
      local name = map[ch]
      if name then px(x + (c - 1) * facing, y - 16 + r, name) end
    end
  end
end

function K.team(x, y, facing, a, b)
  -- far ox two pixels up and ahead, near ox in front of it
  K.shadow(math.min(x, x + 26 * facing), y + 1, 27)
  K.ox(x + 3 * facing, y - 3, facing, a[1], a[2])
  K.ox(x, y, facing, b[1], b[2])
  -- yoke across both necks
  rect(math.min(x + 19 * facing, x + 23 * facing), y - 15, 5, 2, "wood")
  px(x + 19 * facing, y - 15, "ochre")
end

function K.wagon(x, y, facing)
  -- Conestoga-style emigrant wagon, 46 wide; (x, y) = ground line under left wheel
  K.shadow(x - 2, y + 1, 50)
  -- running gear
  rect(x + 2, y - 10, 42, 2, "deep")
  -- bed
  poly({{x, y - 18}, {x + 46, y - 18}, {x + 44, y - 10}, {x + 2, y - 10}}, "blue")
  rect(x, y - 18, 46, 1, "light_blue")
  rect(x + 1, y - 14, 44, 1, "teal")
  rect(x + 2, y - 11, 42, 1, "ink")
  -- bonnet with bows
  poly({{x + 1, y - 18}, {x - 1, y - 30}, {x + 6, y - 36}, {x + 40, y - 36}, {x + 47, y - 30}, {x + 45, y - 18}}, "cream")
  poly({{x + 1, y - 18}, {x - 1, y - 30}, {x + 6, y - 36}, {x + 10, y - 36}, {x + 6, y - 30}, {x + 6, y - 18}}, "white")
  for _, bx in ipairs({12, 22, 32}) do line(x + bx, y - 35, x + bx + 1, y - 19, "sand") end
  poly({{x + 40, y - 36}, {x + 47, y - 30}, {x + 45, y - 18}, {x + 38, y - 18}, {x + 41, y - 30}}, "clap_sh")
  -- puckered opening
  local ox_ = facing == 1 and x + 44 or x + 1
  rect(ox_ - 1, y - 30, 2, 9, "deep")
  -- wheels: small at front, large at back
  local back, front = x + 10, x + 37
  if facing == -1 then back, front = x + 36, x + 9 end
  K.wheel(back, y - 7, 7)
  K.wheel(front, y - 6, 6)
  -- tongue
  local tx = facing == 1 and x + 46 or x - 12
  rect(tx, y - 7, 12, 1, "wood")
end

function K.person(x, y, coat, hat, skirt)
  K.shadow(x - 2, y + 1, 7)
  if skirt then
    poly({{x, y - 8}, {x + 3, y - 8}, {x + 5, y}, {x - 2, y}}, coat)
    rect(x - 2, y - 1, 7, 1, "deep")
  else
    rect(x, y - 4, 1, 4, "deep"); rect(x + 2, y - 4, 1, 4, "deep")
    rect(x - 1, y, 2, 1, "ink"); rect(x + 2, y, 2, 1, "ink")
  end
  rect(x - 1, y - 10, 5, 6, coat)
  px(x - 1, y - 10, "cream")
  rect(x + 3, y - 9, 1, 4, "ink")
  rect(x, y - 13, 3, 3, "skin"); px(x + 2, y - 11, "skin_dk")
  if hat == "bonnet" then
    rect(x - 1, y - 14, 4, 3, "cream"); px(x - 1, y - 11, "cream")
  else
    rect(x - 1, y - 14, 5, 1, hat); rect(x, y - 16, 3, 2, hat)
  end
end

-- Water lapping over feet and wheels from x0 to x1 at ground line y, `depth` pixels deep
-- (5 is about knee-deep at figure scale). Draw it after the figures that stand in the water.
function K.wade(x0, x1, y, depth, water, light)
  water, light = water or "blue", light or "light_blue"
  depth = depth or 3
  for x = x0 - 3, x1 + 3 do
    -- taper at the ends so the water meets the scene's river without a hard edge
    local edge = math.min(x - (x0 - 3), (x1 + 3) - x)
    local d = math.min(depth, edge + 1)
    if d > 0 then
      for yy = y - d + 1, y + 1 + ((edge > 2) and 1 or 0) do px(x, yy, water) end
      if (x + y) % 3 ~= 0 then px(x, y - d, light) end
      if K.rnd(6) == 0 then px(x, y - d, "white") end
      if K.rnd(4) == 0 then px(x, y - d + 2, light) end
    end
  end
  rect(x0 - 6, y, 3, 1, "white"); rect(x1 + 4, y, 4, 1, light)
end

-- A distant wagon and team about 20 px long, for showing scale against big landforms.
function K.far_wagon(x, y, facing)
  local ox = (facing == -1) and x - 9 or x + 11
  K.rect(x, y - 6, 10, 3, "blue"); K.rect(x, y - 10, 10, 4, "cream"); K.px(x, y - 10, "white")
  K.rect(x + 9, y - 9, 1, 3, "clap_sh")
  K.rect(x + 1, y - 3, 2, 2, "deep"); K.rect(x + 7, y - 3, 2, 2, "deep")
  K.rect(ox, y - 5, 8, 3, "ox_dk"); K.px(ox + ((facing == -1) and 0 or 7), y - 6, "ox_dk")
  K.rect(ox + 1, y - 2, 1, 2, "deep"); K.rect(ox + 6, y - 2, 1, 2, "deep")
  K.rect(x, y - 1, 19, 1, "shadow")
end

function K.barrel(x, y)
  rect(x, y - 7, 6, 7, "wood"); rect(x + 1, y - 7, 2, 7, "rust")
  rect(x, y - 6, 6, 1, "ink"); rect(x, y - 2, 6, 1, "ink")
  rect(x, y - 8, 6, 1, "ochre")
end
function K.crate(x, y)
  rect(x, y - 6, 8, 6, "ochre"); rect(x, y - 6, 8, 1, "gold")
  line(x, y - 1, x + 7, y - 6, "rust"); rect(x + 7, y - 6, 1, 6, "rust")
end

-- Pitched 1840s canvas wedge tent with sunlit left slope, shaded right slope, doorway flap, and guy lines.
function K.tent(cx, y, half_w, h)
  half_w = half_w or 20
  h = h or 26
  K.shadow(cx - half_w - 2, y + 1, half_w * 2 + 5)
  -- Sunlit left slope
  poly({{cx - half_w, y}, {cx, y - h}, {cx + 2, y}}, "cream")
  line(cx - half_w, y, cx, y - h, "white")
  line(cx - math.floor(half_w * 0.55), y, cx - 1, y - h + 3, "sand")
  -- Shaded right slope
  poly({{cx, y - h}, {cx + 2, y}, {cx + half_w, y}}, "sand")
  poly({{cx + math.floor(half_w * 0.35), y - math.floor(h * 0.55)}, {cx + 2, y}, {cx + half_w, y}}, "ochre")
  -- Open tent doorway & pole
  poly({{cx - 4, y}, {cx, y - math.floor(h * 0.58)}, {cx + 4, y}}, "deep")
  poly({{cx - 2, y}, {cx, y - math.floor(h * 0.48)}, {cx + 2, y}}, "ink")
  rect(cx, y - h - 2, 1, h + 2, "wood")
  -- Guy lines & pegs
  line(cx - half_w, y, cx - half_w - 4, y + 1, "clap_sh")
  line(cx + half_w, y, cx + half_w + 4, y + 1, "clap_sh")
  px(cx - half_w - 4, y + 1, "wood")
  px(cx + half_w + 4, y + 1, "wood")
end


-- One-room 1840s log cabin seen side-on, (x, y) = ground under the left corner. Round logs
-- notched at the corners, a clapboard-shake gable roof, a stick-and-clay chimney at the right
-- end, a plank door and one window of greased paper. `stage` builds it up for the cabin
-- overlay: 1 felled logs, 2 walls half raised, 3 walls up and rafters, nil or 4 finished.
-- `snow` lays snow on the roof and the log ends. Width w (about 3 px to a foot), wall height h.
function K.log_cabin(x, y, w, h, stage, snow)
  stage = stage or 4
  local function logs(top)
    for yy = y - 2, top, -3 do
      rect(x, yy - 1, w, 3, "wood")
      rect(x, yy - 1, w, 1, "ochre")
      rect(x, yy + 1, w, 1, "deep")
      for xx = x + 3, x + w - 4, 7 do px(xx + (yy % 2), yy, "ox") end
      -- notched ends stick out past the corners
      rect(x - 2, yy - 1, 2, 3, "ochre"); px(x - 2, yy, "sand")
      rect(x + w, yy - 1, 2, 3, "ox"); px(x + w + 1, yy, "sand")
    end
  end
  K.shadow(x - 3, y + 1, w + 8)
  if stage == 1 then
    -- logs felled and decked, bark on, a few hewn, stumps around
    for i = 0, 2 do
      local ly = y - 1 - i * 3
      rect(x + i * 3, ly - 1, w - i * 6, 3, (i % 2 == 0) and "wood" or "ox")
      rect(x + i * 3, ly - 1, w - i * 6, 1, "ochre")
      ellipse(x + i * 3, ly, 1, 1, "sand"); px(x + i * 3, ly, "ochre")
      ellipse(x + w - i * 3, ly, 1, 1, "sand"); px(x + w - i * 3, ly, "ochre")
    end
    for _, sx in ipairs({x - 10, x + w + 8}) do rect(sx, y - 3, 4, 3, "wood"); rect(sx, y - 3, 4, 1, "sand") end
    for i = 1, 14 do px(x - 6 + rnd(w + 12), y + rnd(2), (rnd(2) == 0) and "sand" or "cream") end
    return
  end
  local top = (stage == 2) and (y - math.floor(h / 2)) or (y - h)
  logs(top)
  if stage == 2 then
    -- a skid log leaned up to roll the next course into place
    line(x + w + 4, y, x + w - 6, top - 2, "wood"); line(x + w + 5, y, x + w - 5, top - 2, "ox")
    return
  end
  -- door and window, cut through the courses
  local dx, dw, dh = x + math.floor(w * 0.3), math.max(4, math.floor(w * 0.15)), math.min(18, h - 2)
  rect(dx, y - dh - 1, dw, dh, "deep"); rect(dx + 1, y - dh, dw - 2, dh - 1, (stage == 3) and "ink" or "wood")
  if stage ~= 3 and dw > 5 then rect(dx + math.floor(dw / 2), y - dh, 1, dh - 1, "deep"); px(dx + dw - 2, y - math.floor(dh / 2), "storm") end
  local wx, ww, wh = x + math.floor(w * 0.62), math.max(3, math.floor(w * 0.13)), math.max(3, math.floor(h * 0.3))
  rect(wx, y - math.floor(h * 0.75), ww, wh, "deep"); rect(wx + 1, y - math.floor(h * 0.75) + 1, ww - 2, wh - 2, (stage == 3) and "ink" or "cream")
  -- gable roof, rafters only while building
  local rise = math.floor(w * 0.18) + 2
  if stage == 3 then
    for xx = x - 2, x + w + 2, 6 do line(xx, top, xx + 2, top - rise, "wood") end
    line(x - 3, top - rise, x + w + 3, top - rise, "ox")
    return
  end
  poly({{x - 4, top + 1}, {x + 4, top - rise}, {x + w - 4, top - rise}, {x + w + 4, top + 1}}, "roof")
  for yy = top - rise + 2, top, 2 do
    for xx = x - 3, x + w + 3, 3 do if (xx + yy) % 6 == 0 then rect(xx, yy, 2, 1, "roof_dk") end end
  end
  line(x - 4, top + 1, x + 4, top - rise, "roof_lt")
  rect(x - 4, top + 1, w + 9, 1, "ink")
  -- stick-and-clay chimney at the right gable end
  local cx = x + w - 6
  rect(cx, top - rise - 6, 6, rise + 7, "ochre")
  for yy = top - rise - 5, top, 2 do rect(cx, yy, 6, 1, "wood") end
  rect(cx + 4, top - rise - 6, 2, rise + 7, "ox")
  if snow then
    -- a blanket of snow over the whole roof, thick at the ridge, sagging over the eaves in
    -- uneven lumps, with a few shakes showing through where wind scoured it
    poly({{x - 5, top}, {x + 3, top - rise - 1}, {x + w - 3, top - rise - 1}, {x + w + 5, top}}, "white")
    rect(x + 3, top - rise - 2, w - 6, 1, "white")
    for xx = x - 4, x + w + 4 do
      local sag = ((xx * 7) % 5 < 2) and 1 or 0
      if (xx * 13) % 11 == 0 then sag = 2 end
      rect(xx, top + 1, 1, sag + 1, "white")
      px(xx, top + 1 + sag, "mist")
    end
    for yy = top - rise + 3, top - 2, 3 do
      for xx = x + 2, x + w - 2, 9 do px(xx + (yy % 4), yy, "cream"); px(xx + (yy % 4) + 1, yy, "cream") end
    end
    for xx = x + 5, x + w - 8, 13 do px(xx, top - math.floor(rise / 2), "roof_dk") end
    line(x + w - 3, top - rise, x + w + 4, top, "mist")
    -- the chimney stands clear of the snow, capped white, its foot buried
    rect(cx, top - rise - 6, 6, rise + 2, "ochre")
    for yy = top - rise - 5, top - rise - 4 + rise, 2 do rect(cx, yy, 6, 1, "wood") end
    rect(cx + 4, top - rise - 6, 2, rise + 2, "ox")
    rect(cx - 1, top - rise - 8, 8, 2, "white"); px(cx - 1, top - rise - 6, "cream")
    rect(cx - 3, top - rise - 1, 3, 2, "white"); px(cx + 6, top - rise, "white")
    -- snow on every protruding log end and along the window sill
    for yy = y - 2, top, -3 do
      rect(x - 2, yy - 2, 2, 1, "white"); rect(x + w, yy - 2, 2, 1, "white")
    end
    rect(wx - 1, y - math.floor(h * 0.75) + wh, ww + 2, 1, "white")
    -- drifts banked against the walls and lying around the cabin
    for xx = x - 8, x + w + 8 do
      local d = 2 + math.floor(1.5 + 1.5 * math.sin(xx / 4))
      if xx < x or xx > x + w then d = math.max(1, d - 2) end
      if xx >= dx and xx < dx + dw then d = 1 end
      rect(xx, y - d + 1, 1, d + 1, "white")
      px(xx, y - d + 1, (xx % 3 == 0) and "cream" or "white")
    end
  end
end

return K
