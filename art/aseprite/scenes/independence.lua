-- Independence, Missouri, 1848: the courthouse square on outfitting day.
-- no seasons: build.sh --seasons skips this script (indoors, a trading counter, or its own season).
-- 432x150 arrival scene, light from the upper left. Build with art/aseprite/build.ps1 (or build.sh).
-- Composition follows the circa-1853 engraving noted in art/LOCATION_REFERENCES.md:
-- a brick courthouse with cupola, low frame and brick stores, wagons and people on the square.
local K = dofile(app.params.kit)
local W, H = 432, 150
local HORIZON = 74
local STREET = 100

K.canvas(W, H, 1848)

----------------------------------------------------------------- sky
K.layer("sky", function()
  K.rect(0, 0, W, 22, "sky_top")
  K.blend(0, 22, W, "sky_top", "sky")
  K.rect(0, 25, W, 20, "sky")
  K.blend(0, 45, W, "sky", "light_blue")
  K.rect(0, 48, W, 16, "light_blue")
  K.blend(0, 64, W, "light_blue", "mist")
  K.rect(0, 67, W, HORIZON - 67, "mist")
  K.cloud(40, 16, 1.4)
  K.cloud(300, 10, 1.1)
  K.cloud(392, 30, 0.6)
end)

----------------------------------------------------------------- distance

----------------------------------------------------------------- distance
K.layer("distance", function()
  -- far hazy ridge
  for x = 0, W - 1 do
    local h = math.floor(4 + 3 * math.sin(x / 37) + 2 * math.sin(x / 13 + 1))
    for y = HORIZON - h, HORIZON + 2 do K.px(x, y, "far_hill") end
  end
  -- tree line along the Missouri bottoms
  for x = -4, W + 4, 5 do
    local r = 3 + K.rnd(3)
    local cy = HORIZON - 1 + K.rnd(2)
    K.ellipse(x, cy, r + 1, r, "haze")
    K.ellipse(x - 1, cy - 1, r - 1, r - 2, "mist")
  end
  -- meadow between town and trees
  K.rect(0, HORIZON + 2, W, STREET - HORIZON - 2, "sage")
  for i = 1, 500 do
    local x, y = K.rnd(W), HORIZON + 3 + K.rnd(STREET - HORIZON - 3)
    K.px(x, y, (i % 3 == 0) and "gold" or "grass")
  end
end)

