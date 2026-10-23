-- Fort Kearny from June 1848 Onward (432x150).
-- Historical reference: NPS Fort Kearny site history.
-- Shows the June 1848 low sod/adobe construction work and canvas tent camp on the open
-- Platte plain. Modern replica stockade photos are explicitly rejected as 1848 evidence.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184806)

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

----------------------------------------------------------------- 3. June 1848 Sod/Adobe Construction & Tent Camp
K.layer("sod_post_and_camp", function()
  -- Three pitched army/volunteer canvas tents
  K.tent(50,  110, 19, 24)
  K.tent(122, 109, 20, 25)
  K.tent(302, 110, 19, 24)

  -- Low sod & adobe storehouse/quarters building under construction (x = 166..252, y = 88..114)
  K.shadow(164, 114, 92)
  K.rect(168, 91, 82, 23, "clap_sh")
  -- Sunlit left adobe wall plane & horizontal sod/brick courses
  K.rect(168, 91, 3, 23, "sand")
  for row = 94, 112, 4 do
    K.rect(168, row, 82, 1, "ochre")
    for col = 172 + ((row % 8 == 0) and 4 or 0), 246, 9 do
      K.rect(col, row - 3, 1, 3, "wood")
    end
  end
  -- Thick prairie-sod turf roof over cottonwood pole rafters
  K.rect(166, 87, 86, 4, "sage")
  K.rect(166, 87, 86, 1, "gold")
  K.rect(166, 90, 86, 1, "pine")
  for rx = 169, 249, 6 do
    K.px(rx, 91, "wood") -- exposed rafter ends
  end
  -- Deep-set doorway & small shuttered windows
  K.rect(203, 99, 12, 15, "deep")
  K.rect(204, 100, 10, 14, "ink")
  K.rect(202, 98, 14, 1, "wood")
  for _, wx in ipairs({178, 190, 224, 236}) do
    K.rect(wx, 97, 6, 8, "deep")
    K.rect(wx + 1, 98, 4, 6, "wood")
    K.rect(wx, 96, 6, 1, "sand")
  end

  -- Stacks of cut prairie sod & sun-dried adobe bricks on the right (x = 338..398)
  for _, bx in ipairs({338, 360, 382}) do
    K.shadow(bx - 1, 117, 18)
    K.rect(bx, 108, 16, 9, "wood")
    K.rect(bx, 108, 16, 2, "sand")
    K.rect(bx, 111, 16, 1, "deep")
    K.rect(bx, 114, 16, 1, "deep")
    for jx = bx + 4, bx + 12, 4 do
      K.rect(jx, 108, 1, 9, "deep")
    end
  end

  -- Soldier/workman in blue uniform coat & arriving emigrant wagon
  K.person(262, 118, "blue", "deep", false)
  K.wagon(18, 142, 1)
end)

K.save("location_fort_kearny")
