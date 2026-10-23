-- Umatilla River Crossing (432x150).
-- Historical reference: Joel Palmer's 1845 journal & WESTERN_REFERENCES.md.
-- Clear stream channel winding across the rolling Columbia Plateau grasslands,
-- shaded by groves of cottonwoods and river-bottom willows.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184827)

----------------------------------------------------------------- 1. Sky & Columbia Plateau Hills
K.layer("sky_and_hills", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 14, "light_blue")

  K.cloud(42, 16, 1.35)
  K.cloud(302, 14, 1.4)

  for x = 0, W - 1 do
    local y_far = 64 + math.floor(4 * math.sin(tau * x / 432.0 + 0.4) + 2 * math.cos(tau * x / 144.0))
    for y = y_far, 84 do
      K.px(x, y, (y == y_far) and "mist" or "far_hill")
    end
    local y_mid = 74 + math.floor(4 * math.cos(tau * x / 432.0 + 0.9) + 2 * math.sin(tau * x / 108.0))
    for y = y_mid, 96 do
      K.px(x, y, (y == y_mid) and "gold" or "sage")
    end
  end
end)

----------------------------------------------------------------- 2. Umatilla River Channel, Cottonwoods & Near Bank
K.layer("river_and_trees", function()
  K.rect(0, 92, W, 58, "grass")
  K.dither(0, 92, W, 5, "sage", "grass")
  K.dither(0, 140, W, 10, "grass", "pine")

  -- Far gravel bank
  K.poly({{0, 91}, {432, 80}, {432, 83}, {0, 94}}, "sand")

  -- Umatilla River channel (34px wide)
  K.poly({{0, 93}, {432, 82}, {432, 116}, {0, 127}}, "blue")
  K.poly({{0, 95}, {432, 84}, {432, 114}, {0, 125}}, "sky_top")
  K.poly({{0, 98}, {432, 87}, {432, 111}, {0, 122}}, "sky")
  -- Near gravel shoreline
  K.poly({{0, 126}, {432, 115}, {432, 118}, {0, 129}}, "sand")

  for i = 1, 75 do
    local rx = 6 + K.rnd(W - 16)
    local ry = 85 + K.rnd(38)
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

  for i = 1, 500 do
    local x = K.rnd(W)
    local y = 118 + K.rnd(32)
    local cur = K.at(x, y)
    if cur == "grass" then
      K.px(x, y, (i % 3 == 0) and "sage" or ((i % 2 == 0) and "leaf" or "gold"))
    end
  end

  -- Riparian cottonwoods & alders along the riverbanks
  for _, tx in ipairs({42, 83, 354, 390}) do
    K.elm(tx, 96, 1)
  end
end)

----------------------------------------------------------------- 3. Arriving Wagon
K.layer("wagon", function()
  K.wagon(24, 143, 1)
  K.person(84, 142, "blue", "sand", false)
end)

K.save("location_umatilla")
