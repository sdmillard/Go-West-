-- City of Rocks (432x150).
-- Granite towers and domes stand over the road like a ruined town, grey and weather-rounded,
-- with juniper and mountain mahogany in the gaps and sage on the flats between. The
-- California companies wrote their names on the rocks in axle grease. Granite Pass is beyond.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 185101)

-- a weathered granite formation: rounded knobs and slabs piled on one another, each lit on
-- its upper left, with dark joints where they meet. blobs = {{dx, dy, rx, ry}, ...} from the
-- foot up, relative to (cx, base).
local function formation(cx, base, blobs)
  for _, b in ipairs(blobs) do
    local x, y, rx, ry = cx + b[1], base + b[2], b[3], b[4]
    K.ellipse(x, y, rx, ry, "stone_ink")
    K.ellipse(x, y, rx - 1, ry - 1, "stone_dk")
    K.ellipse(x - 1, y - 1, math.max(1, rx - 2), math.max(1, ry - 2), "stone")
    K.ellipse(x - math.max(1, rx // 3), y - math.max(1, ry // 3), math.max(1, rx // 2), math.max(1, ry // 2), "stone_lt")
    -- weathering pits and streaks
    for i = 1, rx * ry // 6 do
      local px, py = x - rx + K.rnd(2 * rx), y - ry + K.rnd(2 * ry)
      local c = K.at(px, py)
      if c == "stone" or c == "stone_lt" then K.px(px, py, (K.rnd(3) == 0) and "stone_dk" or "clap_sh") end
    end
  end
end
-- a granite tower: one mass with a lumpy weathered outline and a rounded crown, lit on the
-- west, with a few wandering joint cracks; knobs = extra rounded lumps on its shoulders
local function tower(cx, base, w, h, seed, knobs)
  local cracks = {}
  for k = 1, 2 + seed % 2 do cracks[k] = {(seed * 13 + k * 17) % (2 * w) - w, base - h + 4 + (seed * k * 7) % 8} end
  for yy = 0, h do
    local y = base - h + yy
    local hw
    if yy < w then hw = math.sqrt(math.max(0, w * w - (w - yy) * (w - yy))) else hw = w end
    hw = hw + 1.6 * math.sin(yy / 4.3 + seed) + 1.1 * math.sin(yy / 1.9 + seed * 2) + (yy > h - 6 and (yy - h + 6) * 0.8 or 0)
    local off = math.floor(1.5 * math.sin(yy / 9 + seed))
    hw = math.max(1, math.floor(hw + 0.5))
    for x = cx + off - hw, cx + off + hw do
      local f = (x - (cx + off - hw)) / math.max(1, 2 * hw)
      local c = (f < 0.28) and "stone_lt" or ((f < 0.7) and "stone" or "stone_dk")
      if yy < 3 and f < 0.65 then c = "stone_lt" end
      local n = (x * 37 + y * 11 + seed * 7) % 29
      if n == 0 then c = "stone_dk" elseif n == 1 then c = "clap_sh" end
      K.px(x, y, c)
    end
    K.px(cx + off + hw, y, "stone_ink")
    for _, ck in ipairs(cracks) do
      if y >= ck[2] and (y + seed) % 11 ~= 0 then
        local x = cx + off + math.floor(ck[1] * hw / w + math.sin(y / 6 + ck[1]))
        if K.at(x, y) and K.at(x, y):sub(1, 5) == "stone" then K.px(x, y, "stone_ink"); K.px(x - 1, y, "stone_lt") end
      end
    end
  end
  for _, k in ipairs(knobs or {}) do
    local x, y, r = cx + k[1], base - h + k[2], k[3]
    K.ellipse(x, y, r, r, "stone_dk"); K.ellipse(x - 1, y - 1, r - 1, r - 1, "stone"); K.ellipse(x - 2, y - 2, math.max(1, r // 2), math.max(1, r // 2), "stone_lt")
  end
end

local function juniper(x, y, s)
  K.rect(x, y - 3, 1, 3, "deep")
  K.ellipse(x, y - 5 * s, 3 * s, 4 * s, "pine")
  K.ellipse(x - 1, y - 6 * s, 2 * s, 2 * s, "teal")
  K.px(x - 2, y - 7 * s, "haze")
end

K.layer("sky", function()
  K.sky(W, 82, {{60, 12, 0.7}, {250, 6, 1.0}, {380, 22, 0.6}}, "mist")
end)

K.layer("hills", function()
  -- Granite Pass and the Albion range behind, sage and juniper on their flanks
  K.ridge(0, W - 1, 0, 92, function(x) return -(56 - 10 * math.abs(math.sin(x / 47 + 0.5)) - 5 * math.sin(x / 19)) end, "far_hill", "mist", "haze")
  K.ridge(0, W - 1, 0, 96, function(x) return -(70 - 6 * math.sin(x / 33 + 1) - 2 * math.sin(x / 9)) end, "haze", "far_hill", "teal")
  for x = 4, W, 13 do if (x * 7) % 5 < 3 then juniper(x, 74 + math.floor(4 * math.sin(x / 33 + 1)) + x % 6, 1) end end
end)

K.layer("flat", function()
  K.rect(0, 88, W, H - 88, "silt_lt")
  for i = 1, 1500 do K.px(K.rnd(W), 88 + K.rnd(H - 88), ({"sage", "silt", "sand", "clap_sh", "grass"})[i % 5 + 1]) end
  local road = K.smooth({{-8, 118, 3}, {80, 116, 3}, {170, 124, 4}, {260, 132, 5}, {340, 138, 5}, {440, 146, 6}})
  K.ribbon(road, "silt", 1); K.ribbon(road, "clap_sh", 0)
end)

K.layer("rocks", function()
  -- the "city": spires and domes at several distances
  tower(250, 92, 5, 16, 1)
  tower(206, 95, 9, 30, 2, {{-6, 10, 4}})
  tower(30, 99, 12, 40, 3, {{9, 12, 5}}); tower(56, 101, 8, 24, 4)
  formation(92, 102, {{0, -7, 16, 8}, {-5, -15, 10, 7}, {7, -17, 7, 6}})
  tower(124, 100, 14, 54, 5, {{-10, 16, 6}, {11, 22, 5}}); tower(150, 102, 9, 32, 6)
  tower(304, 104, 17, 62, 7, {{14, 18, 7}, {-13, 30, 6}}); tower(334, 106, 10, 38, 8)
  formation(272, 106, {{0, -6, 13, 7}, {4, -13, 8, 6}})
  tower(392, 102, 12, 44, 9, {{-8, 14, 5}}); tower(418, 104, 7, 24, 10)
  for _, b in ipairs({{64, 104, 6, 3}, {160, 106, 5, 2}, {350, 108, 6, 3}, {230, 140, 7, 3}, {20, 136, 5, 2}}) do
    K.ellipse(b[1], b[2], b[3], b[4], "stone"); K.ellipse(b[1] - 1, b[2] - 1, b[3] - 2, b[4] - 1, "stone_lt"); K.rect(b[1] - b[3] + 1, b[2] + b[4], b[3] * 2 - 1, 1, "stone_ink")
  end
  -- grease names on the big tower
  for i = 0, 3 do K.rect(292 + i * 4, 76 + (i % 2) * 5, 3, 1, "ink") end
  for _, j in ipairs({{12, 100}, {72, 102}, {108, 100}, {160, 98}, {186, 102}, {280, 104}, {346, 104}, {372, 100}, {426, 104}}) do juniper(j[1], j[2], 1 + (j[1] % 3 == 0 and 1 or 0)) end
  for _, s in ipairs({{40, 128}, {96, 140}, {150, 112}, {200, 146}, {280, 120}, {380, 124}, {420, 132}, {60, 112}}) do K.sage(s[1], s[2]) end
end)

K.layer("figures", function()
  K.wagon(236, 134, 1)
  K.team(286, 130, 1, {"red"}, {"light", true})
  K.person(226, 136, "blue", "hat")
  K.person(284, 100, "red", "hat") -- writing on the rock
  K.far_wagon(70, 116, 1)
end)

-- winter: snow on the pale desert ground as well as the grass
K.season_extra = {{season="winter", y0=86, y1=150, map={silt_lt="white", clap_sh="white", sand="stone_lt", silt="stone_lt"}}}
K.save("location_city_of_rocks")
