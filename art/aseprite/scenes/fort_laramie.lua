-- Fort Laramie / Fort John Adobe Trading Post (432x150).
-- Historical reference: Wyoming SHPO report (Thomas Bullock's 1847 plan of Fort John)
-- & NPS Fort Laramie FAQ. Depicts the 1841-1849 rectangular adobe fur-trading enclosure
-- with corner blockhouse bastions and gatehouse block—never the 1850s Army Old Bedlam complex.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184811)

----------------------------------------------------------------- 1. Sky & Laramie Peak / Black Hills Horizon
K.layer("sky_and_hills", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 14, "light_blue")
  K.blend(0, 73, W, "light_blue", "mist")
  K.rect(0, 76, W, 8, "mist")

  K.cloud(36, 16, 1.3)
  K.cloud(308, 14, 1.4)

  -- Distant Laramie Range foothills on the western horizon
  for x = 0, W - 1 do
    local hy = 63 + math.floor(5 * math.sin(tau * x / 432.0 + 0.4) + 3 * math.cos(tau * x / 144.0))
    for y = hy, 88 do
      K.px(x, y, (y == hy) and "mist" or "far_hill")
    end
  end

  -- Laramie River glinting behind the bluff terrace (y = 84..91)
  K.rect(0, 84, W, 7, "sky")
  K.rect(0, 84, W, 1, "sand")
  for x = 12, W - 12, 18 do
    K.rect(x, 86 + (x % 3), 5, 1, "light_blue")
  end
end)

----------------------------------------------------------------- 2. Prairie Bench & Trail
K.layer("prairie_bench", function()
  K.rect(0, 90, W, 12, "sage")
  K.dither(0, 98, W, 6, "sage", "grass")
  K.rect(0, 104, W, 46, "grass")
  K.dither(0, 140, W, 10, "grass", "pine")

  -- Wagon road leading directly from the foreground up to the Fort John gatehouse
  K.poly({{188, 122}, {228, 122}, {304, 150}, {226, 150}}, "ochre")
  K.poly({{196, 122}, {220, 122}, {288, 150}, {242, 150}}, "gold")
  K.line(194, 123, 240, 149, "rust")
  K.line(218, 123, 288, 149, "rust")
  K.line(193, 123, 239, 149, "sand")
  K.line(217, 123, 287, 149, "sand")

  for i = 1, 750 do
    local x = K.rnd(W)
    local y = 90 + K.rnd(60)
    local cur = K.at(x, y)
    if cur == "grass" or cur == "sage" then
      K.px(x, y, (i % 3 == 0) and "leaf" or ((i % 2 == 0) and "sage" or "gold"))
    elseif cur == "ochre" or cur == "gold" then
      K.px(x, y, (i % 3 == 0) and "sand" or "rust")
    end
  end
end)

