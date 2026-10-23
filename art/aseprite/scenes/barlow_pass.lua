-- Barlow Pass under Mount Hood (432x150).
-- Historical reference: Oregon Encyclopedia Barlow Road description & WESTERN_REFERENCES.md.
-- Towering snow-capped volcanic cone of Mount Hood rising above the subalpine pass,
-- framed by tall Cascade Douglas-firs and the rough Barlow Road cut.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184831)

----------------------------------------------------------------- 1. Sky & Towering Mount Hood Cone
K.layer("sky_and_mount_hood", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 18, "light_blue")

  K.cloud(150, 22, 0.8)
  K.cloud(370, 10, 1.0)

  -- Flanking Cascade foothills
  K.poly({{0, 74}, {64, 56}, {132, 72}, {336, 70}, {382, 54}, {432, 72}, {432, 94}, {0, 94}}, "far_hill")

  -- Towering volcanic cone of Mount Hood (cx = 232, peak y = 8, base y = 88, x = 118..346)
  for y = 8, 88 do
    local t = (y - 8) / 80.0
    local hw_l = math.floor(114 * (t ^ 0.94) + 2 * math.sin(y * 0.25))
    local hw_r = math.floor(114 * (t ^ 0.94) + 2 * math.cos(y * 0.22))
    local lx, rx = 232 - hw_l, 232 + hw_r
    local ridge = 232 + math.floor(8 * t * math.sin(y * 0.18))
    for x = lx, rx do
      local c
      -- Glacial snowcap & Eliot/Coe/Zigzag glacier fingers extending down the upper cone
      local glacier1 = math.abs((x - lx) - math.floor((rx - lx) * 0.30)) <= 4
      local glacier2 = math.abs((x - lx) - math.floor((rx - lx) * 0.62)) <= 4
      local snow_lim = 0.42 + 0.08 * math.sin(x * 0.18) + ((glacier1 or glacier2) and 0.18 or 0.0)
      if t < snow_lim then
        if x <= ridge then
          c = (x <= lx + 4 or t < 0.22) and "white" or "cream"
        else
          c = (t < 0.26) and "cream" or "mist"
        end
      else
        c = (x <= ridge) and "haze" or "far_hill"
        if x > ridge + math.floor((rx - ridge) * 0.45) then c = "teal" end
      end
      K.px(x, y, c)
    end
  end

  -- Timbered subalpine ridge below Mount Hood
  for x = 0, W - 1 do
    local fh = 76 + math.floor(4 * math.sin(tau * x / 432.0 + 0.5) + 2 * math.cos(tau * x / 144.0))
    for y = fh, 98 do
      K.px(x, y, (y == fh) and "teal" or "pine")
    end
  end
end)

----------------------------------------------------------------- 2. Subalpine Meadow & Barlow Road Cut
K.layer("meadow_and_road", function()
  K.rect(0, 94, W, 12, "sage")
  K.dither(0, 102, W, 6, "sage", "grass")
  K.rect(0, 108, W, 42, "grass")
  K.dither(0, 140, W, 10, "grass", "pine")

  -- Rough Barlow Road climbing over the pass
  K.poly({{184, 96}, {204, 96}, {304, 150}, {234, 150}}, "ochre")
  K.poly({{190, 96}, {198, 96}, {288, 150}, {248, 150}}, "gold")
  K.line(188, 97, 244, 149, "rust")
  K.line(199, 97, 290, 149, "rust")

  for i = 1, 600 do
    local x = K.rnd(W)
    local y = 96 + K.rnd(54)
    local cur = K.at(x, y)
    if cur == "grass" or cur == "sage" then
      K.px(x, y, (i % 3 == 0) and "leaf" or ((i % 2 == 0) and "sage" or "gold"))
    end
  end
end)

----------------------------------------------------------------- 3. Old-Growth Cascade Douglas-Firs & Wagon
K.layer("firs_and_wagon", function()
  -- Tall Cascade Douglas-firs framing the left and right sides of the pass
  for _, tx in ipairs({18, 48, 82, 108, 336, 364, 392, 418}) do
    local th = (tx == 108 or tx == 336) and 44 or 58
    K.conifer(tx, 126 + (tx % 4), th, "ink", "pine", "leaf")
  end

  K.wagon(250, 145, -1)
  K.team(236, 144, -1, {"dark"}, {"light", true})
  K.person(306, 145, "blue", "wood", false)
end)

K.save("location_barlow_pass")
