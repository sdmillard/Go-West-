-- John Day River Gorge Crossing (432x150).
-- Historical reference: Joel Palmer's 1845 journal & WESTERN_REFERENCES.md.
-- Steep rust-and-ochre basalt canyon walls flanking the rocky John Day River crossing.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184828)

----------------------------------------------------------------- 1. Desert Sky & Distant Rimrock
K.layer("sky_and_rimrock", function()
  K.rect(0, 0, W, 16, "sky_top")
  K.blend(0, 16, W, "sky_top", "sky")
  K.rect(0, 19, W, 18, "sky")
  K.blend(0, 37, W, "sky", "light_blue")
  K.rect(0, 40, W, 16, "light_blue")
  K.blend(0, 56, W, "light_blue", "sand")
  K.rect(0, 59, W, 30, "sand")

  K.cloud(42, 16, 1.35)
  K.cloud(304, 14, 1.4)

  for x = 0, W - 1 do
    local by = 60 + math.floor(5 * math.sin(tau * x / 432.0 + 0.3) + 3 * math.cos(tau * x / 144.0))
    for y = by, 88 do
      local c = "ochre"
      if y == by then c = "cream" elseif y % 5 == 0 then c = "sand" elseif y % 5 == 2 then c = "rust" end
      K.px(x, y, c)
    end
  end
end)

----------------------------------------------------------------- 2. John Day River Channel & Sandy Floor
K.layer("river_and_floor", function()
  K.rect(0, 86, W, 64, "sand")
  K.dither(0, 86, W, 4, "ochre", "sand")

  -- John Day River channel (34px wide)
  K.poly({{0, 93}, {432, 82}, {432, 116}, {0, 127}}, "blue")
  K.poly({{0, 95}, {432, 84}, {432, 114}, {0, 125}}, "sky_top")
  K.poly({{0, 98}, {432, 87}, {432, 111}, {0, 122}}, "sky")

  for i = 1, 75 do
    local rx = 6 + K.rnd(W - 16)
    local ry = 84 + K.rnd(40)
    local cur = K.at(rx, ry)
    if cur == "sky" or cur == "sky_top" or cur == "blue" then
      K.rect(rx, ry, 4 + (i % 4), 1, (i % 3 == 0) and "white" or "light_blue")
    end
  end

  -- Ford approach road
  K.poly({{204, 120}, {228, 119}, {304, 150}, {236, 150}}, "ochre")
  K.poly({{210, 120}, {222, 119}, {290, 150}, {248, 150}}, "gold")
  K.line(208, 121, 246, 149, "rust")
  K.line(221, 120, 288, 149, "rust")

  for i = 1, 450 do
    local x = K.rnd(W)
    local y = 118 + K.rnd(32)
    local cur = K.at(x, y)
    if cur == "sand" then
      K.px(x, y, (i % 4 == 0) and "sage" or ((i % 2 == 0) and "ochre" or "cream"))
    end
  end
end)

----------------------------------------------------------------- 3. Rust Basalt Canyon Walls & Wagon
K.layer("canyon_and_wagon", function()
  -- Left rust basalt canyon wall (x = 0..132, y = 72..150) with upper-left sunlit rim & tiered ledges
  for y = 72, 149 do
    local rx = (y <= 85) and math.floor((y - 72) * 80 / 13.0)
      or math.floor(80 + (y - 85) * 52 / 64.0 + 2 * math.sin(y * 0.35))
    for x = 0, rx do
      local c = "rust"
      if x >= rx - 2 then
        c = "gold"
      elseif x >= rx - 8 then
        c = "ochre"
      elseif y % 11 == 0 then
        c = "ochre"
      elseif y % 11 == 5 then
        c = "wood"
      elseif x < 24 and (x + y) % 2 == 0 then
        c = "wood"
      end
      K.px(x, y, c)
    end
  end

  -- Right shaded basalt canyon wall (x = 313..432, y = 61..150)
  for y = 61, 149 do
    local lx = (y <= 76) and math.floor(432 - (y - 61) * 62 / 15.0)
      or math.floor(370 - (y - 76) * 57 / 73.0 + 2 * math.cos(y * 0.3))
    for x = lx, W - 1 do
      local c = "wood"
      if x <= lx + 2 then
        c = "ochre"
      elseif x <= lx + 7 then
        c = "rust"
      elseif y % 11 == 0 then
        c = "rust"
      elseif y % 11 == 6 then
        c = "deep"
      elseif x > 395 and (x + y) % 2 == 0 then
        c = "deep"
      end
      K.px(x, y, c)
    end
  end

  for _, b in ipairs({{118, 136, 5, 3}, {126, 144, 4, 2}, {314, 142, 6, 3}}) do
    K.boulder(b[1], b[2], b[3], b[4])
  end

  K.wagon(24, 143, 1)
  K.person(84, 142, "blue", "sand", false)
end)

K.save("location_john_day")
