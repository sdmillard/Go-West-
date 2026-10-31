-- Town Preparation Screen, Independence, Missouri, 1848 (622x273 setup scene).
-- no seasons: build.sh --seasons skips this script (indoors, a trading counter, or its own season).
-- Wide outfitting panorama companion to scenes/independence.lua.
-- Note: ui/departure_view.gd places the party setup panel on (0..259, 0..273)
-- and the companion editor on (267..622, 0..230), leaving the lower-right street
-- strip (260..622, 230..273) and centre gap visible during setup while keeping
-- the full 622x273 canvas a complete, cohesive town square illustration.
local K = dofile(app.params.kit)
local W, H = 622, 273
local HORIZON = 128
local STREET = 168

K.canvas(W, H, 1848)

----------------------------------------------------------------- 1. Sky
K.layer("sky", function()
  K.rect(0, 0, W, 36, "sky_top")
  K.blend(0, 36, W, "sky_top", "sky")
  K.rect(0, 39, W, 36, "sky")
  K.blend(0, 75, W, "sky", "light_blue")
  K.rect(0, 78, W, 28, "light_blue")
  K.blend(0, 106, W, "light_blue", "mist")
  K.rect(0, 109, W, HORIZON - 109 + 2, "mist")

  K.cloud(52, 24, 1.6)
  K.cloud(224, 18, 1.3)
  K.cloud(418, 22, 1.5)
  K.cloud(542, 44, 0.9)
end)

----------------------------------------------------------------- 2. Distant Missouri Hills & Meadow
K.layer("distance", function()
  for x = 0, W - 1 do
    local h = math.floor(6 + 4 * math.sin(x / 48.0) + 2 * math.sin(x / 17.0 + 1))
    for y = HORIZON - h, HORIZON + 2 do K.px(x, y, "far_hill") end
  end
  for x = -4, W + 4, 6 do
    local r = 3 + K.rnd(3)
    local cy = HORIZON - 1 + K.rnd(2)
    K.ellipse(x, cy, r + 1, r, "haze")
    K.ellipse(x - 1, cy - 1, r - 1, r - 2, "mist")
  end
  K.rect(0, HORIZON + 2, W, STREET - HORIZON - 2, "sage")
  for i = 1, 900 do
    local x, y = K.rnd(W), HORIZON + 3 + K.rnd(STREET - HORIZON - 3)
    K.px(x, y, (i % 3 == 0) and "gold" or "grass")
  end
end)

