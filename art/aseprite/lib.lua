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
  far_hill="9fbfae", shadow="8a5e3e", skin="e0a878", skin_dk="b77f58",
  red="9e3f33", ox_dk="5a3a2a", ox="7d5536", ox_lt="a77a4f", ox_white="e8dcc0",
  stone_lt="dcd5bc", stone="bfb79c", stone_dk="908a72", stone_ink="66614f",
  silt_lt="c4b08a", silt="a38b64", silt_dk="7f6b4c",
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

-- Write <out>/<name>.png (flattened) and <out>/<name>.aseprite (layered).
function K.save(name)
  local out = app.params.out or "."
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
    spr:saveCopyAs(out .. "/" .. file .. ".png")
    print("built " .. file .. " (layer " .. layer_name .. ")")
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
  ellipse(x, y - 3 * s, 6 * s, 4 * s, "pine")
  ellipse(x - 1, y - 4 * s, 5 * s, 3 * s, "leaf")
  ellipse(x - 2, y - 5 * s, 3 * s, 2 * s, "grass")
  px(x - 3 * s, y - 6 * s, "sage")
end

-- Columnar basalt cliff face from x to x + w, rim at y, down to y + h.
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
  for _, c in ipairs(clumps) do ellipse(x + c[1] * s, y + c[2] * s, c[3] * s, c[4] * s, "pine") end
  for _, c in ipairs(clumps) do ellipse(x + c[1] * s - 1, y + c[2] * s - 1, c[3] * s - 2, c[4] * s - 2, "leaf") end
  for _, c in ipairs(clumps) do ellipse(x + c[1] * s - 2, y + c[2] * s - 2, math.max(1, c[3] * s - 5), math.max(1, c[4] * s - 4), "grass") end
  for _, c in ipairs(clumps) do px(x + c[1] * s - 3, y + c[2] * s - 3, "sage") end
end

-- Tall western conifer (ponderosa pine / Douglas fir) with layered boughs, lit from upper-left.
function K.conifer(x, y, h, coat_dk, coat_mid, coat_lt)
  coat_dk  = coat_dk  or "ink"
  coat_mid = coat_mid or "pine"
  coat_lt  = coat_lt  or "leaf"
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
  end
  px(x, y - h - 1, coat_lt)
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


return K
