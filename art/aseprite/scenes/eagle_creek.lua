-- Eagle Creek & Philip Foster's Farm (432x150).
-- Historical reference: Oregon Encyclopedia Barlow Road description & WESTERN_REFERENCES.md.
-- First Willamette Valley settlement at the western foot of the Barlow Road: tall Cascade
-- Douglas-firs opening onto a green clearing, Eagle Creek, and Foster's farmstead.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184833)

----------------------------------------------------------------- 1. Sky & Western Cascade Foothills
K.layer("sky_and_foothills", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 14, "light_blue")

  K.cloud(40, 16, 1.35)
  K.cloud(304, 14, 1.4)

  -- Timbered Cascade foothills receding behind Eagle Creek
  for x = 0, W - 1 do
    local r1 = 52 + math.floor(7 * math.sin(tau * x / 432.0 + 0.3) + 4 * math.cos(tau * x / 216.0))
    for y = r1, 88 do K.px(x, y, (y == r1) and "haze" or "far_hill") end
    local r2 = 64 + math.floor(5 * math.cos(tau * x / 432.0 + 1.0) + 3 * math.sin(tau * x / 144.0))
    for y = r2, 96 do K.px(x, y, (y <= r2 + 1) and "teal" or "pine") end
  end
end)

----------------------------------------------------------------- 2. Clearing, Eagle Creek & Farmstead
K.layer("clearing_and_farm", function()
  K.rect(0, 92, W, 12, "sage")
  K.dither(0, 100, W, 6, "sage", "grass")
  K.rect(0, 106, W, 44, "grass")
  K.dither(0, 140, W, 10, "grass", "pine")

  -- Barlow Road emerging from the forest into the farm clearing
  K.poly({{184, 96}, {204, 96}, {304, 150}, {234, 150}}, "ochre")
  K.poly({{190, 96}, {198, 96}, {288, 150}, {248, 150}}, "gold")
  K.line(188, 97, 244, 149, "rust")
  K.line(199, 97, 290, 149, "rust")

  -- Clear Eagle Creek stream winding across the valley floor
  K.poly({{0, 116}, {170, 104}, {432, 120}, {432, 136}, {166, 119}, {0, 132}}, "sand")
  K.poly({{0, 118}, {170, 106}, {432, 122}, {432, 134}, {166, 117}, {0, 130}}, "blue")
  K.poly({{0, 120}, {170, 108}, {432, 124}, {432, 132}, {166, 115}, {0, 128}}, "sky_top")
  K.poly({{0, 122}, {170, 110}, {432, 126}, {432, 130}, {166, 113}, {0, 126}}, "sky")
  for x = 14, W - 14, 18 do
    local wy = (x < 170) and (124 - math.floor(x * 12 / 170.0)) or (112 + math.floor((x - 170) * 16 / 262.0))
    K.rect(x, wy, 4, 1, (x % 36 == 0) and "white" or "light_blue")
  end

  -- Timber plank foot/wagon bridge over Eagle Creek at the road crossing
  K.poly({{186, 108}, {214, 110}, {222, 122}, {190, 120}}, "wood")
  for bx = 188, 212, 4 do
    K.line(bx, 109, bx + 4, 120, "sand")
  end
  K.line(186, 107, 214, 109, "ochre")

  -- Philip Foster's farmstead building (x = 252, y = 88, w = 48, h = 30)
  K.shadow(248, 118, 56)
  K.chimney(288, 76, 12)
  K.gable_roof(252, 88, 48, 14)
  K.clapboard(252, 88, 48, 30, "sand", "ochre")
  K.door(273, 118, 14)
  K.window(258, 95, 7, 10)
  K.window(286, 95, 7, 10)
  -- Split-rail pasture fence beside the farmhouse
  for fx = 302, 342, 10 do
    K.rect(fx, 110, 2, 8, "wood")
    K.rect(fx, 112, 10, 1, "sand")
    K.rect(fx, 115, 10, 1, "ochre")
  end

  for i = 1, 500 do
    local x = K.rnd(W)
    local y = 94 + K.rnd(56)
    local cur = K.at(x, y)
    if cur == "grass" or cur == "sage" then
      K.px(x, y, (i % 3 == 0) and "leaf" or ((i % 2 == 0) and "sage" or "gold"))
    end
  end
end)

----------------------------------------------------------------- 3. Framing Douglas-Firs & Arriving Wagon
K.layer("firs_and_wagon", function()
  for _, tx in ipairs({10, 38, 74, 354, 392, 422}) do
    K.conifer(tx, 126 + (tx % 4), 56, "ink", "pine", "leaf")
  end

  K.wagon(24, 143, 1)
  K.person(84, 142, "blue", "sand", false)
end)

K.save("location_eagle_creek")
