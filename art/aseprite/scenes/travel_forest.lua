-- Regional Conifer Forest Travel Scene (432x150).
-- Used when terrain == "forest" (Blue Mountains / Barlow Road / Cascade forests).
-- Bottom strip (y = 100..150) is seamlessly tileable horizontally for trail_view.gd scrolling.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 1851)

----------------------------------------------------------------- 1. Sky & Distant Timbered Ridges
K.layer("sky_and_ridge", function()
  K.rect(0, 0, W, 16, "sky_top")
  K.blend(0, 16, W, "sky_top", "sky")
  K.rect(0, 19, W, 18, "sky")
  K.blend(0, 37, W, "sky", "light_blue")
  K.rect(0, 40, W, 18, "light_blue")
  K.blend(0, 58, W, "light_blue", "mist")
  K.rect(0, 61, W, 14, "mist")

  K.cloud(38, 16, 1.3)
  K.cloud(304, 14, 1.4)

  -- Distant timbered Blue Mountains / Cascade ridges
  for x = 0, W - 1 do
    local r1 = 46 + math.floor(8 * math.sin(tau * x / 432.0 + 0.3) + 4 * math.cos(tau * x / 216.0))
    for y = r1, 88 do K.px(x, y, (y == r1) and "haze" or "far_hill") end

    local r2 = 58 + math.floor(6 * math.cos(tau * x / 432.0 + 1.1) + 3 * math.sin(tau * x / 144.0) + 1.5 * math.sin(tau * x / 36.0))
    for y = r2, 96 do K.px(x, y, (y <= r2 + 1) and "teal" or "pine") end
  end
end)

----------------------------------------------------------------- 2. Deep Layered Douglas-Fir & Ponderosa Forest
K.layer("forest", function()
  -- Dark forest under-canopy & fern floor (y = 84..99)
  K.rect(0, 84, W, 10, "ink")
  K.rect(0, 94, W, 6, "pine")
  K.dither(0, 92, W, 4, "ink", "pine")

  -- Back rank of dense conifers (teal/pine)
  for tx = 4, W - 4, 11 do
    local ty = 90 + (tx % 5)
    local th = 22 + ((tx * 3) % 12)
    K.conifer(tx, ty, th, "ink", "pine", "teal")
  end

  -- Mid-rank conifers (pine/leaf) with varied heights & natural clustering
  local mid_trees = {
    {10, 95, 34}, {24, 96, 28}, {42, 94, 38}, {56, 97, 26}, {74, 95, 36},
    {92, 96, 30}, {112, 94, 40}, {128, 97, 27}, {146, 95, 35}, {166, 96, 31},
    {184, 94, 39}, {202, 97, 28}, {220, 95, 36}, {238, 96, 30}, {256, 94, 41},
    {274, 97, 27}, {292, 95, 35}, {312, 96, 32}, {330, 94, 38}, {348, 97, 28},
    {366, 95, 36}, {386, 96, 31}, {404, 94, 39}, {420, 96, 30}
  }
  for _, tr in ipairs(mid_trees) do
    K.conifer(tr[1], tr[2], tr[3], "ink", "pine", "leaf")
  end

  -- Foreground old-growth Douglas-firs with warm sunlit foliage & forest-edge shrubs concealing trunk bases
  local fore_trees = {
    {18, 99, 44}, {64, 98, 42}, {102, 99, 46}, {154, 98, 40}, {194, 99, 45},
    {246, 98, 42}, {284, 99, 46}, {338, 98, 41}, {376, 99, 44}, {412, 99, 42}
  }
  for _, tr in ipairs(fore_trees) do
    K.conifer(tr[1], tr[2], tr[3], "ink", "leaf", "grass")
    -- Understory huckleberry & fern bushes around the base of the trunk
    K.ellipse(tr[1] - 3, tr[2] - 1, 5, 2, "pine")
    K.ellipse(tr[1] + 3, tr[2], 4, 2, "leaf")
    K.px(tr[1] - 4, tr[2] - 2, "grass")
  end
end)

----------------------------------------------------------------- 3. Horizontally Tileable Forest Trail (y = 100..150)
K.layer("scrolling_ground", function()
  K.rect(0, 100, W, 50, "leaf")
  K.dither(0, 100, W, 5, "pine", "leaf")
  K.dither(0, 142, W, 8, "leaf", "pine")

  for x = 0, W - 1 do
    local wave = math.floor(1.8 * math.sin(tau * x / 432.0) + 1.0 * math.cos(tau * x / 216.0))
    local top = 112 + wave
    local bot = 139 + wave

    K.px(x, top - 1, "grass")
    K.px(x, top, "ochre")
    -- Rich damp forest-loam & clay road
    K.rect(x, top + 1, 1, bot - top - 2, "rust")
    K.rect(x, top + 4, 1, bot - top - 8, "ochre")
    K.rect(x, top + 11, 1, 5, "gold")
    K.px(x, bot - 1, "wood")
    K.px(x, bot, "deep")

    local rut1 = top + 9
    local rut2 = top + 21
    if (x % 16) ~= 0 then
      K.px(x, rut1 - 1, "gold"); K.px(x, rut1, "deep"); K.px(x, rut1 + 1, "wood")
    end
    if ((x + 8) % 16) ~= 0 then
      K.px(x, rut2 - 1, "gold"); K.px(x, rut2, "deep"); K.px(x, rut2 + 1, "wood")
    end
  end

  -- Forest floor texture: ferns, moss, fallen needles & bark
  for i = 1, 1200 do
    local x = K.rnd(W)
    local y = 100 + K.rnd(50)
    local cur = K.at(x, y)
    if cur == "ochre" or cur == "rust" or cur == "gold" then
      K.px(x, y, (i % 3 == 0) and "wood" or ((i % 2 == 0) and "sand" or "rust"))
    else
      K.px(x, y, (i % 3 == 0) and "grass" or ((i % 2 == 0) and "pine" or "sage"))
    end
  end

  -- Fallen mossy nurse logs & fern fronds along the forest road edges
  for _, lx in ipairs({26, 124, 236, 348}) do
    K.rect(lx, 106, 14, 3, "wood")
    K.rect(lx, 106, 14, 1, "rust")
    K.rect(lx + 2, 105, 6, 1, "grass")
    K.rect(lx, 108, 14, 1, "ink")
  end
  for _, fx in ipairs({18, 64, 104, 156, 198, 248, 294, 338, 386, 418}) do
    K.line(fx, 148, fx - 3, 143, "grass")
    K.line(fx, 148, fx + 3, 143, "leaf")
    K.line(fx, 148, fx, 142, "sage")
  end
end)

K.save("travel_forest")