----------------------------------------------------------------- 3. Courthouse Square Buildings
K.layer("buildings", function()
  -- Far left: two-storey frame outfitter with shutters
  local x, y = 24, 112
  K.side_wall(x + 76, y, 8, 52, "clap_sh", "ochre")
  K.clapboard(x, y, 76, 52, "sand", "clap_sh")
  K.rect(x, y, 2, 52, "cream")
  K.hip_roof(x, y, 76, 8, 14)
  K.chimney(x + 12, y - 7, 8)
  K.windows(x, y + 7, 76, 4, "ochre", "teal")
  K.windows(x, y + 32, 36, 2, "ochre", "teal")
  K.door(x + 50, y + 52, 16)
  K.sign(x + 10, y + 20, 56, "cream", 16)
  -- Porch roof and posts
  K.poly({{x - 2, y + 28}, {x + 78, y + 28}, {x + 82, y + 32}, {x - 6, y + 32}}, "roof")
  K.rect(x - 6, y + 32, 88, 1, "roof_dk")
  for px_ = x - 4, x + 80, 14 do K.rect(px_, y + 33, 2, 19, "cream"); K.px(px_ + 1, y + 33, "clap_sh") end

  -- Left-centre: brick dry-goods store
  x, y = 132, 120
  K.side_wall(x + 54, y, 7, 44, "brick_dk")
  K.bricks(x, y, 54, 44)
  K.poly({{x - 2, y}, {x + 27, y - 18}, {x + 56, y}}, "roof")
  K.line(x - 2, y, x + 27, y - 18, "roof_lt")
  K.poly({{x + 27, y - 18}, {x + 34, y - 21}, {x + 63, y - 3}, {x + 56, y}}, "roof_dk")
  K.rect(x - 2, y, 59, 1, "ink")
  K.windows(x, y + 6, 54, 3, "brick_dk", nil)
  K.windows(x, y + 26, 24, 1, "brick_dk", nil)
  K.door(x + 34, y + 44, 15)
  K.sign(x + 6, y + 17, 42, "gold", 12)

  -- Centre: Independence Brick Courthouse with Cupola
  x, y = 244, 106
  local w = 108
  K.side_wall(x + w, y, 10, 58, "brick_dk")
  K.bricks(x, y, w, 58)
  for _, ox in ipairs({0, 35, 70, 104}) do
    K.rect(x + ox, y, 4, 58, "brick_lt")
    K.rect(x + ox + 3, y, 1, 58, "brick_dk")
  end
  K.rect(x, y + 26, w, 2, "sand")
  K.windows(x + 4, y + 8, 30, 2, "brick_dk", nil)
  K.windows(x + 39, y + 8, 30, 2, "brick_dk", nil)
  K.windows(x + 74, y + 8, 30, 2, "brick_dk", nil)
  K.windows(x + 4, y + 34, 30, 2, "brick_dk", nil)
  K.windows(x + 74, y + 34, 30, 2, "brick_dk", nil)
  K.door(x + 51, y + 58, 20)
  K.poly({{x + 44, y + 35}, {x + 54, y + 29}, {x + 64, y + 35}}, "sand")
  K.hip_roof(x, y, w, 10, 17)
  K.chimney(x + 10, y - 9, 9)
  K.chimney(x + w - 12, y - 12, 9)
  -- Cupola
  local cx = x + w / 2 + 2
  local cy = y + 5
  K.rect(cx - 8, cy - 24, 17, 6, "roof_dk")
  K.rect(cx - 8, cy - 24, 17, 1, "sand")
  K.rect(cx - 9, cy - 25, 19, 1, "cream")
  K.rect(cx - 8, cy - 35, 17, 10, "sand")
  K.rect(cx + 7, cy - 35, 2, 10, "clap_sh")
  K.rect(cx - 6, cy - 33, 3, 7, "deep"); K.rect(cx + 1, cy - 33, 3, 7, "deep")
  K.rect(cx - 10, cy - 36, 21, 2, "cream")
  K.poly({{cx - 10, cy - 36}, {cx, cy - 48}, {cx + 11, cy - 36}}, "roof")
  K.line(cx - 10, cy - 36, cx, cy - 48, "roof_lt")
  K.line(cx, cy - 53, cx, cy - 48, "deep")
  -- Weathervane rather than a cross
  K.rect(cx - 3, cy - 53, 7, 1, "deep")
  K.px(cx + 2, cy - 54, "deep"); K.px(cx + 2, cy - 52, "deep")
  K.px(cx - 3, cy - 54, "deep"); K.px(cx - 3, cy - 52, "deep")
  K.px(cx, cy - 55, "gold")

  -- Right-centre: frame warehouse & general store with striped awning
  x, y = 392, 122
  K.side_wall(x + 84, y, 7, 42, "clap_sh", "ochre")
  K.clapboard(x, y, 84, 42, "cream", "sand")
  K.rect(x, y, 2, 42, "white")
  K.hip_roof(x, y, 84, 7, 12)
  K.windows(x, y + 6, 84, 4, "sand", "red")
  K.door(x + 16, y + 42, 15); K.door(x + 60, y + 42, 15)
  K.sign(x + 26, y + 17, 32, "gold", 9)
  K.poly({{x + 2, y + 18}, {x + 82, y + 18}, {x + 86, y + 24}, {x - 2, y + 24}}, "red")
  for xx = x - 1, x + 83, 6 do K.rect(xx, y + 19, 3, 5, "cream") end
  K.rect(x - 2, y + 24, 88, 1, "deep")
  for xx = x, x + 82, 20 do K.rect(xx, y + 25, 1, 17, "wood") end

  -- Far right: log blacksmith & wagon repair shop
  x, y = 508, 132
  K.side_wall(x + 56, y, 6, 32, "wood")
  K.rect(x, y, 56, 32, "wood")
  for yy = y + 1, y + 31, 3 do
    K.rect(x, yy, 56, 2, "rust")
    K.px(x, yy, "ochre"); K.px(x + 55, yy, "deep")
  end
  K.poly({{x - 4, y}, {x + 28, y - 14}, {x + 60, y}}, "roof")
  K.line(x - 4, y, x + 28, y - 14, "roof_lt")
  K.poly({{x + 28, y - 14}, {x + 34, y - 17}, {x + 66, y - 3}, {x + 60, y}}, "roof_dk")
  K.rect(x - 4, y, 65, 1, "ink")
  K.chimney(x + 42, y - 6, 11)
  K.rect(x + 12, y + 12, 14, 20, "ink")
  K.rect(x + 15, y + 20, 8, 12, "rust")
  K.rect(x + 17, y + 23, 4, 7, "gold")
end)

