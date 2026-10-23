-- Deschutes River Canyon Crossing (432x150).
-- Historical reference: Joel Palmer's 1845 journal & WESTERN_REFERENCES.md.
-- Deep, swift 48px-wide Deschutes River rushing between dark volcanic basalt cliffs
-- near its confluence with the Columbia River.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184829)

----------------------------------------------------------------- 1. Sky & Distant Columbia Gorge Bluffs
K.layer("sky_and_bluffs", function()
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
    local by = 58 + math.floor(5 * math.sin(tau * x / 432.0 + 0.5) + 3 * math.cos(tau * x / 144.0))
    for y = by, 88 do
      local c = "rust"
      if y == by then c = "sand" elseif y % 5 == 0 then c = "ochre" elseif y % 5 == 2 then c = "wood" end
      K.px(x, y, c)
    end
  end
end)

----------------------------------------------------------------- 2. Swift Deschutes River Channel & Canyon Floor
K.layer("river_and_floor", function()
  K.rect(0, 86, W, 64, "sand")
  K.dither(0, 86, W, 4, "ochre", "sand")

  -- Swift Deschutes River channel (48px wide) with whitewater rapids
  K.poly({{0, 93}, {432, 82}, {432, 130}, {0, 141}}, "blue")
  K.poly({{0, 96}, {432, 85}, {432, 126}, {0, 137}}, "sky_top")
  K.poly({{0, 101}, {432, 90}, {432, 120}, {0, 131}}, "sky")

  for i = 1, 95 do
    local rx = 6 + K.rnd(W - 16)
    local ry = 84 + K.rnd(52)
    local cur = K.at(rx, ry)
    if cur == "sky" or cur == "sky_top" or cur == "blue" then
      K.rect(rx, ry, 5 + (i % 4), 1, (i % 2 == 0) and "white" or "light_blue")
    end
  end

  -- Ford approach road
  K.poly({{204, 128}, {228, 127}, {304, 150}, {236, 150}}, "ochre")
  K.poly({{210, 128}, {222, 127}, {290, 150}, {248, 150}}, "gold")
  K.line(208, 129, 246, 149, "rust")
  K.line(221, 128, 288, 149, "rust")
end)

----------------------------------------------------------------- 3. Dark Basalt Cliff Walls & Wagon
K.layer("basalt_and_wagon", function()
  -- Left dark volcanic basalt cliff wall with columnar ledges & sunlit inner rim
  for y = 72, 149 do
    local rx = (y <= 85) and math.floor((y - 72) * 80 / 13.0)
      or math.floor(80 + (y - 85) * 52 / 64.0 + 2 * math.sin(y * 0.35))
    for x = 0, rx do
      local c = "deep"
      if x >= rx - 2 then
        c = "ochre"
      elseif x >= rx - 7 then
        c = "wood"
      elseif y % 12 == 0 then
        c = "wood"
      elseif (x + math.floor(y / 12) * 3) % 11 == 0 then
        c = "ink"
      end
      K.px(x, y, c)
    end
  end

  -- Right rust/dark-wood basalt canyon wall
  for y = 61, 149 do
    local lx = (y <= 76) and math.floor(432 - (y - 61) * 62 / 15.0)
      or math.floor(370 - (y - 76) * 57 / 73.0 + 2 * math.cos(y * 0.3))
    for x = lx, W - 1 do
      local c = "wood"
      if x <= lx + 2 then
        c = "ochre"
      elseif x <= lx + 7 then
        c = "rust"
      elseif y % 12 == 0 then
        c = "rust"
      elseif y % 12 == 6 then
        c = "deep"
      end
      K.px(x, y, c)
    end
  end

  K.wagon(24, 143, 1)
  K.person(84, 142, "blue", "sand", false)
end)

K.save("location_deschutes")
