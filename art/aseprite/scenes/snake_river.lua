-- Snake River / Three Island Crossing (432x150).
-- Historical reference: William Henry Jackson's "Three Island Crossing" (NPS Idaho guide).
-- Broad, deep-blue Snake River channel below desert rimrock bluffs, with three elongated
-- sandy islands topped with sagebrush and dark volcanic basalt rock in the foreground.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184821)

----------------------------------------------------------------- 1. Desert Sky & Snake River Canyon Bluffs
K.layer("sky_and_bluffs", function()
  K.rect(0, 0, W, 16, "sky_top")
  K.blend(0, 16, W, "sky_top", "sky")
  K.rect(0, 19, W, 18, "sky")
  K.blend(0, 37, W, "sky", "light_blue")
  K.rect(0, 40, W, 16, "light_blue")
  K.blend(0, 56, W, "light_blue", "sand")
  K.rect(0, 59, W, 30, "sand")

  K.cloud(42, 16, 1.35)
  K.cloud(304, 14, 1.4)

  -- Stepped basalt & sandstone rimrock bluffs along the north bank of the Snake River
  for x = 0, W - 1 do
    local by = 60 + math.floor(5 * math.sin(tau * x / 432.0 + 0.3) + 3 * math.cos(tau * x / 144.0))
    if (x > 40 and x < 110) or (x > 210 and x < 290) or (x > 360) then
      by = by - 5
    end
    for y = by, 90 do
      local c = "rust"
      if y <= by + 1 then
        c = "sand"
      elseif y <= by + 4 then
        c = "ochre"
      elseif y % 5 == 0 then
        c = "ochre"
      elseif y % 5 == 2 then
        c = "wood"
      end
      K.px(x, y, c)
    end
  end
  K.poly({{0, 86}, {180, 79}, {432, 76}, {432, 94}, {0, 96}}, "sand")
end)

----------------------------------------------------------------- 2. Broad Snake River & The Three Islands
K.layer("river_and_islands", function()
  -- Wide, deep-blue Snake River channel (68px wide)
  K.poly({{0, 92}, {432, 81}, {432, 150}, {0, 150}}, "blue")
  K.poly({{0, 96}, {432, 85}, {432, 146}, {0, 150}}, "sky_top")
  K.poly({{0, 102}, {432, 91}, {432, 138}, {0, 148}}, "sky")

  -- Three elongated gravel/sand islands with sagebrush scrub (Three Island Crossing)
  local islands = {{72, 108}, {208, 118}, {340, 103}}
  for _, pt in ipairs(islands) do
    local ix, iy = pt[1], pt[2]
    -- Whitewater wake & shoal reflection around each island
    K.poly({{ix - 48, iy + 4}, {ix + 14, iy - 10}, {ix + 60, iy + 1}, {ix + 12, iy + 11}}, "light_blue")
    -- Sandy gravel bar shore
    K.poly({{ix - 45, iy + 3}, {ix + 14, iy - 9}, {ix + 55, iy}, {ix + 10, iy + 9}}, "ochre")
    K.poly({{ix - 42, iy + 2}, {ix + 14, iy - 8}, {ix + 51, iy}, {ix + 10, iy + 7}}, "sand")
    -- Willows & desert sagebrush crown on each island
    K.poly({{ix - 27, iy}, {ix + 11, iy - 6}, {ix + 36, iy}, {ix + 7, iy + 4}}, "sage")
    K.poly({{ix - 20, iy - 1}, {ix + 9, iy - 5}, {ix + 26, iy - 1}, {ix + 6, iy + 2}}, "leaf")
  end

  -- Current ripples & whitewater riffles between the islands
  for i = 1, 95 do
    local rx = 8 + K.rnd(W - 18)
    local ry = 88 + K.rnd(58)
    local cur = K.at(rx, ry)
    if cur == "blue" or cur == "sky_top" or cur == "sky" then
      K.rect(rx, ry, 4 + (i % 4), 1, (i % 3 == 0) and "white" or "light_blue")
    end
  end
end)

----------------------------------------------------------------- 3. Foreground Basalt Rimrock, Bank & Wagon
K.layer("foreground", function()
  -- Dark volcanic basalt outcrop & sandy ford bank on the lower left
  K.poly({{0, 132}, {98, 128}, {154, 150}, {0, 150}}, "sand")
  K.poly({{0, 136}, {94, 131}, {142, 150}, {0, 150}}, "ochre")
  K.poly({{0, 142}, {91, 133}, {132, 150}, {0, 150}}, "deep")
  -- Columnar basalt joint highlights on the dark foreground rock
  for bx = 12, 112, 14 do
    K.line(bx, 138, bx + 2, 149, "wood")
  end

  K.wagon(24, 143, 1)
  K.person(84, 140, "blue", "sand", false)
end)

K.save("location_snake_river")
