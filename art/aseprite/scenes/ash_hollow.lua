-- Windlass Hill & Ash Hollow (432x150).
-- Historical reference: Joel Palmer's 1845 journal & WESTERN_REFERENCES.md.
-- Steep eroded calcareous sandstone bluffs framing the canyon draw where wagons locked
-- their wheels to descend into the green ash & cedar bottomland near the North Platte.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184808)

----------------------------------------------------------------- 1. Sky & Distant North Platte Valley
K.layer("sky_and_valley", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 14, "light_blue")
  K.blend(0, 73, W, "light_blue", "mist")
  K.rect(0, 76, W, 8, "mist")

  K.cloud(48, 16, 1.3)
  K.cloud(294, 14, 1.4)

  -- Distant North Platte valley floor seen through the canyon mouth
  for x = 0, W - 1 do
    local hy = 68 + math.floor(3 * math.sin(tau * x / 432.0 + 0.5))
    for y = hy, 96 do
      K.px(x, y, (y == hy) and "mist" or ((y < hy + 6) and "far_hill" or "sage"))
    end
  end
  -- Glint of the North Platte River spanning the distant valley behind the canyon walls
  K.rect(0, 78, W, 1, "sand")
  K.rect(0, 79, W, 5, "sky")
  K.rect(0, 79, W, 1, "sky_top")
  for x = 16, W - 16, 18 do
    K.rect(x, 81 + (x % 2), 5, 1, "light_blue")
  end
  K.rect(0, 84, W, 1, "sand")
end)

----------------------------------------------------------------- 2. Canyon Bluffs & Lush Ash Hollow Bottomland
K.layer("bluffs_and_hollow", function()
  -- Lush green Ash Hollow floor watered by fresh springs (center-bottom)
  K.poly({{96, 94}, {336, 94}, {360, 150}, {72, 150}}, "sage")
  K.poly({{124, 106}, {308, 102}, {342, 150}, {96, 150}}, "grass")
  K.dither(110, 102, 210, 6, "sage", "grass")

  -- Clear spring branch curving from the base of the right bluff down through the hollow
  K.poly({{304, 104}, {310, 104}, {244, 124}, {228, 150}, {210, 150}, {232, 122}}, "sky_top")
  K.poly({{305, 104}, {309, 104}, {242, 124}, {224, 150}, {214, 150}, {235, 122}}, "sky")
  for y = 108, 148, 4 do
    local sx = (y < 124) and (304 - math.floor((y - 104) * 3.2)) or (236 - math.floor((y - 124) * 0.7))
    K.rect(sx, y, 3, 1, "white")
  end

  -- Left calcareous sandstone bluff (sunlit upper-left rim & stepped erosion gullies)
  for y = 44, 149 do
    local t = (y - 44) / 105.0
    local rx = math.floor(88 + t * 94 + 6 * math.sin(y * 0.14) + 3 * math.cos(y * 0.35))
    for x = 0, rx do
      local c = "sand"
      if x >= rx - 3 then
        c = "cream"
      elseif y % 7 == 0 then
        c = "cream"
      elseif y % 7 == 4 then
        c = "ochre"
      elseif (x + y * 2) % 13 == 0 then
        c = "ochre"
      end
      if x < math.floor(rx * 0.35) and y % 5 == 0 then c = "ochre" end
      K.px(x, y, c)
    end
  end

  -- Right canyon bluff in deeper warm afternoon shade
  for y = 46, 149 do
    local t = (y - 46) / 103.0
    local lx = math.floor(342 - t * 102 + 6 * math.cos(y * 0.15) + 3 * math.sin(y * 0.31))
    for x = lx, W - 1 do
      local c = "ochre"
      if x <= lx + 3 then
        c = "sand"
      elseif y % 7 == 0 then
        c = "sand"
      elseif y % 7 == 3 then
        c = "rust"
      elseif (x - y * 2) % 11 == 0 then
        c = "rust"
      end
      if x > lx + math.floor((W - lx) * 0.55) and y % 4 == 0 then c = "rust" end
      K.px(x, y, c)
    end
  end
end)

----------------------------------------------------------------- 3. Steep Descent Trace, Ash Trees & Wagon
K.layer("trace_and_trees", function()
  -- Steep Windlass Hill wagon trace cutting down the left bluff into the hollow
  K.poly({{34, 62}, {52, 60}, {198, 144}, {168, 150}}, "ochre")
  K.poly({{38, 62}, {48, 60}, {190, 144}, {174, 150}}, "gold")
  -- Deep locked-wheel ruts & brake-shoe scars in the steep limestone sand
  K.line(38, 62, 174, 146, "wood")
  K.line(39, 62, 175, 146, "deep")
  K.line(46, 61, 188, 144, "wood")
  K.line(47, 61, 189, 144, "deep")
  K.line(37, 62, 173, 146, "cream")

  -- Green ash & cedar trees thriving in the sheltered hollow bottom
  K.elm(272, 132, 1)
  K.elm(298, 120, 1)
  K.conifer(134, 108, 18, "ink", "pine", "leaf")
  K.conifer(322, 114, 20, "ink", "pine", "leaf")

  -- Texture pebbles & bunchgrass on the canyon floor and slopes
  for i = 1, 650 do
    local x = K.rnd(W)
    local y = 70 + K.rnd(80)
    local cur = K.at(x, y)
    if cur == "grass" or cur == "sage" then
      K.px(x, y, (i % 3 == 0) and "leaf" or "gold")
    elseif cur == "sand" or cur == "ochre" then
      K.px(x, y, (i % 3 == 0) and "cream" or "rust")
    end
  end

  -- Emigrant wagon safely down at the foot of the bluff, with driver checking wheel locks
  K.wagon(24, 143, 1)
  K.person(82, 142, "blue", "wood", false)
end)

K.save("location_ash_hollow")
