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
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 14, "light_blue")

  K.cloud(44, 16, 1.35)
  K.cloud(298, 14, 1.4)

  -- Distant Kaw Valley bluffs & dense cottonwood gallery forest along the north shore
  for x = 0, W - 1 do
    local bh = 58 + math.floor(4 * math.sin(tau * x / 432.0 + 0.4) + 2 * math.cos(tau * x / 144.0))
    for y = bh, 74 do
      K.px(x, y, (y == bh) and "mist" or "far_hill")
    end
    local th = 67 + math.floor(3 * math.sin(x * 0.14) + 2 * math.cos(x * 0.27))
    for y = th, 76 do
      K.px(x, y, (y <= th + 1) and "sage" or ((y <= th + 3) and "leaf" or "pine"))
    end
  end
  -- Far sandy riverbank & north ferry landing post
  K.rect(0, 76, W, 2, "sand")
  K.rect(0, 77, W, 1, "ochre")
  K.rect(134, 71, 3, 7, "wood")
  K.px(134, 71, "sand")
end)

----------------------------------------------------------------- 2. Wide Muddy Kansas River
K.layer("muddy_water", function()
  -- Silt-laden tan/brown water ("clap_sh" #927e62 with ochre/wood current eddies & sand glints)
  K.rect(0, 78, W, 72, "clap_sh")
  K.rect(0, 78, W, 2, "wood")
  K.rect(0, 80, W, 1, "ochre")

  for i = 1, 140 do
    local rx = K.rnd(W - 10)
    local ry = 82 + K.rnd(67)
    local len = 4 + K.rnd(6)
    local col = (i % 4 == 0) and "sand" or ((i % 2 == 0) and "ochre" or "wood")
    K.rect(rx, ry, len, 1, col)
  end

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
