-- Engraved plates for THE OVERLAND GUIDE (each 216 x 79), one per chapter, printed in the
-- book under the chapter title (ui/guide_book.gd, data/guide.json "plate"). Each plate is cut
-- from one of the game's own pictures, as a period engraver would copy a painting: the
-- picture is reduced to half size, then its light and shade are re-drawn as ink line work on
-- bare paper (transparent, so the page shows through): solid ink in the deepest shadow,
-- cross-hatching, close and open ruled lines, a dotted half-tone, and paper for the lights,
-- with a line wherever the tone breaks sharply. A double ruled border frames it.
-- no seasons
local K = dofile(app.params.kit)
local PIX = app.fs.joinPath(app.fs.filePath(app.params.kit), "..", "pixels")
local W, H = 216, 79
local IX, IY, IW, IH = 4, 4, 208, 71 -- picture inside the border

local function load(name) return Image{fromFile = app.fs.joinPath(PIX, name .. ".png")} end
local function lum(v)
  local pc = app.pixelColor
  return (0.30 * pc.rgbaR(v) + 0.59 * pc.rgbaG(v) + 0.11 * pc.rgbaB(v)) / 255, pc.rgbaA(v)
end

-- Tone grid for the picture area: source (sx, sy) is the top-left of the window, reduced by
-- s (2 for a whole scene, 1 for a close crop of its subject).
local function tones(img, sx, sy, s)
  s = s or 2
  local g = {}
  for y = 0, IH - 1 do
    g[y] = {}
    for x = 0, IW - 1 do
      local sum, n = 0, 0
      for dy = 0, s - 1 do for dx = 0, s - 1 do
        local px, py = sx + x * s + dx, sy + y * s + dy
        if px >= 0 and py >= 0 and px < img.width and py < img.height then
          local l, a = lum(img:getPixel(px, py))
          if a > 0 then sum = sum + l; n = n + 1 end
        end
      end end
      g[y][x] = (n > 0) and sum / n or 1
    end
  end
  return g
end

