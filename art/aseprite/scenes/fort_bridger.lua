-- Fort Bridger Trading Post on Blacks Fork (432x150).
-- Historical reference: NPS Fort Bridger site history & Wyoming SHPO report.
-- Depicts Jim Bridger & Louis Vasquez's 1843-1848 rustic log trading cabins and picket
-- stockade in the braided Blacks Fork meadow—omitting the 1858 U.S. Army stone complex.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184818)

----------------------------------------------------------------- 1. Sky & Distant Uinta Mountains
K.layer("sky_and_mountains", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 14, "light_blue")

  K.cloud(40, 16, 1.35)
  K.cloud(304, 14, 1.4)

  -- Distant snow-streaked Uinta Mountain range on the southern horizon
  K.poly({{0, 72}, {44, 52}, {84, 67}, {138, 36}, {198, 66}, {248, 45}, {310, 68}, {368, 38}, {432, 70}, {432, 86}, {0, 86}}, "haze")
  -- Sunlit snow crests on the higher peaks
  K.poly({{122, 45}, {138, 36}, {148, 44}, {136, 48}}, "cream")
  K.poly({{236, 52}, {248, 45}, {258, 52}, {246, 55}}, "cream")
  K.poly({{354, 46}, {368, 38}, {378, 46}, {366, 50}}, "cream")

  for x = 0, W - 1 do
    local fh = 76 + math.floor(4 * math.sin(tau * x / 432.0 + 0.5) + 2 * math.cos(tau * x / 144.0))
    for y = fh, 92 do
      K.px(x, y, (y == fh) and "far_hill" or "sage")
    end
  end
end)

----------------------------------------------------------------- 2. Blacks Fork Meadow, Log Cabins & Picket Enclosure
K.layer("fort_bridger", function()
  K.rect(0, 90, W, 14, "sage")
  K.dither(0, 100, W, 6, "sage", "grass")
  K.rect(0, 106, W, 44, "grass")
  K.dither(0, 140, W, 10, "grass", "pine")

  -- Helper for Bridger's rough-hewn horizontal log cabins with mud chinking & turf roofs
  local function log_cabin(x, y, w, h)
    K.shadow(x - 2, y + h, w + 4)
    K.rect(x, y, w, h, "wood")
    -- Horizontal log rounds & pale mud chinking lines
    for ly = y + 3, y + h - 2, 4 do
      K.rect(x + 1, ly, w - 2, 1, "sand")
      K.rect(x, ly + 1, w, 1, "deep")
    end
    -- Interlocking notched log corners
    for ly = y + 1, y + h - 2, 2 do
      K.rect(x - 1, ly, 2, 1, "ochre")
      K.rect(x + w - 1, ly, 2, 1, "deep")
    end
    -- Low pole-and-sod roof
    K.rect(x - 3, y - 4, w + 6, 4, "deep")
    K.rect(x - 2, y - 5, w + 4, 2, "sage")
    K.rect(x - 2, y - 5, w + 4, 1, "gold")
    -- Doorway & small trade windows
    local dx = x + math.floor(w / 2) - 5
    K.rect(dx, y + h - 18, 10, 18, "deep")
    K.rect(dx + 1, y + h - 17, 8, 17, "ink")
    K.rect(x + 9, y + 7, 6, 7, "deep")
    K.rect(x + 10, y + 8, 4, 5, "light_blue")
    K.rect(x + w - 15, y + 7, 6, 7, "deep")
    K.rect(x + w - 14, y + 8, 4, 5, "light_blue")
  end

  -- Three low log trading & dwelling cabins inside the enclosure
  log_cabin(80,  84, 64, 30)
  log_cabin(164, 82, 66, 32)
  log_cabin(258, 84, 64, 30)

  -- Rustic vertical cottonwood-picket fence enclosing the trading post yard (x = 58..348)
  K.shadow(56, 124, 296)
  for px_x = 58, 348, 5 do
    if px_x < 192 or px_x > 216 then
      local ph = 18 + (px_x % 3)
      K.rect(px_x, 124 - ph, 4, ph, "wood")
      K.px(px_x, 124 - ph, "ochre")
      K.rect(px_x + 3, 124 - ph + 1, 1, ph - 1, "deep")
    end
  end
  -- Horizontal ledger rails binding the picket fence
  K.rect(58, 110, 134, 2, "rust"); K.rect(218, 110, 132, 2, "rust")
  K.rect(58, 119, 134, 2, "rust"); K.rect(218, 119, 132, 2, "rust")

  -- Open timber gateway in the center of the picket fence
  K.rect(192, 100, 26, 25, "deep")
  K.rect(195, 103, 20, 22, "ink")
  K.rect(190, 99, 30, 3, "wood")
  K.rect(190, 99, 30, 1, "gold")
end)

----------------------------------------------------------------- 3. Blacks Fork Creek, Trail & Wagon
K.layer("creek_and_wagon", function()
  -- Wagon path leading from the gate across the creek
  K.poly({{194, 124}, {216, 124}, {304, 150}, {232, 150}}, "ochre")
  K.poly({{198, 124}, {212, 124}, {288, 150}, {246, 150}}, "gold")

  -- Braided Blacks Fork stream channel in the foreground (y = 129..137)
  K.rect(0, 128, W, 1, "sand")
  K.rect(0, 129, W, 9, "sky_top")
  K.rect(0, 131, W, 5, "sky")
  for x = 10, W - 10, 18 do
    K.rect(x, 132 + (x % 3), 5, 1, (x % 36 == 0) and "white" or "light_blue")
  end
  K.rect(0, 138, W, 1, "sand")

  for i = 1, 500 do
    local x = K.rnd(W)
    local y = 92 + K.rnd(58)
    local cur = K.at(x, y)
    if cur == "grass" or cur == "sage" then
      K.px(x, y, (i % 3 == 0) and "leaf" or ((i % 2 == 0) and "sage" or "gold"))
    end
  end

  -- Mountain man / trader & arriving emigrant wagon
  K.person(228, 125, "ochre", "wood", false)
  K.wagon(24, 143, 1)
end)

K.save("location_fort_bridger")
