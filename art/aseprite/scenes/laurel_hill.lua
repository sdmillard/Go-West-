-- Laurel Hill Chute on the Barlow Road (432x150).
-- Historical reference: Oregon Encyclopedia Barlow Road description & WESTERN_REFERENCES.md.
-- Steep timbered mountain descent where emigrants snubbed hemp ropes around trees/stumps
-- at the crest and trailed drag-logs behind their locked-wheel wagons to slide down the chute.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184832)

----------------------------------------------------------------- 1. Sky & Cascade MountainRidges
K.layer("sky_and_cascades", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 18, "light_blue")

  K.cloud(200, 14, 0.9)
  K.cloud(380, 24, 0.7)

  -- Distant Cascade peaks beyond the steep drop-off
  K.poly({{0, 72}, {44, 52}, {88, 66}, {140, 36}, {204, 67}, {254, 46}, {314, 68}, {372, 38}, {432, 70}, {432, 150}, {0, 150}}, "haze")
  K.poly({{126, 44}, {140, 36}, {152, 44}, {138, 47}}, "cream")
  K.poly({{358, 46}, {372, 38}, {384, 46}, {370, 49}}, "cream")

  for x = 0, W - 1 do
    local fh = 76 + math.floor(4 * math.sin(tau * x / 432.0 + 0.4) + 3 * math.cos(tau * x / 144.0))
    for y = fh, 149 do
      K.px(x, y, (y == fh) and "far_hill" or ((y < fh + 14) and "teal" or "sage"))
    end
  end
end)

----------------------------------------------------------------- 2. Steep Laurel Hill Slope & Raw Earth Chute
K.layer("steep_chute", function()
  -- Steep timbered mountain flank dropping diagonally from upper-left (0, 44) to lower-right (432, 147)
  K.poly({{0, 44}, {98, 62}, {432, 146}, {432, 150}, {0, 150}}, "pine")
  K.poly({{0, 52}, {92, 68}, {410, 150}, {0, 150}}, "leaf")

  -- Forest floor texture across the steep hillside
  for i = 1, 700 do
    local x = K.rnd(W)
    local y = 46 + K.rnd(104)
    local cur = K.at(x, y)
    if cur == "pine" or cur == "leaf" then
      K.px(x, y, (i % 3 == 0) and "grass" or ((i % 2 == 0) and "pine" or "ink"))
    end
  end

  -- Raw, gouged ochre/rust earth chute plunging down the 60% grade
  K.poly({{52, 62}, {78, 60}, {362, 144}, {312, 148}}, "ochre")
  K.poly({{56, 63}, {74, 61}, {350, 143}, {322, 146}}, "gold")
  -- Deep locked-wheel gouges & rope-burn ruts down the chute
  K.line(58, 63, 326, 145, "rust")
  K.line(59, 63, 327, 145, "deep")
  K.line(70, 62, 346, 143, "rust")
  K.line(71, 62, 347, 143, "deep")
  K.line(57, 63, 325, 145, "sand")

  -- Conifers flanking the steep chute
  for _, tr in ipairs({{18, 118, 42}, {82, 134, 46}, {132, 142, 40}, {284, 118, 34}, {356, 136, 36}}) do
    K.conifer(tr[1], tr[2], tr[3], "ink", "pine", "leaf")
  end
end)

----------------------------------------------------------------- 3. Snubbing Tree, Taut Hemp Rope & Lowered Wagon
K.layer("snubbed_wagon", function()
  -- Heavy anchor Douglas-fir at the top of the chute with rope-scarred trunk (x = 43, y = 81)
  K.conifer(43, 81, 52, "ink", "pine", "leaf")
  -- Rope-burned bark ring & coiled snubbing turns around the anchor trunk base
  K.rect(41, 74, 5, 3, "sand")
  K.rect(41, 75, 5, 1, "ochre")

  -- Taut hemp hawser cable snubbed from the anchor tree to the rear axle of the descending wagon
  K.line(46, 75, 192, 116, "cream")
  K.line(46, 76, 192, 117, "sand")
  K.line(46, 77, 192, 118, "wood")

  -- Emigrant bracing the snubbing line near the top & driver guiding the wagon down the chute
  K.person(54, 78, "rust", "wood", false)
  K.wagon(190, 124, 1)
  K.person(246, 128, "blue", "sand", false)
end)

K.save("location_laurel_hill")
