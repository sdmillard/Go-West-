-- Fort Hall Adobe Trading Post (432x150).
-- Historical reference: NPS historic-site survey & WESTERN_REFERENCES.md.
-- Depicts the Hudson's Bay Company trading post rebuilt in whitewashed adobe around 1840
-- on the Snake / Portneuf River bottomland.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184820)

----------------------------------------------------------------- 1. Sky & Distant Bannock / Snake River Range
K.layer("sky", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 14, "light_blue")

  K.cloud(42, 16, 1.35)
  K.cloud(304, 14, 1.4)

  for x = 0, W - 1 do
    local hy = 65 + math.floor(4 * math.sin(tau * x / 432.0 + 0.4) + 2 * math.cos(tau * x / 144.0))
    for y = hy, 88 do
      K.px(x, y, (y == hy) and "mist" or "far_hill")
    end
  end
end)

----------------------------------------------------------------- 2. Snake River Bottoms, Slough & Trail
K.layer("bottomland", function()
  K.rect(0, 88, W, 14, "sage")
  K.dither(0, 98, W, 6, "sage", "grass")
  K.rect(0, 104, W, 46, "grass")
  K.dither(0, 140, W, 10, "grass", "pine")

  -- Deep blue Portneuf / Snake River slough running behind the fort (y = 110..118)
  K.rect(0, 109, W, 1, "sand")
  K.rect(0, 110, W, 9, "blue")
  K.rect(0, 112, W, 5, "sky_top")
  for x = 12, W - 12, 18 do
    K.rect(x, 114 + (x % 2), 5, 1, "light_blue")
  end
  K.rect(0, 119, W, 1, "sand")

  -- Wagon road leading to the Fort Hall gateway
  K.poly({{196, 118}, {228, 118}, {304, 150}, {234, 150}}, "ochre")
  K.poly({{202, 118}, {222, 118}, {290, 150}, {248, 150}}, "gold")
  K.line(200, 119, 246, 149, "rust")
  K.line(220, 119, 288, 149, "rust")

  for i = 1, 600 do
    local x = K.rnd(W)
    local y = 90 + K.rnd(60)
    local cur = K.at(x, y)
    if cur == "grass" or cur == "sage" then
      K.px(x, y, (i % 3 == 0) and "leaf" or ((i % 2 == 0) and "sage" or "gold"))
    end
  end
end)

----------------------------------------------------------------- 3. Whitewashed Adobe Fort Hall Enclosure
K.layer("fort_hall", function()
  K.shadow(98, 122, 238)

  -- Interior HBC storehouse gable peeking above the north wall
  K.rect(164, 64, 88, 9, "sand")
  K.rect(162, 62, 92, 3, "wood")
  K.rect(162, 62, 92, 1, "gold")

  -- Main whitewashed adobe curtain wall (x = 116..318, y = 72..120)
  K.rect(116, 72, 202, 48, "cream")
  K.rect(116, 72, 202, 2, "white")
  for row = 78, 116, 6 do
    K.rect(116, row, 202, 1, "sand")
    for col = 122 + ((row % 12 == 0) and 6 or 0), 312, 12 do
      K.rect(col, row - 5, 1, 5, "sand")
    end
  end
  -- Exposed viga beam ends
  for vx = 124, 310, 10 do
    K.rect(vx, 76, 2, 2, "wood")
  end

  -- Left corner adobe bastion tower (x = 100..130, y = 58..122)
  K.rect(100, 58, 30, 64, "cream")
  K.rect(115, 58, 15, 64, "sand")
  K.rect(128, 60, 2, 62, "ochre")
  K.rect(99, 56, 32, 3, "wood")
  K.rect(99, 56, 32, 1, "gold")
  for row = 64, 118, 6 do
    K.rect(100, row, 15, 1, "sand")
    K.rect(115, row, 15, 1, "ochre")
  end
  for _, lx in ipairs({106, 112, 120}) do
    K.rect(lx, 66, 2, 5, "deep")
    K.rect(lx, 84, 2, 5, "deep")
  end

  -- Right corner adobe bastion tower (x = 300..332, y = 62..122)
  K.rect(300, 62, 32, 60, "sand")
  K.rect(316, 62, 16, 60, "ochre")
  K.rect(330, 62, 2, 60, "rust")
  K.rect(299, 60, 34, 3, "wood")
  K.rect(299, 60, 34, 1, "gold")
  for row = 68, 118, 6 do
    K.rect(300, row, 16, 1, "ochre")
    K.rect(316, row, 16, 1, "rust")
  end
  for _, lx in ipairs({306, 312, 322}) do
    K.rect(lx, 70, 2, 5, "deep")
    K.rect(lx, 86, 2, 5, "deep")
  end

  -- Upper curtain windows & central timbered gate
  for _, wx in ipairs({146, 170, 252, 276}) do
    K.rect(wx, 86, 8, 9, "deep")
    K.rect(wx + 1, 87, 6, 7, "ink")
    K.rect(wx, 85, 8, 1, "wood")
  end
  K.rect(202, 96, 22, 24, "wood")
  K.rect(200, 94, 26, 3, "deep")
  K.rect(205, 98, 16, 22, "deep")
  K.rect(207, 99, 12, 21, "ink")

  -- flagstaff rising behind the wall; ui/scene_ambience.gd flies the HBC red ensign from it
  K.rect(213, 46, 1, 18, "wood")
end)

----------------------------------------------------------------- 4. Foreground Wagon & Trader
K.layer("wagon", function()
  K.person(238, 124, "rust", "wood", false)
  K.wagon(24, 143, 1)
end)

K.save("location_fort_hall")
