-- South Pass (Continental Divide) (432x150).
-- Historical reference: NPS South Pass landscape description & WESTERN_REFERENCES.md.
-- A wide, open, gently rolling high-elevation sagebrush saddle—deliberately omitting
-- any implausible narrow alpine gorge at the wagon crossing, with only distant low
-- Wind River / Pacific Butte swells on the horizon.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184815)

----------------------------------------------------------------- 1. High-Altitude Sky & Distant Wind River Horizon
K.layer("sky", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 14, "light_blue")

  K.cloud(44, 16, 1.35)
  K.cloud(300, 14, 1.45)

  -- Very distant, low hazy Wind River range on the far left and Oregon Buttes on the far right,
  -- leaving the broad central Continental Divide saddle wide open
  for x = 0, W - 1 do
    local saddle = 70 - math.floor(11 * math.exp(-((x - 68) / 48.0) ^ 2) + 9 * math.exp(-((x - 364) / 46.0) ^ 2))
    for y = saddle, 76 do
      K.px(x, y, (y == saddle) and "mist" or "far_hill")
    end
  end
end)

----------------------------------------------------------------- 2. Wide Sagebrush Saddle & Twin Mounds
K.layer("wide_saddle", function()
  -- Rolling sagebrush slopes flanking the broad central pass
  for x = 0, W - 1 do
    local h_mid = 74 - math.floor(12 * math.exp(-((x - 74) / 62.0) ^ 2) + 10 * math.exp(-((x - 358) / 60.0) ^ 2))
    for y = h_mid, 102 do
      K.px(x, y, (y == h_mid) and "gold" or "sage")
    end
  end

  -- Sandy high-basin floor across the divide (y = 92..150)
  K.poly({{0, 102}, {158, 90}, {282, 92}, {432, 103}, {432, 150}, {0, 150}}, "sand")
  K.dither(0, 98, W, 6, "sage", "sand")

  -- Wide emigrant road crossing the Continental Divide
  K.poly({{184, 92}, {204, 92}, {308, 150}, {232, 150}}, "ochre")
  K.poly({{190, 92}, {198, 92}, {292, 150}, {248, 150}}, "gold")
  K.line(188, 93, 244, 149, "rust")
  K.line(199, 93, 292, 149, "rust")
  K.line(187, 93, 243, 149, "cream")
  K.line(198, 93, 291, 149, "cream")

  -- Alkali grit, desert pebbles & low sagebrush clumps
  for i = 1, 900 do
    local x = K.rnd(W)
    local y = 76 + K.rnd(74)
    local cur = K.at(x, y)
    if cur == "sand" then
      K.px(x, y, (i % 4 == 0) and "sage" or ((i % 2 == 0) and "ochre" or "cream"))
    elseif cur == "sage" then
      K.px(x, y, (i % 3 == 0) and "leaf" or "gold")
    elseif cur == "ochre" or cur == "gold" then
      K.px(x, y, (i % 3 == 0) and "sand" or "rust")
    end
  end

  -- Low wind-sculpted sagebrush bushes across the divide floor
  for _, pt in ipairs({{42, 112}, {114, 106}, {152, 118}, {318, 110}, {362, 122}, {404, 114}, {136, 138}, {346, 140}}) do
    K.shadow(pt[1] - 4, pt[2] + 1, 9)
    K.ellipse(pt[1], pt[2] - 2, 4, 2, "leaf")
    K.ellipse(pt[1] - 1, pt[2] - 3, 3, 2, "sage")
    K.px(pt[1], pt[2], "wood")
  end
end)

----------------------------------------------------------------- 3. Divide Cairn & Arriving Wagon
K.layer("wagon", function()
  -- Small stone cairn marking the Pacific watershed divide beside the road
  K.boulder(172, 114, 5, 2)
  K.boulder(172, 111, 3, 2)
  K.px(172, 109, "cream")

  K.wagon(24, 143, 1)
  K.person(82, 142, "blue", "sand", false)
end)

K.save("location_south_pass")
