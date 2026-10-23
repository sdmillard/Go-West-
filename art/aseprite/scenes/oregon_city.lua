-- Oregon City on the Willamette River (432x150).
-- Historical reference: Oregon City municipal gallery / Henry James Warre view captioned
-- "Oregon City, Mount Hood, 1848" (WESTERN_REFERENCES.md).
-- Willamette River foreground, east-bank clapboard buildings and church steeple nestled
-- beneath the wooded basalt bluff, distant snow-capped Mount Hood, and a west-bank
-- foreground overlook with a spreading tree and emigrant figure.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184834)

----------------------------------------------------------------- 1. Sky & Distant Mount Hood
K.layer("sky_and_mount_hood", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 32, "light_blue")

  K.cloud(40, 16, 1.35)
  K.cloud(316, 14, 1.4)

  -- Distant snow-crowned volcanic cone of Mount Hood rising above the Cascade skyline (cx = 228, y = 21..82)
  for y = 21, 82 do
    local t = (y - 21) / 61.0
    local hw = math.floor(94 * (t ^ 0.94) + 1.5 * math.sin(y * 0.25))
    local lx, rx = 228 - hw, 228 + hw
    local ridge = 228 + math.floor(5 * t * math.sin(y * 0.2))
    for x = lx, rx do
      local c
      local snow_lim = 0.34 + 0.07 * math.sin(x * 0.22)
      if t < snow_lim then
        c = (x <= ridge) and ((t < 0.18) and "white" or "cream") or "mist"
      else
        c = (x <= ridge) and "haze" or "far_hill"
      end
      K.px(x, y, c)
    end
  end
end)

----------------------------------------------------------------- 2. Wooded Basalt Bluff & East-Bank Town of Oregon City
K.layer("bluff_and_town", function()
  -- Wooded basalt ridge rising behind Oregon City (y = 60..108)
  for x = 0, W - 1 do
    local by = 68 - math.floor(7 * math.sin(tau * x / 432.0 - 0.3) + 3 * math.cos(tau * x / 144.0))
    for y = by, 108 do
      K.px(x, y, (y == by) and "teal" or "pine")
    end
  end
  for x = 8, 424, 14 do
    local cy = 68 - math.floor(7 * math.sin(tau * x / 432.0 - 0.3) + 3 * math.cos(tau * x / 144.0))
    K.conifer(x, cy + 4 + (x % 4), 16 + (x % 6), "ink", "pine", "teal")
  end

  -- Exposed basalt cliff face & cleared town terrace along the east bank (x = 120..432, y = 70..109)
  K.poly({{174, 85}, {243, 76}, {298, 82}, {368, 64}, {432, 72}, {432, 109}, {120, 109}}, "wood")
  K.poly({{120, 96}, {240, 92}, {432, 90}, {432, 109}, {120, 109}}, "sand")
  K.rect(118, 107, 314, 2, "ochre")

  -- White frame church with pointed steeple on the left of the town terrace (x = 124, y = 76)
  K.poly({{130, 70}, {135, 52}, {140, 70}}, "cream")
  K.line(135, 52, 140, 70, "sand")
  K.px(135, 50, "white"); K.px(135, 51, "gold")
  K.poly({{122, 78}, {135, 67}, {148, 78}}, "roof_dk")
  K.rect(124, 78, 22, 29, "cream")
  K.rect(141, 78, 5, 29, "sand")
  for _, wx in ipairs({127, 133, 139}) do
    K.rect(wx, 83, 3, 7, "deep")
    K.px(wx + 1, 84, "light_blue")
  end
  K.rect(133, 98, 4, 9, "deep")

  -- Seven 1840s frame houses, stores & warehouses along the east-bank waterfront
  local houses = {
    {152, 22, 18, "sand",  "ochre", false},
    {184, 26, 22, "cream", "sand",  false},
    {222, 32, 28, "sand",  "ochre", true},
    {266, 25, 19, "ochre", "rust",  false},
    {304, 28, 26, "cream", "sand",  true},
    {346, 36, 30, "sand",  "ochre", true},
    {394, 26, 22, "rust",  "wood",  false},
  }
  for _, h in ipairs(houses) do
    local hx, hw, hh, wall_c, sh_c, two_story = h[1], h[2], h[3], h[4], h[5], h[6]
    local hy = 108 - hh
    K.gable_roof(hx, hy, hw, 10)
    K.clapboard(hx, hy, hw, hh, wall_c, sh_c)
    K.door(hx + math.floor(hw / 2) - 3, 108, 10)
    for wx = hx + 4, hx + hw - 8, 9 do
      K.rect(wx, hy + 4, 4, 6, "deep")
      K.rect(wx + 1, hy + 5, 2, 4, "light_blue")
      if two_story and math.abs(wx - (hx + math.floor(hw / 2) - 2)) > 4 then
        K.rect(wx, hy + 14, 4, 6, "deep")
        K.rect(wx + 1, hy + 15, 2, 4, "light_blue")
      end
    end
  end
end)

----------------------------------------------------------------- 3. Willamette River & West-Bank Foreground Overlook
K.layer("willamette_and_overlook", function()
  -- Broad Willamette River in the foreground (y = 108..150)
  K.rect(0, 108, W, 42, "blue")
  K.rect(0, 111, W, 36, "sky_top")
  K.rect(0, 116, W, 26, "sky")

  -- Subtle building reflections & water ripples across the Willamette
  for x = 124, 420, 6 do
    K.rect(x, 109, 3, 2, "sand")
    K.rect(x + 1, 111, 2, 2, "light_blue")
  end
  for i = 1, 80 do
    local rx = 6 + K.rnd(W - 16)
    local ry = 110 + K.rnd(38)
    K.rect(rx, ry, 4 + (i % 4), 1, (i % 3 == 0) and "white" or "light_blue")
  end

  -- West-bank foreground promontory on the lower left (x = 0..124, y = 122..150)
  K.poly({{0, 122}, {70, 128}, {122, 150}, {0, 150}}, "sand")
  K.poly({{0, 125}, {66, 131}, {114, 150}, {0, 150}}, "ochre")
  K.poly({{0, 130}, {58, 135}, {98, 150}, {0, 150}}, "grass")
  for i = 1, 160 do
    local x = K.rnd(115)
    local y = 124 + K.rnd(26)
    if K.at(x, y) == "grass" then
      K.px(x, y, (i % 2 == 0) and "leaf" or "sage")
    end
  end

  -- Framing west-bank tree & emigrant figure gazing across at Oregon City & Mount Hood
  K.elm(14, 138, 1)
  K.person(60, 142, "pine", "sand", false)
end)

K.save("location_oregon_city")