----------------------------------------------------------------- 3. Fort John Adobe Enclosure (1841-1849)
K.layer("fort_john", function()
  -- Ground shadow along the base of the fort walls
  K.shadow(72, 125, 272)

  -- Interior two-story trade store & factor's house roof peeking above the north/back wall
  K.rect(128, 64, 72, 10, "clap_sh")
  K.rect(126, 62, 76, 3, "wood")
  K.rect(126, 62, 76, 1, "ochre")
  for wx = 136, 188, 16 do
    K.rect(wx, 66, 5, 5, "deep")
    K.px(wx + 1, 67, "light_blue")
  end

  -- Main adobe curtain wall (x = 86..332, y = 73..124)
  K.rect(86, 73, 246, 52, "sand")
  -- Whitewashed upper parapet coping & horizontal adobe brick course lines
  K.rect(86, 73, 246, 3, "cream")
  K.rect(86, 73, 246, 1, "white")
  for row = 79, 121, 5 do
    K.rect(86, row, 246, 1, "ochre")
    for col = 92 + ((row % 10 == 0) and 5 or 0), 326, 12 do
      K.rect(col, row - 4, 1, 4, "clap_sh")
    end
  end
  -- Exposed timber viga / roof-beam ends along the curtain wall
  for vx = 90, 328, 9 do
    K.rect(vx, 78, 2, 3, "wood")
    K.px(vx, 81, "deep")
  end
  -- Timber palisade / parapet pickets along the top of the curtain wall
  for px_x = 88, 330, 6 do
    K.rect(px_x, 70, 2, 3, "wood")
  end

  -- Projecting Left (SW) Bastion Blockhouse (sunlit left face + shaded right return)
  K.rect(74, 58, 40, 67, "sand")
  K.rect(74, 58, 18, 67, "cream")
  K.rect(92, 58, 22, 67, "ochre")
  K.rect(112, 60, 3, 65, "rust") -- cast shadow onto main curtain wall
  K.rect(73, 56, 42, 3, "wood")
  K.rect(73, 56, 42, 1, "gold")
  for row = 63, 120, 6 do
    K.rect(74, row, 18, 1, "sand")
    K.rect(92, row, 22, 1, "rust")
  end
  -- Bastion watch-loop & embrasure slits
  for _, lx in ipairs({80, 86, 98, 104}) do
    K.rect(lx, 66, 2, 6, "deep")
    K.rect(lx, 84, 2, 5, "deep")
  end

  -- Projecting Right (SE) Bastion Blockhouse
  K.rect(304, 60, 38, 65, "sand")
  K.rect(322, 60, 20, 65, "ochre")
  K.rect(340, 60, 2, 65, "rust")
  K.rect(303, 58, 40, 3, "wood")
  K.rect(303, 58, 40, 1, "gold")
  for row = 65, 120, 6 do
    K.rect(304, row, 18, 1, "ochre")
    K.rect(322, row, 20, 1, "rust")
  end
  for _, lx in ipairs({310, 316, 326, 332}) do
    K.rect(lx, 68, 2, 6, "deep")
    K.rect(lx, 86, 2, 5, "deep")
  end

  -- Central Timbered Gatehouse Block & Heavy Double Plank Gates (x = 190..228)
  K.rect(188, 62, 42, 16, "wood")
  K.rect(188, 62, 42, 2, "gold")
  K.rect(186, 60, 46, 2, "deep")
  for gx = 194, 222, 7 do
    K.rect(gx, 66, 3, 6, "deep")
  end
  -- Flagstaff flying trading post banner above the gatehouse
  K.rect(208, 44, 1, 16, "wood")
  K.poly({{209, 45}, {221, 47}, {209, 50}}, "rust")
  K.rect(209, 45, 5, 3, "blue")
  K.px(211, 46, "white")

  -- Main gateway arch/lintel & open heavy timber doors
  K.rect(194, 96, 30, 29, "wood")
  K.rect(193, 94, 32, 3, "deep")
  K.rect(198, 98, 22, 27, "deep")
  K.rect(201, 99, 16, 26, "ink")
  -- Open studded oak gate leaves flanking the gateway
  K.rect(194, 98, 5, 27, "rust")
  K.rect(219, 98, 5, 27, "rust")
  for gy = 101, 121, 5 do
    K.px(196, gy, "gold"); K.px(221, gy, "gold")
  end
end)

----------------------------------------------------------------- 4. Traders, Tipi & Arriving Wagon
K.layer("foreground", function()
  -- Lakota / Cheyenne trade tipi pitched on the left prairie bench outside the fort
  K.tent(36, 114, 14, 22)
  K.line(34, 92, 31, 86, "wood")
  K.line(38, 92, 41, 86, "wood")

  -- Fur trader & emigrant conversing outside the gate, plus parked emigrant wagon
  K.person(246, 134, "rust", "wood", false)
  K.person(258, 135, "blue", "sand", false)
  K.wagon(24, 143, 1)
end)

K.save("location_fort_laramie")
