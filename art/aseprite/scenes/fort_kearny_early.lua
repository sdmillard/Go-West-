-- Fort Kearny Before June 1848 Construction (432x150).
-- Historical reference: NPS Fort Kearny site history.
-- Before June 1848, the site on the Platte River was an open camp with canvas tents
-- and no sod/adobe fort buildings yet (and never a wooden stockade).
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184805)

----------------------------------------------------------------- 1. Sky & Flat Platte Horizon
K.layer("sky", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 12, "light_blue")
  K.blend(0, 71, W, "light_blue", "mist")
  K.rect(0, 74, W, 6, "mist")

  K.cloud(42, 17, 1.35)
  K.cloud(298, 14, 1.45)

  for x = 0, W - 1 do
    local hy = 69 + math.floor(2 * math.sin(tau * x / 432.0 + 0.3) + 1.5 * math.cos(tau * x / 144.0))
    for y = hy, 77 do
      K.px(x, y, (y == hy) and "mist" or "sage")
    end
  end
end)

----------------------------------------------------------------- 2. Distant Platte Channel & Open Bottomland
K.layer("river_and_plain", function()
  -- Braided Platte channel glinting behind the camp (y = 77..86)
  K.rect(0, 77, W, 1, "sand")
  K.rect(0, 78, W, 8, "sky")
  K.rect(0, 78, W, 2, "sky_top")
  for y = 79, 85, 2 do
    for x = 8, W - 8, 16 do
      local rx = (x + y * 5) % (W - 12)
      K.rect(rx, y, 4, 1, (y % 4 == 1) and "white" or "light_blue")
    end
  end
  K.rect(0, 86, W, 2, "sand")

  -- Open grassy Platte plain (y = 88..150)
  K.rect(0, 88, W, 10, "sage")
  K.dither(0, 96, W, 6, "sage", "grass")
  K.rect(0, 102, W, 48, "grass")
  K.dither(0, 140, W, 10, "grass", "pine")

  -- Diagonal wagon road crossing the plain
  K.poly({{168, 96}, {204, 96}, {318, 150}, {228, 150}}, "ochre")
  K.poly({{176, 96}, {196, 96}, {296, 150}, {248, 150}}, "gold")
  K.line(174, 97, 244, 149, "rust")
  K.line(196, 97, 298, 149, "rust")
  K.line(173, 97, 243, 149, "sand")
  K.line(195, 97, 297, 149, "sand")

  for i = 1, 800 do
    local x = K.rnd(W)
    local y = 88 + K.rnd(62)
    local cur = K.at(x, y)
    if cur == "ochre" or cur == "gold" then
      K.px(x, y, (i % 3 == 0) and "sand" or "rust")
    else
      K.px(x, y, (i % 3 == 0) and "leaf" or ((i % 2 == 0) and "sage" or "gold"))
    end
  end
end)

----------------------------------------------------------------- 3. Pre-Construction Tent Encampment
K.layer("early_camp", function()
  -- Three pitched canvas tents on the open plain (no sod/adobe wall yet)
  K.tent(52,  112, 20, 25)
  K.tent(126, 110, 21, 26)
  K.tent(302, 112, 20, 25)

  -- Survey stakes & supply crates marking out the future post site
  for _, sx in ipairs({172, 208, 244}) do
    K.rect(sx, 104, 1, 5, "wood")
    K.px(sx, 103, "cream")
  end
  K.crate(332, 114)
  K.barrel(342, 114)

  -- Campfire & scout
  K.shadow(84, 122, 12)
  K.rect(86, 120, 8, 2, "wood")
  K.poly({{88, 120}, {90, 115}, {92, 120}}, "gold")
  K.px(90, 117, "cream")
  K.person(98, 121, "blue", "wood", false)
end)

K.save("location_fort_kearny_early")