----------------------------------------------------------------- 4. Trees & Dusty Town Square
K.layer("street", function()
  K.elm(214, STREET - 3, 1)
  K.elm(374, STREET - 3, 1)
  K.elm(592, STREET - 2, 1)

  K.rect(0, STREET - 4, W, 2, "grass")
  K.rect(0, STREET - 2, W, 3, "wood")
  K.rect(0, STREET - 2, W, 1, "rust")
  for xx = 0, W - 1, 7 do K.px(xx, STREET - 1, "deep"); K.px(xx, STREET, "deep") end

  K.rect(0, STREET + 1, W, H - STREET - 1, "ochre")
  K.dither(0, STREET + 1, W, 2, "dirt_dk", "ochre")

  -- Sweeping wheel ruts across the wide dusty square
  for i = 0, 3 do
    local y0 = STREET + 18 + i * 22
    for x = 0, W - 1 do
      local y = math.floor(y0 + 7 * math.sin(x / 85.0 + i))
      if y < H - 6 then
        K.px(x, y, "dirt_dk"); if x % 3 ~= 0 then K.px(x, y + 1, "rust") end
        K.px(x, y + 5, "dirt_dk")
      end
    end
  end

  for i = 1, 1600 do
    local x, y = K.rnd(W), STREET + 3 + K.rnd(H - STREET - 3)
    if K.at(x, y) == "ochre" then
      K.px(x, y, (i % 3 == 0) and "gold" or ((i % 3 == 1) and "rust" or "sand"))
    end
  end

  -- Hitching rails along the boardwalk
  K.rect(16, STREET + 2, 180, 1, "deep")
  for xx = 16, 196, 20 do K.rect(xx, STREET + 2, 2, 6, "deep"); K.px(xx, STREET + 2, "wood") end
  K.rect(388, STREET + 2, 180, 1, "deep")
  for xx = 388, 568, 20 do K.rect(xx, STREET + 2, 2, 6, "deep"); K.px(xx, STREET + 2, "wood") end
end)

----------------------------------------------------------------- 5. Outfitting Wagons, Ox Teams & Townsfolk
K.layer("figures", function()
  K.barrel(38, STREET + 1); K.barrel(45, STREET + 1); K.crate(53, STREET + 1)
  K.crate(412, STREET + 1); K.crate(421, STREET + 1); K.barrel(431, STREET + 1)

  -- Left square wagon & team
  K.wagon(72, 212, 1)
  K.team(126, 212, 1, {"dark"}, {"light", true})
  K.line(118, 205, 145, 198, "deep")

  -- Centre-left parked wagon
  K.wagon(264, 202, -1)

  -- Lower-right foreground wagon & team (visible below the companion editor panel at y = 230..273!)
  K.wagon(352, 260, -1)
  K.team(336, 260, -1, {"red"}, {"dark", true})
  K.team(304, 258, -1, {"dark"}, {"light", false})
  K.line(352, 253, 286, 251, "deep")

  -- Additional wagon loading on the far right
  K.wagon(518, 232, -1)
  K.team(502, 232, -1, {"light", true}, {"red"})
  K.line(518, 225, 484, 224, "deep")

  -- Emigrants and townsfolk across the square (including the visible lower-right strip)
  K.person(60, 212, "blue", "deep", false)
  K.person(192, 204, "red", "bonnet", true)
  K.person(200, 205, "wood", "roof", false)
  K.person(264, 248, "teal", "deep", false)
  K.person(274, 250, "red", "bonnet", true)
  K.person(408, 262, "blue", "deep", false)
  K.person(472, 234, "wood", "roof", false)
  K.person(580, 236, "red", "bonnet", true)
  K.person(588, 238, "blue", "rust", false)
end)

K.save("location_town_setup")
