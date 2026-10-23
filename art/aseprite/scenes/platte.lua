-- The Great Platte River Valley (432x150).
-- Historical reference: NPS "The Platte Experience" & Joel Palmer's 1845 journal.
-- Broad, flat floodplain with shallow braided channels weaving around sandy shoals
-- and a low wooded island ("Grand Island" character). No mountains or later army posts.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 246)

----------------------------------------------------------------- 1. Wide Prairie Sky & Low Horizon Bluffs
K.layer("sky_and_horizon", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 12, "light_blue")
  K.blend(0, 71, W, "light_blue", "mist")
  K.rect(0, 74, W, 6, "mist")

  K.cloud(44, 18, 1.35)
  K.cloud(192, 14, 1.05)
  K.cloud(312, 16, 1.45)

  -- Very low, flat Platte valley horizon bluffs
  for x = 0, W - 1 do
    local hy = 69 + math.floor(2 * math.sin(tau * x / 432.0 + 0.4) + 1.5 * math.cos(tau * x / 144.0))
    for y = hy, 76 do
      K.px(x, y, (y == hy) and "mist" or "sage")
    end
  end
end)

----------------------------------------------------------------- 2. Braided Channels, Sandbars & Wooded Island
K.layer("braided_platte", function()
  -- Broad sandy floodplain floor (y = 76..136)
  K.rect(0, 76, W, 60, "sand")
  K.dither(0, 76, W, 3, "cream", "sand")

  -- Far braided channel (y = 78..94)
  K.poly({{0, 81}, {180, 78}, {432, 76}, {432, 88}, {180, 92}, {0, 98}}, "sky_top")
  K.poly({{0, 83}, {180, 80}, {432, 78}, {432, 86}, {180, 90}, {0, 96}}, "sky")

  -- Near braided channel sweeping across the sandy bed
  K.poly({{0, 118}, {168, 96}, {310, 102}, {432, 108}, {432, 121}, {310, 115}, {168, 108}, {0, 132}}, "sky_top")
  K.poly({{0, 120}, {168, 98}, {310, 104}, {432, 110}, {432, 119}, {310, 113}, {168, 106}, {0, 130}}, "sky")

  -- Exposed mid-stream sandbars & wet silt margins
  K.poly({{28, 104}, {98, 97}, {142, 101}, {88, 108}}, "ochre")
  K.poly({{34, 103}, {94, 98}, {132, 100}, {84, 106}}, "cream")
  K.poly({{312, 92}, {388, 89}, {424, 94}, {378, 98}}, "ochre")
  K.poly({{318, 91}, {384, 90}, {416, 93}, {374, 96}}, "cream")

  -- Shallow water glints & ripples across both channels
  for y = 78, 130 do
    for x = 4, W - 8, 14 do
      local rx = (x + y * 7) % (W - 10)
      local cur = K.at(rx, y)
      if cur == "sky" or cur == "sky_top" then
        K.rect(rx, y, 3 + (y % 3), 1, (y % 3 == 0) and "white" or "light_blue")
      end
    end
  end

  -- Low grassy/sandy mid-river island with cottonwood trees
  K.poly({{138, 94}, {172, 84}, {264, 86}, {314, 96}, {246, 102}, {154, 98}}, "ochre")
  K.poly({{144, 93}, {174, 85}, {258, 87}, {304, 95}, {242, 100}, {158, 96}}, "sage")
  K.poly({{154, 92}, {182, 87}, {248, 88}, {288, 94}, {236, 98}, {166, 95}}, "grass")
  for _, tx in ipairs({182, 214, 244}) do
    K.elm(tx, 93, 1)
  end
end)

----------------------------------------------------------------- 3. South Bank Trail & Wagon
K.layer("south_bank", function()
  -- South bank prairie terrace & sandy wagon road (y = 122..150)
  K.poly({{0, 134}, {168, 114}, {320, 120}, {432, 124}, {432, 150}, {0, 150}}, "ochre")
  K.poly({{0, 138}, {172, 120}, {320, 125}, {432, 129}, {432, 150}, {0, 150}}, "grass")
  K.dither(0, 136, W, 4, "ochre", "grass")

  -- Sandy wheel ruts along the Great Platte River Road
  for x = 0, W - 1 do
    local ry = 134 - math.floor(14 * math.sin(math.pi * x / W))
    if (x % 15) < 11 then
      K.px(x, ry, "rust"); K.px(x, ry - 1, "cream")
      K.px(x, ry + 7, "rust"); K.px(x, ry + 6, "cream")
    end
  end

  -- Sand, pebble & bunchgrass texture
  for i = 1, 750 do
    local x = K.rnd(W)
    local y = 76 + K.rnd(74)
    local cur = K.at(x, y)
    if cur == "sand" or cur == "ochre" then
      K.px(x, y, (i % 3 == 0) and "cream" or ((i % 2 == 0) and "gold" or "rust"))
    elseif cur == "grass" or cur == "sage" then
      K.px(x, y, (i % 3 == 0) and "leaf" or "gold")
    end
  end

  -- Emigrant wagon & ox team halted on the south bank overlooking the braided river
  K.wagon(324, 141, -1)
  K.team(282, 141, -1, {"light", true}, {"dark", false})
  K.person(268, 141, "blue", "sand", false)
end)

K.save("location_platte")