----------------------------------------------------------------- buildings
K.layer("buildings", function()
  -- far left: two-storey frame outfitter with shutters
  local x, y = 6, 50
  K.side_wall(x + 64, y, 7, 46, "clap_sh", "ochre")
  K.clapboard(x, y, 64, 46, "sand", "clap_sh")
  K.rect(x, y, 2, 46, "cream")
  K.hip_roof(x, y, 64, 7, 12)
  K.chimney(x + 10, y - 6, 7)
  K.windows(x, y + 6, 64, 4, "ochre", "teal")
  K.windows(x, y + 26, 30, 1, "ochre", "teal")
  K.door(x + 41, y + 46, 15)
  K.sign(x + 8, y + 18, 48, "cream", 14)
  -- porch roof
  K.poly({{x - 2, y + 25}, {x + 66, y + 25}, {x + 70, y + 29}, {x - 6, y + 29}}, "roof")
  K.rect(x - 6, y + 29, 76, 1, "roof_dk")
  for px_ = x - 4, x + 68, 12 do K.rect(px_, y + 30, 2, 16, "cream"); K.px(px_ + 1, y + 30, "clap_sh") end

  -- left: brick store, gable end to the street
  x, y = 86, 58
  K.side_wall(x + 44, y, 6, 38, "brick_dk")
  K.bricks(x, y, 44, 38)
  K.poly({{x - 2, y}, {x + 22, y - 16}, {x + 46, y}}, "roof")
  K.line(x - 2, y, x + 22, y - 16, "roof_lt")
  K.poly({{x + 22, y - 16}, {x + 28, y - 19}, {x + 52, y - 3}, {x + 46, y}}, "roof_dk")
  K.rect(x - 2, y, 49, 1, "ink")
  K.rect(x + 19, y - 9, 6, 5, "sand"); K.rect(x + 20, y - 8, 4, 3, "blue")
  K.windows(x, y + 5, 44, 3, "brick_dk", nil)
  K.rect(x + 2, y + 18, 40, 2, "brick_dk")
  K.windows(x, y + 22, 18, 1, "brick_dk", nil)
  K.door(x + 26, y + 38, 14)
  K.sign(x + 4, y + 15, 36, "gold", 10)

  -- centre: the brick courthouse with its cupola
  x, y = 170, 48
  local w = 92
  K.side_wall(x + w, y, 9, 48, "brick_dk")
  K.bricks(x, y, w, 48)
  -- pilasters
  for _, ox in ipairs({0, 30, 60, 88}) do K.rect(x + ox, y, 4, 48, "brick_lt"); K.rect(x + ox + 3, y, 1, 48, "brick_dk") end
  K.rect(x, y + 22, w, 2, "sand")
  K.windows(x + 4, y + 6, 26, 2, "brick_dk", nil)
  K.windows(x + 34, y + 6, 26, 2, "brick_dk", nil)
  K.windows(x + 64, y + 6, 24, 2, "brick_dk", nil)
  K.windows(x + 4, y + 30, 26, 2, "brick_dk", nil)
  K.windows(x + 64, y + 30, 24, 2, "brick_dk", nil)
  -- entrance with steps and pediment
  K.door(x + 43, y + 48, 18)
  K.poly({{x + 37, y + 29}, {x + 46, y + 24}, {x + 55, y + 29}}, "sand")
  K.rect(x + 38, y + 48, 16, 1, "clap_sh"); K.rect(x + 36, y + 49, 20, 1, "sand")
  K.hip_roof(x, y, w, 9, 15)
  K.chimney(x + 8, y - 8, 8)
  K.chimney(x + w - 10, y - 11, 8)
  -- cupola, its base set into the roof ridge
  local cx = x + w / 2 + 2
  local cy = y + 6
  K.rect(cx - 7, cy - 22, 15, 6, "roof_dk")
  K.rect(cx - 7, cy - 22, 15, 1, "sand")
  K.rect(cx - 8, cy - 23, 17, 1, "cream")
  K.rect(cx - 7, cy - 32, 15, 9, "sand")
  K.rect(cx + 6, cy - 32, 2, 9, "clap_sh")
  K.rect(cx - 5, cy - 30, 3, 6, "deep"); K.rect(cx + 1, cy - 30, 3, 6, "deep")
  K.rect(cx - 9, cy - 33, 19, 2, "cream")
  K.poly({{cx - 9, cy - 33}, {cx, cy - 44}, {cx + 10, cy - 33}}, "roof")
  K.line(cx - 9, cy - 33, cx, cy - 44, "roof_lt")
  K.line(cx, cy - 48, cx, cy - 44, "deep")
  -- weathervane rather than a cross: this is a courthouse, not a church
  K.rect(cx - 3, cy - 48, 7, 1, "deep"); K.px(cx + 2, cy - 49, "deep"); K.px(cx + 2, cy - 47, "deep")
  K.px(cx - 3, cy - 49, "deep"); K.px(cx - 3, cy - 47, "deep")
  K.px(cx, cy - 50, "gold")

  -- right: long low frame warehouse with gallery
  x, y = 282, 62
  K.side_wall(x + 70, y, 6, 34, "clap_sh", "ochre")
  K.clapboard(x, y, 70, 34, "cream", "sand")
  K.rect(x, y, 2, 34, "white")
  K.poly({{x - 3, y}, {x + 4, y - 10}, {x + 72, y - 13}, {x + 79, y - 3}, {x + 73, y}}, "roof_lt")
  for yy = y - 9, y - 1, 2 do K.line(x - 2, yy, x + 76, yy - 2, "roof") end
  K.rect(x - 3, y, 77, 1, "roof_dk")
  K.windows(x, y + 5, 70, 4, "sand", "red")
  K.door(x + 12, y + 34, 13); K.door(x + 50, y + 34, 13)
  K.sign(x + 22, y + 15, 26, "gold", 7)
  -- awning
  K.poly({{x + 2, y + 15}, {x + 68, y + 15}, {x + 72, y + 20}, {x - 2, y + 20}}, "red")
  for xx = x - 1, x + 70, 6 do K.rect(xx, y + 16, 3, 4, "cream") end
  K.rect(x - 2, y + 20, 74, 1, "deep")
  for xx = x, x + 68, 17 do K.rect(xx, y + 21, 1, 13, "wood") end

  -- far right: log cabin smithy
  x, y = 370, 72
  K.side_wall(x + 40, y, 5, 24, "wood")
  K.rect(x, y, 40, 24, "wood")
  for yy = y + 1, y + 23, 3 do K.rect(x, yy, 40, 2, "rust"); K.px(x, yy, "ochre"); K.px(x + 39, yy, "deep") end
  K.poly({{x - 4, y}, {x + 20, y - 12}, {x + 44, y}}, "roof")
  K.line(x - 4, y, x + 20, y - 12, "roof_lt")
  K.poly({{x + 20, y - 12}, {x + 25, y - 15}, {x + 49, y - 3}, {x + 44, y}}, "roof_dk")
  K.rect(x - 4, y, 49, 1, "ink")
  K.chimney(x + 30, y - 5, 10)
  -- glowing forge door
  K.rect(x + 8, y + 9, 12, 15, "ink")
  K.rect(x + 10, y + 16, 8, 8, "rust"); K.rect(x + 12, y + 18, 4, 5, "gold")
  -- smoke
  for i, p in ipairs({{32, -18, 2}, {34, -23, 3}, {37, -29, 3}, {41, -36, 4}}) do
    K.ellipse(x + p[1], y + p[2], p[3], p[3] - 1, "mist")
    K.px(x + p[1] - 1, y + p[2] - 1, "white")
  end
end)

