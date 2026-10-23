-- Big Blue River Crossing near Alcove Spring (432x150).
-- Historical reference: NPS Alcove Spring exhibit description.
-- Low limestone & wooded ridges, clear blue river channel crossed by a diagonal shallow
-- gravel-bar ford, cottonwoods & bur oaks, and emigrant wagon on the near gravel bank.
-- No later Marshall ferry is shown.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 248)

----------------------------------------------------------------- 1. Sky & Low Wooded Limestone Ridges
K.layer("sky_and_ridges", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 14, "light_blue")

  K.cloud(42, 17, 1.35)
  K.cloud(302, 14, 1.4)

  -- Low rolling Flint Hills / Big Blue valley ridges
  for x = 0, W - 1 do
    local y_far = 60 + math.floor(4 * math.sin(tau * x / 432.0 + 0.3) + 3 * math.cos(tau * x / 144.0))
    for y = y_far, 78 do
      K.px(x, y, (y == y_far) and "mist" or "far_hill")
    end
    local y_mid = 68 + math.floor(4 * math.cos(tau * x / 432.0 + 0.9) + 2 * math.sin(tau * x / 108.0))
    for y = y_mid, 86 do
      K.px(x, y, (y <= y_mid + 1) and "sage" or "grass")
    end
  end

  -- Exposed pale limestone outcrop band along the far bank (Alcove Spring ledge character)
  for x = 86, 338 do
    local ly = 77 + math.floor(2 * math.sin(x * 0.04))
    K.rect(x, ly, 1, 5, "sand")
    K.px(x, ly, "cream")
    K.px(x, ly + 3, "ochre")
    K.px(x, ly + 4, "wood")
  end

  -- Far bank cottonwoods & oaks
  for _, tx in ipairs({22, 64, 348, 398}) do
    K.elm(tx, 86, 1)
  end
end)

----------------------------------------------------------------- 2. Big Blue River & Shallow Gravel-Bar Ford
K.layer("river_and_ford", function()
  -- Far gravel bank
  K.poly({{0, 79}, {180, 83}, {432, 87}, {432, 91}, {0, 84}}, "sand")

  -- Deep clear blue channel of the Big Blue River
  K.poly({{0, 82}, {432, 89}, {432, 130}, {0, 118}}, "blue")
  K.poly({{0, 85}, {432, 92}, {432, 126}, {0, 115}}, "sky_top")
  K.poly({{0, 90}, {432, 96}, {432, 120}, {0, 110}}, "sky")

  -- Diagonal shallow gravel ford bar (from near bank x=115,y=124 across to far bank x=318,y=92)
  for step = 0, 34 do
    local t = step / 34.0
    local fx = math.floor(114 + t * 204 + 4 * math.sin(t * math.pi * 2))
    local fy = math.floor(124 - t * 32)
    -- Submerged & emergent gravel/cobble shoalstones with whitewater riffle wakes
    K.ellipse(fx, fy, 7, 2, "sky_top")
    K.ellipse(fx - 1, fy, 4, 1, (step % 2 == 0) and "ochre" or "sand")
    K.px(fx - 2, fy, "cream")
    K.rect(fx + 3, fy, 5, 1, "white")
    K.rect(fx - 6, fy + 1, 4, 1, "light_blue")
  end

  -- Horizontal water ripples across the rest of the stream
  for y = 86, 124, 2 do
    for x = 8, W - 12, 18 do
      local rx = (x + y * 5) % (W - 16)
      K.rect(rx, y, 3 + (y % 3), 1, (y % 4 == 0) and "light_blue" or "sky_top")
    end
  end
end)

----------------------------------------------------------------- 3. Near Gravel Bank, Trail & Waiting Wagon
K.layer("near_bank", function()
  -- Broad gravel and sand bar on the near shore
  K.poly({{0, 114}, {96, 118}, {224, 132}, {432, 120}, {432, 150}, {0, 150}}, "sand")
  K.poly({{0, 118}, {96, 122}, {224, 136}, {432, 124}, {432, 150}, {0, 150}}, "ochre")
  -- Grassy terrace along the lower left & right corners
  K.poly({{0, 126}, {82, 134}, {148, 150}, {0, 150}}, "grass")
  K.poly({{286, 150}, {348, 134}, {432, 128}, {432, 150}}, "grass")

  -- River cobbles, pebbles & grass texture
  for i = 1, 600 do
    local x = K.rnd(W)
    local y = 116 + K.rnd(34)
    local cur = K.at(x, y)
    if cur == "sand" or cur == "ochre" then
      K.px(x, y, (i % 3 == 0) and "cream" or ((i % 2 == 0) and "rust" or "wood"))
    elseif cur == "grass" then
      K.px(x, y, (i % 3 == 0) and "leaf" or ((i % 2 == 0) and "sage" or "gold"))
    end
  end

  -- Wheel ruts curving down onto the gravel ford approach
  for i = 0, 40 do
    local rx = 44 + i * 2
    local ry = 138 - math.floor(i * 0.35)
    K.px(rx, ry, "rust"); K.px(rx, ry - 1, "sand")
    K.px(rx + 6, ry + 4, "rust"); K.px(rx + 6, ry + 3, "sand")
  end

  -- Emigrant wagon & scout checking the ford depth at the water's edge
  K.wagon(38, 138, 1)
  K.team(96, 137, 1, {"light", true}, {"red", false})
  K.person(132, 134, "blue", "wood", false)
end)

K.save("location_big_blue")
