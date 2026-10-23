-- Grande Ronde Valley (432x150).
-- Historical reference: Joel Palmer's 1845 journal & WESTERN_REFERENCES.md.
-- Broad, fertile oval mountain-ringed basin framed by Blue Mountain ponderosa pines
-- on the left and right overlooks as the wagon road descends into the valley.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184825)

----------------------------------------------------------------- 1. Sky & Blue Mountains Ringing the Basin
K.layer("sky_and_mountains", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 14, "light_blue")

  K.cloud(42, 16, 1.35)
  K.cloud(304, 14, 1.4)

  -- Blue Mountains & Wallowa spurs encircling the Grande Ronde basin
  K.poly({{0, 72}, {42, 50}, {88, 66}, {140, 36}, {202, 66}, {254, 46}, {314, 68}, {372, 38}, {432, 70}, {432, 92}, {0, 92}}, "haze")
  K.poly({{126, 44}, {140, 36}, {152, 44}, {138, 47}}, "cream")
  K.poly({{358, 46}, {372, 38}, {384, 46}, {370, 49}}, "cream")

  for x = 0, W - 1 do
    local fh = 76 + math.floor(5 * math.sin(tau * x / 432.0 + 0.5) + 3 * math.cos(tau * x / 144.0))
    for y = fh, 102 do
      K.px(x, y, (y == fh) and "far_hill" or "teal")
    end
  end
end)

----------------------------------------------------------------- 2. Fertile Oval Valley Basin & Trail
K.layer("valley_basin", function()
  K.rect(0, 96, W, 54, "pine")
  -- Broad oval meadow floor of the Grande Ronde Valley
  K.ellipse(216, 118, 196, 36, "grass")
  K.ellipse(216, 114, 154, 24, "sage")
  K.ellipse(216, 112, 110, 14, "gold")
  K.ellipse(216, 113, 106, 13, "sage")

  -- Winding Grande Ronde River glinting across the middle of the valley floor
  K.poly({{84, 110}, {182, 106}, {294, 111}, {348, 108}, {344, 112}, {290, 114}, {180, 109}, {80, 113}}, "sky")
  for x = 96, 336, 22 do
    K.rect(x, 109 + (x % 3), 5, 1, "light_blue")
  end

  -- Wagon road descending from the foreground into the valley floor
  K.poly({{186, 102}, {202, 102}, {304, 150}, {234, 150}}, "ochre")
  K.poly({{190, 102}, {198, 102}, {288, 150}, {248, 150}}, "gold")
  K.line(188, 103, 244, 149, "rust")
  K.line(199, 103, 290, 149, "rust")

  for i = 1, 650 do
    local x = K.rnd(W)
    local y = 94 + K.rnd(56)
    local cur = K.at(x, y)
    if cur == "grass" or cur == "sage" then
      K.px(x, y, (i % 3 == 0) and "leaf" or ((i % 2 == 0) and "sage" or "gold"))
    end
  end
end)

----------------------------------------------------------------- 3. Framing Ponderosa Pines & Wagon
K.layer("pines_and_wagon", function()
  -- Tall ponderosa pines framing the left and right valley overlooks
  for _, tx in ipairs({16, 38, 60, 374, 394, 414}) do
    local th = 42 + (tx % 9)
    K.conifer(tx, 124 + (tx % 4), th, "ink", "pine", "leaf")
  end

  K.wagon(24, 143, 1)
  K.person(84, 142, "blue", "sand", false)
end)

K.save("location_grande_ronde")
