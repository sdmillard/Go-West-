-- Soda Springs & Steamboat Spring on the Bear River (432x150).
-- Historical reference: James F. Wilkins's 1849 sketch "Steam Boat Springs" (NPS Idaho guide).
-- White/cream travertine mineral cones, bubbling teal mineral basins, and Steamboat Spring's
-- spouting water/vapor plume in the open Bear River mountain valley. No later resort buildings.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184819)

----------------------------------------------------------------- 1. Sky & Bear River Range
K.layer("sky_and_range", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 14, "light_blue")

  K.cloud(42, 16, 1.35)
  K.cloud(300, 14, 1.4)

  -- Bear River / Caribou mountain ridges across the valley
  K.poly({{0, 72}, {44, 52}, {88, 68}, {142, 38}, {204, 67}, {256, 46}, {314, 68}, {372, 40}, {432, 70}, {432, 92}, {0, 92}}, "haze")
  K.poly({{128, 46}, {142, 38}, {154, 46}, {140, 49}}, "cream")
  K.poly({{358, 48}, {372, 40}, {384, 48}, {370, 51}}, "cream")

  for x = 0, W - 1 do
    local fh = 76 + math.floor(4 * math.sin(tau * x / 432.0 + 0.4) + 3 * math.cos(tau * x / 144.0))
    for y = fh, 98 do
      K.px(x, y, (y == fh) and "far_hill" or "sage")
    end
  end

  -- Bear River glinting along the base of the distant hills
  K.rect(0, 86, W, 5, "sky")
  K.rect(0, 86, W, 1, "sand")
  for x = 16, W - 16, 20 do
    K.rect(x, 88 + (x % 2), 5, 1, "light_blue")
  end
end)

----------------------------------------------------------------- 2. Valley Floor, Trail & Travertine Mineral Cones
K.layer("mineral_springs", function()
  K.rect(0, 92, W, 12, "sage")
  K.dither(0, 100, W, 6, "sage", "grass")
  K.rect(0, 106, W, 44, "grass")
  K.dither(0, 140, W, 10, "grass", "pine")

  -- Wagon road passing through the Soda Springs basin
  K.poly({{184, 96}, {204, 96}, {304, 150}, {234, 150}}, "ochre")
  K.poly({{190, 96}, {198, 96}, {288, 150}, {248, 150}}, "gold")
  K.line(188, 97, 244, 149, "rust")
  K.line(199, 97, 290, 149, "rust")

  for i = 1, 650 do
    local x = K.rnd(W)
    local y = 92 + K.rnd(58)
    local cur = K.at(x, y)
    if cur == "grass" or cur == "sage" then
      K.px(x, y, (i % 3 == 0) and "leaf" or ((i % 2 == 0) and "sage" or "gold"))
    end
  end

  -- Helper for terraced white/ochre travertine spring mound with bubbling teal mineral pool
  local function spring_mound(cx, cy, rx, ry, geyser)
    -- Rust/ochre iron-stained travertine outer apron
    K.ellipse(cx, cy + 2, rx + 4, ry + 2, "ochre")
    K.ellipse(cx - 1, cy + 1, rx + 2, ry + 1, "sand")
    -- Pale cream/white calcium-carbonate sinter rim
    K.ellipse(cx, cy, rx, ry, "cream")
    K.ellipse(cx - 2, cy - 1, rx - 3, ry - 1, "white")
    -- Mineral-rich emerald/teal spring pool
    local prx = math.max(6, math.floor(rx * 0.68))
    local pry = math.max(3, math.floor(ry * 0.56))
    K.ellipse(cx, cy, prx, pry, "teal")
    K.ellipse(cx - 1, cy, prx - 3, math.max(2, pry - 1), "sky")
    -- Effervescent CO2 gas bubbles & foam rings
    for _, off in ipairs({-10, -3, 4, 11}) do
      if math.abs(off) < prx - 2 then
        K.rect(cx + off, cy - 1 + (off % 2), 2, 2, "white")
        K.px(cx + off - 1, cy, "light_blue")
      end
    end
    if geyser then
      -- Steamboat Spring intermittent spouting column & steam puffs
      K.rect(cx - 2, cy - 14, 5, 14, "white")
      K.rect(cx - 1, cy - 18, 3, 18, "white")
      K.ellipse(cx, cy - 18, 5, 3, "cream")
      K.ellipse(cx - 1, cy - 22, 4, 2, "white")
      K.px(cx - 4, cy - 11, "light_blue")
      K.px(cx + 4, cy - 13, "light_blue")
    end
  end

  spring_mound(82,  108, 36, 10, false)
  spring_mound(204, 120, 38, 11, true)  -- Steamboat Spring spouting in the center
  spring_mound(338, 100, 34, 9,  false)
end)

----------------------------------------------------------------- 3. Emigrants Tasting the Water & Wagon
K.layer("wagon", function()
  K.person(154, 122, "blue", "sand", false)
  K.wagon(24, 143, 1)
end)

K.save("location_soda_springs")
