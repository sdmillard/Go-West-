-- Kansas (Kaw) River Crossing & Pappan's Ferry (432x150).
-- Historical reference: NPS Kansas River / Pappan's Ferry account (1840s Topeka crossing).
-- Wide muddy silt-laden river, wooded far shore, sandy landing beach, and a timber plank
-- platform resting on twin dugout hulls carrying an emigrant wagon along a guide hawser.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 252)

----------------------------------------------------------------- 1. Sky & Far Wooded Kaw Bluffs
K.layer("sky_and_bluffs", function()
  K.sky(W, 74, {{18, 26, 0.8}, {150, 10, 1.1}, {356, 30, 0.75}})

  -- Distant Kaw Valley bluffs & dense cottonwood gallery forest along the north shore
  for x = 0, W - 1 do
    local bh = 58 + math.floor(4 * math.sin(tau * x / 432.0 + 0.4) + 2 * math.cos(tau * x / 144.0))
    for y = bh, 74 do
      K.px(x, y, (y == bh) and "mist" or "far_hill")
    end
  end
  -- cottonwood and oak crowns along the north shore, irregular and overlapping
  local x = -4
  while x < W + 6 do
    local r = 4 + K.rnd(5)
    local cy = 70 - K.rnd(4) + ((r > 6) and -2 or 0)
    K.ellipse(x, cy, r, r - 1, "pine")
    K.ellipse(x - 1, cy - 1, r - 1, r - 2, "leaf")
    K.ellipse(x - 2, cy - 2, math.max(1, r - 3), math.max(1, r - 4), "sage")
    x = x + r + K.rnd(4)
  end
  K.rect(0, 72, W, 5, "pine")
  for i = 1, 60 do K.px(K.rnd(W), 72 + K.rnd(4), "leaf") end
  -- Far sandy riverbank & north ferry landing post
  K.rect(0, 76, W, 2, "sand")
  K.rect(0, 77, W, 1, "ochre")
  K.rect(134, 71, 3, 7, "wood")
  K.px(134, 71, "sand")
end)

----------------------------------------------------------------- 2. Wide Muddy Kansas River
K.layer("muddy_water", function()
  -- Yellow-brown turbid water: Palmer (1845) calls the Kaw "a muddy stream"; Fremont (1842)
  -- a "yellow turbid current". Darker under the far trees, paler where it takes the sky.
  K.rect(0, 78, W, 72, "silt")
  K.rect(0, 78, W, 5, "silt_dk")
  K.dither(0, 83, W, 4, "silt_dk", "silt")
  for y = 96, 128 do
    for x = 0, W - 1 do
      if (x + y) % 2 == 0 and K.rnd(100) < 50 - math.abs(y - 112) * 3 then K.px(x, y, "silt_lt") end
    end
  end
  for i = 1, 170 do
    local rx = K.rnd(W - 10)
    local ry = 82 + K.rnd(67)
    local len = 3 + K.rnd(8) + math.floor((ry - 80) / 12)
    local col = (i % 5 == 0) and "silt_dk" or ((i % 3 == 0) and "light_blue" or "silt_lt")
    if ry < 90 then col = (i % 2 == 0) and "pine" or "silt_dk" end
    K.rect(rx, ry, len, 1, col)
  end
  for i = 1, 24 do K.px(K.rnd(W), 90 + K.rnd(58), "cream") end
  -- the far bank's reflection
  K.rect(0, 78, W, 1, "pine")

  -- Floating driftwood branch in the current
  K.line(348, 134, 366, 132, "deep")
  K.line(354, 133, 358, 130, "wood")
  K.rect(346, 135, 22, 1, "sand")
end)

----------------------------------------------------------------- 3. Pappan's Dugout-Hull Plank Ferry & Guide Rope
K.layer("ferry", function()
  -- Guide hawser cable stretched from the north bank post to the ferry bow, with water reflection
  K.line(135, 76, 186, 112, "sand")
  K.line(136, 77, 186, 113, "wood")

  -- Wake & bow ripples around the twin dugout hulls
  K.ellipse(232, 127, 52, 4, "sand")
  K.ellipse(234, 127, 48, 3, "wood")
  K.rect(176, 118, 12, 1, "cream")
  K.rect(172, 125, 14, 1, "cream")
  K.rect(282, 119, 16, 1, "sand")
  K.rect(286, 126, 18, 1, "sand")

  -- Far dugout canoe hull (carved cottonwood log with tapered bow & stern)
  K.poly({{178, 116}, {190, 113}, {274, 113}, {286, 116}, {276, 119}, {188, 119}}, "deep")
  K.rect(190, 114, 84, 2, "wood")
  K.rect(192, 113, 80, 1, "ochre")

  -- Timber plank deck platform spanning the two dugout hulls
  K.poly({{184, 114}, {280, 114}, {284, 122}, {180, 122}}, "ochre")
  K.rect(180, 121, 104, 2, "rust")
  K.rect(180, 123, 104, 1, "deep")
  -- Individual cross-planks & low wheel guard rails
  for px_x = 184, 278, 6 do
    K.line(px_x, 114, px_x - 2, 122, "wood")
    K.px(px_x + 1, 114, "sand")
  end
  K.rect(182, 112, 100, 2, "wood")
  K.rect(182, 112, 100, 1, "sand")

  -- Near dugout canoe hull below the front edge of the platform
  K.poly({{176, 124}, {188, 121}, {276, 121}, {288, 124}, {278, 127}, {186, 127}}, "deep")
  K.rect(188, 122, 88, 2, "wood")
  K.rect(190, 121, 84, 1, "ochre")
  K.rect(186, 126, 92, 1, "ink")

  -- Covered wagon Chocked & riding aboard the ferry platform
  K.wagon(196, 118, -1)

  -- Two ferrymen working the guide rope and setting pole
  K.person(186, 117, "rust", "wood", false)
  K.person(264, 118, "blue", "sand", false)
  K.line(266, 112, 278, 134, "sand") -- long setting pole reaching into the river
end)

----------------------------------------------------------------- 4. Near Sandy Ferry Landing & Waiting Ox Team
K.layer("near_bank", function()
  -- Sloping sandy/muddy south bank on the lower left
  K.poly({{0, 100}, {46, 110}, {96, 128}, {132, 150}, {0, 150}}, "sand")
  K.poly({{0, 106}, {42, 115}, {88, 132}, {118, 150}, {0, 150}}, "ochre")
  K.poly({{0, 118}, {64, 134}, {96, 150}, {0, 150}}, "grass")
  K.dither(0, 116, 70, 5, "ochre", "grass")

  -- Corduroy timber landing planks at the water's edge
  for i = 0, 5 do
    local lx = 68 + i * 7
    local ly = 122 + i * 4
    K.rect(lx, ly, 12, 2, "wood")
    K.rect(lx, ly, 12, 1, "sand")
  end

  -- South bank mooring post & coiled hawser
  K.rect(58, 112, 4, 12, "deep")
  K.rect(58, 112, 2, 11, "wood")
  K.ellipse(60, 123, 5, 2, "sand")

  -- Cottonwood tree & waiting ox team on the south bank
  K.elm(22, 118, 1)
  K.team(28, 142, 1, {"light", true}, {"dark", false})
  K.person(64, 142, "wood", "sand", false)
end)

K.save("location_kansas_river")
