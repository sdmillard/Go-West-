-- Burnt River Canyon (432x150).
-- Historical reference: Joel Palmer's 1845 journal & WESTERN_REFERENCES.md.
-- Steep, narrow rust-and-dark-basalt canyon walls closing in around the twisting rocky
-- Burnt River stream, where wagons had to cross and recross the creek bed.
local K = dofile(app.params.kit)
local W, H = 432, 150

K.canvas(W, H, 184823)

----------------------------------------------------------------- 1. Sky & Distant Canyon Ridge
K.layer("sky", function()
  K.rect(0, 0, W, 16, "sky_top")
  K.blend(0, 16, W, "sky_top", "sky")
  K.rect(0, 19, W, 18, "sky")
  K.blend(0, 37, W, "sky", "light_blue")
  K.rect(0, 40, W, 16, "light_blue")
  K.blend(0, 56, W, "light_blue", "sand")
  K.rect(0, 59, W, 24, "sand")

  K.cloud(44, 16, 1.35)
  K.cloud(300, 14, 1.4)

  -- Distant arid ridge seen through the V-shaped Burnt River gorge
  K.poly({{96, 80}, {198, 56}, {326, 78}, {326, 98}, {96, 98}}, "ochre")
  K.poly({{120, 82}, {204, 62}, {308, 82}, {308, 98}, {120, 98}}, "rust")
end)

----------------------------------------------------------------- 2. Canyon Floor, Twisting Burnt River & Trail
K.layer("canyon_floor", function()
  K.rect(0, 80, W, 70, "sand")
  K.dither(110, 80, 210, 6, "ochre", "sand")

  -- Narrow rocky wagon trace winding beside the stream
  K.poly({{168, 84}, {184, 84}, {208, 150}, {162, 150}}, "ochre")
  K.poly({{172, 84}, {180, 84}, {200, 150}, {170, 150}}, "gold")
  K.line(170, 85, 168, 149, "rust")
  K.line(181, 85, 202, 149, "rust")

  -- Twisting rocky Burnt River stream bed
  K.poly({{184, 82}, {208, 79}, {246, 150}, {206, 150}}, "blue")
  K.poly({{187, 82}, {205, 79}, {242, 150}, {210, 150}}, "sky_top")
  K.poly({{190, 82}, {201, 79}, {236, 150}, {215, 150}}, "sky")
  for y = 84, 148, 3 do
    local t = (y - 82) / 68.0
    local cx = math.floor(194 + t * 28)
    K.rect(cx - 2 + (y % 3), y, 4, 1, (y % 6 == 0) and "white" or "light_blue")
  end
end)

----------------------------------------------------------------- 3. Steep Rust & Dark-Wood Basalt Canyon Walls
K.layer("canyon_walls", function()
  -- Left canyon wall (sunlit upper-left rust/ochre volcanic talus & ledges)
  for y = 42, 149 do
    local t = (y - 42) / 107.0
    local rx
    if y <= 86 then
      rx = math.floor((y - 42) * 123 / 44.0 + 4 * math.sin(y * 0.22))
    else
      rx = math.floor(123 + (y - 86) * 57 / 63.0 + 4 * math.sin(y * 0.18))
    end
    for x = 0, rx do
      local c = "rust"
      if x >= rx - 3 then
        c = "ochre"
      elseif y % 7 == 0 then
        c = "ochre"
      elseif y % 7 == 3 then
        c = "wood"
      elseif (x + y * 2) % 11 == 0 then
        c = "sand"
      end
      K.px(x, y, c)
    end
  end

  -- Right canyon wall (steep shaded dark basalt/wood & rust cliff slopes)
  for y = 34, 149 do
    local t = (y - 34) / 115.0
    local lx
    if y <= 73 then
      lx = math.floor(432 - (y - 34) * 112 / 39.0 + 4 * math.cos(y * 0.24))
    else
      lx = math.floor(320 - (y - 73) * 70 / 76.0 + 4 * math.cos(y * 0.19))
    end
    for x = lx, W - 1 do
      local c = "wood"
      if x <= lx + 3 then
        c = "rust"
      elseif y % 7 == 0 then
        c = "rust"
      elseif y % 7 == 4 then
        c = "deep"
      elseif (x - y * 2) % 13 == 0 then
        c = "deep"
      end
      K.px(x, y, c)
    end
  end

  -- Canyon boulders & burnt/charred deadwood stumps along the rocky creek margins
  for _, bx in ipairs({152, 182, 248, 272}) do
    K.boulder(bx, 118 + (bx % 22), 5, 2)
  end
  K.line(144, 108, 147, 98, "deep")
  K.line(146, 102, 151, 99, "deep")
  K.line(266, 114, 263, 103, "deep")

  -- Arriving wagon at the mouth of the gorge
  K.wagon(24, 143, 1)
  K.person(84, 142, "blue", "wood", false)
end)

K.save("location_burnt_river")