-- Paste a sprite frame (cell at fx, fy, fw x fh) onto the tone grid at (dx, dy), scale s.
local function overlay(g, img, fx, fy, fw, fh, dx, dy, s)
  for y = 0, fh * s - 1 do
    for x = 0, fw * s - 1 do
      local l, a = lum(img:getPixel(fx + x // s, fy + y // s))
      local gx, gy = dx + x, dy + y
      if a > 0 and gy >= 0 and gy < IH and gx >= 0 and gx < IW then g[gy][gx] = l end
    end
  end
end

local function blank()
  local g = {}
  for y = 0, IH - 1 do g[y] = {}; for x = 0, IW - 1 do g[y][x] = 1 end end
  return g
end

-- Stretch the plate's tones so its darkest twentieth is ink and its lightest is paper,
-- then lift the middle tones: engravers left skies and lit ground nearly bare.
local function stretch(g)
  local all = {}
  for y = 0, IH - 1 do for x = 0, IW - 1 do all[#all + 1] = g[y][x] end end
  table.sort(all)
  local lo, hi = all[math.floor(#all * 0.04) + 1], all[math.floor(#all * 0.96)]
  if hi - lo < 0.05 then return end
  for y = 0, IH - 1 do for x = 0, IW - 1 do
    local t = math.max(0, math.min(1, (g[y][x] - lo) / (hi - lo)))
    g[y][x] = t ^ 0.7
  end end
end

local function engrave(g)
  stretch(g)
  for y = 0, IH - 1 do
    for x = 0, IW - 1 do
      local l = g[y][x]
      local c
      if l < 0.16 then c = "deep"
      elseif l < 0.32 then if y % 2 == 0 or (x + y) % 4 == 0 then c = "deep" end
      elseif l < 0.48 then if y % 2 == 0 then c = "deep" end
      elseif l < 0.62 then if y % 3 == 0 then c = "deep" end
      elseif l < 0.76 then if y % 4 == 0 and x % 2 == 0 then c = "wood" end
      end
      -- a line where the tone breaks sharply, on the darker side
      local r = (x + 1 < IW) and g[y][x + 1] or l
      local d = (y + 1 < IH) and g[y + 1][x] or l
      if (r - l > 0.22) or (d - l > 0.22) then c = "deep" end
      if c then K.px(IX + x, IY + y, c) end
    end
  end
  -- double ruled border
  for _, i in ipairs({0, 2}) do
    K.rect(i, i, W - i * 2, 1, "deep"); K.rect(i, H - 1 - i, W - i * 2, 1, "deep")
    K.rect(i, i, 1, H - i * 2, "deep"); K.rect(W - 1 - i, i, 1, H - i * 2, "deep")
  end
end

-- name, source picture, crop origin (x, y) in the source, reduction (2 = whole scene halved,
-- 1 = a close crop of the subject at full size)
local PLATES = {
  {"preface", "location_independence", 0, 0},
  {"outfit", "location_store", 30, 100, 1},
  {"mounts", "encounter_grande_ronde", 200, 72, 1},
  {"road", "location_chimney_rock", 8, 4},
  {"rivers", "location_kansas_river", 8, 4},
  {"camp", "location_camp", 100, 74, 1},
  {"keeping", "encounter_the_dalles", 40, 79, 1},
  {"provisions", "location_big_blue", 150, 79, 1},
  {"winter", "location_barlow_pass_winter", 8, 4},
  {"trade", "location_trader_camp", 100, 70},
  {"natives", "encounter_umatilla", 20, 79, 1},
  {"callings", "location_town_setup", 100, 60},
  {"law", "location_jail_county", 8, 4},
  {"fighting", "event_bandits", 90, 72, 1},
}
for _, p in ipairs(PLATES) do
  K.canvas(W, H, 1847)
  local g = tones(load(p[2]), p[3], p[4], p[5])
  K.layer("plate", function() engrave(g) end)
  K.save("guide_plate_" .. p[1])
end

-- Dogs: a farm shepherd sitting at the edge of an elm grove.
K.canvas(W, H, 1847)
do
  local g = tones(load("location_elm_grove"), 8, 4)
  local dog = load("dog")
  overlay(g, dog, 0, 0, 48, 44, 120, 20, 1)
  K.layer("plate", function() engrave(g) end)
end
K.save("guide_plate_dogs")

-- Sickness: a grave by the road, with a wagon going on past it.
K.canvas(W, H, 1847)
do
  local g = blank()
  for y = 0, IH - 1 do for x = 0, IW - 1 do
    if y < 30 then g[y][x] = 0.9
    elseif y < 34 then g[y][x] = 0.55 + 0.1 * math.sin(x / 9)
    else g[y][x] = 0.58 end
  end end
  -- the road, bare and pale, rising to the right
  for x = 0, IW - 1 do
    local cy = math.floor(60 - x * 0.12)
    for y = cy - 3, cy + 3 do if y >= 0 and y < IH then g[y][x] = 0.95 end end
  end
  -- the grave: a low mound of earth, stones round it, a headboard
  for y = -5, 5 do for x = -17, 17 do
    if (x * x) / 289 + (y * y) / 25 <= 1 and 54 + y < IH then g[54 + y][58 + x] = (y < -2) and 0.4 or 0.28 end
  end end
  for _, st in ipairs({{40, 56}, {44, 59}, {72, 58}, {76, 55}, {58, 60}, {50, 60}}) do
    g[st[2]][st[1]] = 0.05; g[st[2]][st[1] + 1] = 0.05
  end
  for y = 32, 52 do g[y][70] = 0.05; g[y][71] = 0.05; g[y][72] = 0.12 end
  for x = 64, 78 do g[38][x] = 0.05; g[39][x] = 0.12 end
  -- a wagon and its team going on, at half size
  local wagon, oxen = load("wagon"), load("oxen")
  for y = 0, 31 do for x = 0, 47 do
    local l, a = lum(wagon:getPixel(x * 2, y * 2))
    if a > 0 and 12 + y < IH then g[12 + y][128 + x] = l end
  end end
  for y = 0, 15 do for x = 0, 23 do
    local l, a = lum(oxen:getPixel(x * 2, y * 2))
    if a > 0 then g[28 + y][174 + x] = l end
  end end
  K.layer("plate", function() engrave(g) end)
end
K.save("guide_plate_sickness")

-- Arms: the period kit laid out as a still life, each piece at twice size.
K.canvas(W, H, 1847)
do
  local g = blank()
  local arms = load("weapon_icons")
  for i = 0, 5 do overlay(g, arms, i * 16, 0, 16, 16, 8 + i * 33, 19, 2) end
  K.layer("plate", function() engrave(g) end)
end
K.save("guide_plate_arms")
