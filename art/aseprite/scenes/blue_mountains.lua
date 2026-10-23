-- Blue Mountains Timbered Pass (432x150).
-- Historical reference: Joel Palmer's 1845 journal & WESTERN_REFERENCES.md.
-- Dense ponderosa pine & Douglas-fir forest covering the Blue Mountains crest,
-- with the narrow rocky emigrant road climbing through a gap in the timber.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184826)

----------------------------------------------------------------- 1. Sky & High Blue Mountain Ridge
K.layer("sky_and_ridge", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 14, "light_blue")

  K.cloud(40, 16, 1.35)
  K.cloud(304, 14, 1.4)

  -- Distant Blue Mountain summits
  K.poly({{0, 72}, {44, 52}, {88, 66}, {140, 36}, {204, 67}, {254, 46}, {314, 68}, {372, 38}, {432, 70}, {432, 92}, {0, 92}}, "haze")
  K.poly({{126, 44}, {140, 36}, {152, 44}, {138, 47}}, "cream")
  K.poly({{358, 46}, {372, 38}, {384, 46}, {370, 49}}, "cream")

  for x = 0, W - 1 do
    local fh = 72 + math.floor(5 * math.sin(tau * x / 432.0 + 0.3) + 3 * math.cos(tau * x / 144.0))
    for y = fh, 102 do
      K.px(x, y, (y == fh) and "far_hill" or "teal")
    end
  end
end)

----------------------------------------------------------------- 2. Forest Floor & Winding Timber Road
K.layer("floor_and_road", function()
  K.rect(0, 88, W, 14, "pine")
  K.dither(0, 98, W, 6, "pine", "leaf")
  K.rect(0, 104, W, 46, "grass")
  K.dither(0, 138, W, 12, "grass", "pine")

  -- Winding sandy/rocky pass road climbing through the timber gap (x = 188..245)
  K.poly({{184, 150}, {214, 106}, {235, 88}, {248, 91}, {240, 120}, {234, 150}}, "sand")
  K.poly({{190, 150}, {218, 106}, {237, 89}, {245, 91}, {236, 120}, {228, 150}}, "ochre")
  K.poly({{196, 150}, {221, 108}, {238, 90}, {242, 91}, {232, 120}, {222, 150}}, "gold")
  K.line(192, 149, 237, 89, "rust")
  K.line(226, 149, 244, 91, "rust")

  for i = 1, 700 do
    local x = K.rnd(W)
    local y = 90 + K.rnd(60)
    local cur = K.at(x, y)
    if cur == "grass" or cur == "leaf" or cur == "pine" then
      K.px(x, y, (i % 3 == 0) and "sage" or ((i % 2 == 0) and "leaf" or "pine"))
    elseif cur == "ochre" or cur == "gold" then
      K.px(x, y, (i % 3 == 0) and "sand" or "rust")
    end
  end
end)

----------------------------------------------------------------- 3. Dense Blue Mountain Conifer Ranks & Wagon
K.layer("conifers_and_wagon", function()
  -- Back rank of conifers flanking the road gap
  for x = 8, 424, 18 do
    if x < 208 or x > 252 then
      K.conifer(x, 106 + (x % 7), 32 + (x % 11), "ink", "pine", "teal")
    end
  end

  -- Foreground rank of tall ponderosa pines & Douglas-firs
  for x = 14, 422, 23 do
    if x < 198 or x > 256 then
      local ty = 115 + (x % 11)
      local th = 42 + (x % 15)
      K.conifer(x, ty, th, "ink", "pine", "leaf")
    end
  end

  -- Trailside boulders & arriving wagon
  K.boulder(174, 136, 5, 2)
  K.boulder(252, 132, 6, 3)
  K.wagon(24, 143, 1)
  K.person(84, 142, "blue", "wood", false)
end)

K.save("location_blue_mountains")
