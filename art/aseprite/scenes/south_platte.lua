-- South Platte River Crossing (432x150).
-- Historical reference: 1848 trail journals (California Crossing / Lower California Crossing).
-- Broad, treeless sandy river with shifting mid-stream quicksand bars where teams had to
-- keep moving continuously so the wheels wouldn't sink.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184807)

----------------------------------------------------------------- 1. Sky & Treeless High-Plains Bluffs
K.layer("sky_and_bluffs", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 12, "light_blue")
  K.blend(0, 71, W, "light_blue", "mist")
  K.rect(0, 74, W, 8, "mist")

  K.cloud(40, 16, 1.35)
  K.cloud(296, 14, 1.45)

  for x = 0, W - 1 do
    local y_far = 65 + math.floor(4 * math.sin(tau * x / 432.0 + 0.2) + 2 * math.cos(tau * x / 144.0))
    for y = y_far, 82 do
      K.px(x, y, (y == y_far) and "mist" or "far_hill")
    end
    local y_mid = 74 + math.floor(3 * math.cos(tau * x / 432.0 + 0.9) + 2 * math.sin(tau * x / 108.0))
    for y = y_mid, 92 do
      K.px(x, y, (y == y_mid) and "gold" or "sage")
    end
  end
end)

----------------------------------------------------------------- 2. Broad South Platte Channel & Shifting Sandbars
K.layer("river_and_sandbars", function()
  -- Far sandy shore
  K.poly({{0, 88}, {432, 79}, {432, 85}, {0, 94}}, "sand")

  -- Wide shallow South Platte channel (y = 93..141 on left, y = 82..130 on right)
  K.poly({{0, 92}, {432, 82}, {432, 130}, {0, 141}}, "blue")
  K.poly({{0, 95}, {432, 85}, {432, 127}, {0, 138}}, "sky_top")
  K.poly({{0, 99}, {432, 89}, {432, 123}, {0, 134}}, "sky")

  -- Large elongated mid-stream sandbar & wet quicksand flats
  K.poly({{64, 111}, {192, 102}, {314, 109}, {218, 121}, {112, 118}}, "ochre")
  K.poly({{72, 110}, {194, 103}, {302, 109}, {214, 119}, {118, 116}}, "sand")
  K.poly({{94, 109}, {196, 105}, {278, 109}, {206, 115}}, "cream")

  -- Second smaller shoal bar to the right
  K.poly({{338, 98}, {396, 94}, {424, 99}, {382, 104}}, "ochre")
  K.poly({{344, 97}, {392, 95}, {416, 98}, {378, 102}}, "sand")

  -- Braided current ripples & foam wakes around the sandbars
  for y = 86, 136, 2 do
    for x = 8, W - 8, 16 do
      local rx = (x + y * 7) % (W - 12)
      local cur = K.at(rx, y)
      if cur == "sky" or cur == "sky_top" then
        K.rect(rx, y, 4 + (y % 4), 1, (y % 4 == 0) and "white" or "light_blue")
      end
    end
  end
end)

----------------------------------------------------------------- 3. Near Bank, Ford Approach & Wagon
K.layer("near_bank", function()
  -- Near bank grass & sandy ford ramp
  K.poly({{0, 138}, {432, 128}, {432, 150}, {0, 150}}, "sand")
  K.poly({{0, 141}, {432, 132}, {432, 150}, {0, 150}}, "grass")

  -- Ford approach road cutting diagonally into the river
  K.poly({{188, 126}, {226, 125}, {308, 150}, {234, 150}}, "ochre")
  K.poly({{196, 126}, {218, 125}, {292, 150}, {248, 150}}, "gold")
  K.line(194, 127, 246, 149, "rust")
  K.line(216, 126, 290, 149, "rust")

  for i = 1, 450 do
    local x = K.rnd(W)
    local y = 128 + K.rnd(22)
    local cur = K.at(x, y)
    if cur == "grass" then
      K.px(x, y, (i % 3 == 0) and "sage" or ((i % 2 == 0) and "leaf" or "gold"))
    else
      K.px(x, y, (i % 3 == 0) and "cream" or "rust")
    end
  end

  -- Arriving wagon & driver preparing the team for the wide sandy ford
  K.wagon(24, 143, 1)
  K.team(82, 142, 1, {"light", true}, {"red", false})
  K.person(118, 141, "blue", "sand", false)
end)

K.save("location_south_platte")