----------------------------------------------------------------- trees
K.layer("trees", function()
  K.elm(150, 97, 1)
  K.elm(276, 97, 1)
  K.elm(424, 98, 1)
end)

----------------------------------------------------------------- street
K.layer("street", function()
  -- boardwalk and grass verge
  K.rect(0, STREET - 4, W, 2, "grass")
  K.rect(0, STREET - 2, W, 3, "wood")
  K.rect(0, STREET - 2, W, 1, "rust")
  for xx = 0, W - 1, 7 do K.px(xx, STREET - 1, "deep"); K.px(xx, STREET, "deep") end
  -- the dusty square
  K.rect(0, STREET + 1, W, H - STREET - 1, "ochre")
  K.dither(0, STREET + 1, W, 2, "dirt_dk", "ochre")
  -- wagon ruts curving toward the trail west (left)
  for i = 0, 2 do
    local y0 = STREET + 14 + i * 13
    for x = 0, W - 1 do
      local y = math.floor(y0 + 6 * math.sin(x / 70 + i))
      K.px(x, y, "dirt_dk"); if x % 3 ~= 0 then K.px(x, y + 1, "rust") end
      K.px(x, y + 5, "dirt_dk")
    end
  end
  -- grit
  for i = 1, 900 do
    local x, y = K.rnd(W), STREET + 3 + K.rnd(H - STREET - 3)
    if K.at(x, y) == "ochre" then K.px(x, y, (i % 3 == 0) and "gold" or ((i % 3 == 1) and "rust" or "sand")) end
  end
  -- hitching rail in front of the stores
  K.rect(4, STREET + 2, 140, 1, "deep")
  for xx = 4, 144, 20 do K.rect(xx, STREET + 2, 2, 6, "deep"); K.px(xx, STREET + 2, "wood") end
end)

----------------------------------------------------------------- figures
K.layer("figures", function()
  -- goods stacked on the boardwalk
  K.barrel(22, STREET + 1); K.barrel(29, STREET + 1); K.crate(36, STREET + 1)
  K.crate(300, STREET + 1); K.crate(308, STREET + 1); K.barrel(318, STREET + 1)
  K.barrel(354, STREET + 1)
  -- a wagon loading at the outfitter, team resting
  K.wagon(56, 128, 1)
  K.team(110, 128, 1, {"dark"}, {"light", true})
  K.line(102, 121, 129, 114, "deep")
  -- a second wagon heading west, team in front (left)
  K.wagon(322, 141, -1)
  K.team(316, 141, -1, {"red"}, {"dark", true})
  K.line(310, 134, 297, 127, "deep")
  -- a parked wagon beside the courthouse, unhitched
  K.wagon(240, 113, -1)
  -- townsfolk and emigrants
  K.person(48, 128, "blue", "deep")
  K.person(160, 124, "red", "bonnet", true)
  K.person(167, 125, "wood", "roof")
  K.person(206, 107, "teal", "deep")
  K.person(224, 108, "sand", "wood")
  K.person(356, 140, "deep", "roof")      -- driver walking by his team
  K.person(240, 145, "wood", "deep")
  K.person(386, 118, "red", "bonnet", true)
  K.person(393, 120, "blue", "rust")
  -- a dog
  K.rect(206, 140, 6, 3, "wood"); K.rect(211, 138, 3, 3, "wood"); K.px(213, 139, "ink")
  K.px(206, 139, "wood"); K.rect(206, 143, 1, 1, "deep"); K.rect(211, 143, 1, 1, "deep")
end)

K.save("location_independence")
