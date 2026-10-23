-- Powder River Valley & The Lone Pine Stump (432x150).
-- Historical reference: Joel Palmer's 1845 journal & WESTERN_REFERENCES.md.
-- Lush Powder River meadow with the famous Lone Pine already felled into a stump
-- (explicitly not reviving a standing tree at Palmer's already-named stump).
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184824)

----------------------------------------------------------------- 1. Sky & Distant Blue / Elkhorn Mountains
K.layer("sky_and_mountains", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 20, "light_blue")

  K.cloud(40, 16, 1.35)
  K.cloud(304, 14, 1.4)

  -- Distant Blue Mountains rising ahead on the western horizon
  K.poly({{0, 74}, {52, 54}, {112, 68}, {178, 42}, {244, 65}, {308, 46}, {374, 66}, {432, 52}, {432, 92}, {0, 92}}, "haze")
  K.poly({{164, 50}, {178, 42}, {190, 50}, {176, 53}}, "cream")
  K.poly({{296, 53}, {308, 46}, {320, 53}, {306, 56}}, "cream")

  for x = 0, W - 1 do
    local hy = 74 + math.floor(4 * math.sin(tau * x / 432.0 + 0.4) + 2 * math.cos(tau * x / 144.0))
    for y = hy, 96 do
      K.px(x, y, (y == hy) and "far_hill" or "sage")
    end
  end
end)

----------------------------------------------------------------- 2. Powder River Meadow, Creek & Trail
K.layer("meadow_and_creek", function()
  K.rect(0, 92, W, 12, "sage")
  K.poly({{0, 106}, {157, 94}, {432, 104}, {432, 150}, {0, 150}}, "grass")
  K.dither(0, 100, W, 6, "sage", "grass")
  K.dither(0, 140, W, 10, "grass", "pine")

  -- Wagon road crossing the Powder River valley
  K.poly({{184, 96}, {204, 96}, {304, 150}, {234, 150}}, "ochre")
  K.poly({{190, 96}, {198, 96}, {288, 150}, {248, 150}}, "gold")
  K.line(188, 97, 244, 149, "rust")
  K.line(199, 97, 290, 149, "rust")

  -- Powder River stream channel (y = 122..129)
  K.rect(0, 121, W, 1, "sand")
  K.rect(0, 122, W, 8, "sky_top")
  K.rect(0, 124, W, 4, "sky")
  for x = 10, W - 10, 18 do
    K.rect(x, 125 + (x % 3), 5, 1, (x % 36 == 0) and "white" or "light_blue")
  end
  K.rect(0, 130, W, 1, "sand")

  for i = 1, 600 do
    local x = K.rnd(W)
    local y = 94 + K.rnd(56)
    local cur = K.at(x, y)
    if cur == "grass" or cur == "sage" then
      K.px(x, y, (i % 3 == 0) and "leaf" or ((i % 2 == 0) and "sage" or "gold"))
    end
  end
end)

----------------------------------------------------------------- 3. The Felled "Lone Pine" Stump & Wagon
K.layer("stump_and_wagon", function()
  -- The famous Lone Pine stump (x = 336..354, y = 113..132), with spreading roots & pale cut heartwood
  K.shadow(332, 132, 26)
  -- Spreading root flare
  K.poly({{334, 132}, {338, 124}, {352, 124}, {356, 132}}, "deep")
  -- Furrowed ponderosa bark trunk
  K.rect(338, 116, 14, 16, "wood")
  K.rect(339, 116, 4, 15, "rust")
  K.rect(349, 116, 3, 16, "deep")
  for bx = 341, 349, 3 do
    K.line(bx, 116, bx, 131, "deep")
  end
  -- Freshly axed pale wood top with growth rings & axe notch
  K.ellipse(345, 115, 8, 2, "sand")
  K.ellipse(345, 115, 5, 1, "cream")
  K.px(345, 115, "ochre")
  -- Scattered wood chips around the base of the stump
  for _, cx in ipairs({331, 335, 355, 359}) do
    K.rect(cx, 131 + (cx % 2), 2, 1, "sand")
  end

  K.wagon(24, 143, 1)
  K.person(84, 142, "blue", "sand", false)
end)

K.save("location_powder_river")
