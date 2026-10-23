-- The trail map: the West of 1848 as a parchment survey map, 616 x 288.
-- Geography is real: art/aseprite/data/map_geo.lua (coast, lakes, rivers and hill shading,
-- made by art/aseprite/tools/make_map_geo.py) and data/map.json (projection, peaks, boundaries).
-- The game draws the roads, the red journey line and the wagon over this picture (ui/map_view.gd).
local K = dofile(app.params.kit)
local HERE = app.params.kit:match("^(.*)[/\\]")
local G = dofile(HERE .. "/data/map_geo.lua")
local f = io.open(HERE .. "/../../data/map.json")
local MAP = json.decode(f:read("a"))
f:close()
local W, H = G.W, G.H
local P = MAP.projection
local SX = W / (P.east - P.west)
local SY = SX / math.cos(math.rad(P.parallel))
local function project(lat, lon)
  return math.floor((lon - P.west) * SX + 0.5), math.floor((P.north - lat) * SY + 0.5)
end
K.canvas(W, H, 1848)

-- Runs of a mask row as a lookup table.
local function mask(rows)
  local m = {}
  for y = 0, H - 1 do
    local row, set = rows[y + 1], {}
    for i = 1, #row, 2 do for x = row[i], row[i] + row[i + 1] - 1 do set[x] = true end end
    m[y] = set
  end
  return m
end
local land, lakes = mask(G.land), mask(G.lakes)
local function is_land(x, y) return y >= 0 and y < H and x >= 0 and x < W and land[y][x] end

local TONE = {"cream", "sand", "dune", "gold", "ochre", "rust"}

K.layer("land", function()
  for y = 0, H - 1 do
    local row, x = G.relief[y + 1], 0
    for i = 1, #row, 2 do
      local c = TONE[row[i]]
      for _ = 1, row[i + 1] do
        if land[y][x] then
          -- Light shade is dithered with the plain so slopes read as hatching, not blotches.
          if c == "gold" and (x + y) % 2 == 0 then c = "sand" end
          K.px(x, y, c)
          c = TONE[row[i]]
        end
        x = x + 1
      end
    end
  end
end)

-- Sea with engraver's water-lining: broken lines following the coast at 2 and 5 pixels out.
K.layer("sea", function()
  local function near(x, y, r)
    for dy = -r, r do for dx = -r, r do
      if is_land(x + dx, y + dy) then return true end
    end end
    return false
  end
  for y = 0, H - 1 do for x = 0, W - 1 do
    if not land[y][x] then
      local c = "sea"
      if not near(x, y, 1) and near(x, y, 2) and (x + y * 3) % 7 ~= 0 then c = "sea_line"
      elseif not near(x, y, 4) and near(x, y, 5) and (x * 2 + y) % 5 ~= 0 then c = "sea_line" end
      K.px(x, y, c)
    end
  end end
end)

-- Parallels and meridians every five degrees, dotted.
K.layer("graticule", function()
  for lon = -125, -95, 5 do
    local x = project(0, lon)
    for y = 0, H - 1, 3 do K.px(x, y, land[y][x] and "ochre" or "sea_line") end
  end
  for lat = 40, 45, 5 do
    local _, y = project(lat, P.west)
    for x = 0, W - 1, 3 do K.px(x, y, land[y][x] and "ochre" or "sea_line") end
  end
end)

K.layer("water", function()
  for _, r in ipairs(G.rivers) do
    local pts, c = r[2], r[1] == 2 and "blue" or "sky"
    for i = 1, #pts - 2, 2 do K.line(pts[i], pts[i + 1], pts[i + 2], pts[i + 3], c) end
  end
  for y = 0, H - 1 do for x = 0, W - 1 do
    if lakes[y][x] then
      local edge = not (lakes[y][x - 1] and lakes[y][x + 1] and (y > 0 and lakes[y - 1][x]) and (y < H - 1 and lakes[y + 1][x]))
      K.px(x, y, edge and "blue" or "sea")
    end
  end end
end)

-- 1848 boundaries as dashes: the 49th parallel, the 42nd (Mexican Cession), Missouri and Iowa.
K.layer("boundaries", function()
  for _, b in ipairs(MAP.boundaries) do
    local step = 0
    for i = 1, #b.line - 1 do
      local x0, y0 = project(b.line[i][1], b.line[i][2])
      local x1, y1 = project(b.line[i + 1][1], b.line[i + 1][2])
      local n = math.max(math.abs(x1 - x0), math.abs(y1 - y0))
      for s = 0, n - 1 do
        local x = math.floor(x0 + (x1 - x0) * s / n + 0.5)
        local y = math.floor(y0 + (y1 - y0) * s / n + 0.5)
        if step % 6 < 3 and is_land(x, y) then K.px(x, y, "deep") end
        step = step + 1
      end
    end
  end
end)

-- Snow-capped volcanoes of the Cascades (and Laramie Peak), lit from the left.
K.layer("peaks", function()
  for _, p in ipairs(MAP.peaks) do
    local x, y = project(p.at[1], p.at[2])
    local volcano = p.name:match("^Mount") ~= nil
    local h = volcano and 7 or 4
    for i = 0, h do
      local half = math.floor(i * 0.6 + 0.5)
      for dx = -half, half do
        local c = dx <= 0 and "stone_lt" or "stone_dk"
        if volcano and i <= 3 then c = dx <= 0 and "white" or "stone_lt" end
        if dx == half then c = "stone_ink" end
        K.px(x + dx, y - h + i, c)
      end
    end
  end
end)

-- Neatline: ink rule with a ruled inner border in the margin, like a printed survey.
K.layer("frame", function()
  for x = 0, W - 1 do K.px(x, 0, "ink"); K.px(x, H - 1, "ink"); K.px(x, 2, "wood"); K.px(x, H - 3, "wood") end
  for y = 0, H - 1 do K.px(0, y, "ink"); K.px(W - 1, y, "ink"); K.px(2, y, "wood"); K.px(W - 3, y, "wood") end
  for x = 1, W - 2 do K.px(x, 1, "cream"); K.px(x, H - 2, "cream") end
  for y = 1, H - 2 do K.px(1, y, "cream"); K.px(W - 2, y, "cream") end
  -- Degree ticks on the inner rule at each whole degree.
  for lon = math.ceil(P.west), math.floor(P.east) do
    local x = project(0, lon)
    if x > 3 and x < W - 4 then K.px(x, 3, "wood"); K.px(x, H - 4, "wood") end
  end
  for lat = math.ceil(P.north - H / SY), math.floor(P.north) do
    local _, y = project(lat, 0)
    if y > 3 and y < H - 4 then K.px(3, y, "wood"); K.px(W - 4, y, "wood") end
  end
end)

K.save("trail_map")
