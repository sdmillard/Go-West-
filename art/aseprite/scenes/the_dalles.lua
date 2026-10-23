-- The Dalles of the Columbia (432x150).
-- Here the Columbia narrows and pours over low black basalt reefs and islands. In 1848 the
-- old Wascopam mission house still stood on the rise above the landing, and emigrants camped
-- on the bottom to build log rafts for the float down the river, or turned south for the
-- Barlow Road around Mount Hood, whose snow cone shows far to the southwest.
local K = dofile(app.params.kit)
local W, H = 432, 150

K.canvas(W, H, 184830)

K.layer("sky", function()
  K.sky(W, 74, {{150, 14, 0.9}, {310, 6, 0.6}, {388, 24, 0.8}}, "mist")
end)

K.layer("mount hood", function()
  -- a broad snow cone far off, lit on its left flank
  local cx, top = 70, 40
  for x = cx - 56, cx + 56 do
    local d = math.abs(x - cx)
    local y0 = math.floor(top + d * 0.55 + 0.003 * d * d + 1.5 * math.sin(x / 5) * math.min(1, d / 16))
    for y = y0, 80 do
      local snow = y < top + 12 + 4 * math.sin(x / 4)
      local c
      if snow then c = (x < cx + 2) and "white" or "light_blue"
      else c = (x < cx) and "mist" or "far_hill" end
      if snow and x >= cx + 2 and (x + y) % 5 == 0 then c = "mist" end
      K.px(x, y, c)
    end
  end
  for i = 0, 3 do K.line(cx - 3 - i * 3, top + 8 + i * 2, cx - 5 - i * 3, top + 14 + i * 2, "mist") end
end)

K.layer("bluffs", function()
  -- the Washington shore: long basalt bluffs stepped in flows, dry grass on the benches
  local far = function(x) return -(70 + 3 * math.sin(x / 41) + 2 * math.sin(x / 13)) end
  K.ridge(0, W - 1, 0, 92, far, "far_hill", "mist", "haze")
  local bluff = function(x) return 10 + 14 * math.max(0, math.sin(x / 60 + 1)) + 3 * math.sin(x / 17) end
  K.ridge(0, W - 1, 92, 94, bluff, "ochre", "sand", "rust")
  -- basalt flows lie flat: dark rimrock bands at fixed heights wherever the bluff reaches them,
  -- grassy talus benches between
  for x = 0, W - 1 do
    local top = math.floor(92 - bluff(x) + 0.5)
    for _, f in ipairs({{70, 4}, {80, 3}}) do
      local y0 = f[1] + math.floor(math.sin(x / 70) * 2)
      if y0 > top then
        for y = y0, y0 + f[2] - 1 do K.px(x, y, ((x * 3 + y) % 7 == 0) and "roof_dk" or "roof") end
        K.px(x, y0, "roof_lt"); K.px(x, y0 + f[2], "deep")
      elseif y0 + f[2] > top then
        for y = top, y0 + f[2] - 1 do K.px(x, y, "roof") end
        K.px(x, top, "roof_lt")
      end
    end
    if K.rnd(4) == 0 then K.px(x, top + 3 + K.rnd(math.max(1, 90 - top)), "sage") end
  end
end)

K.layer("river", function()
  K.rect(0, 92, W, 46, "blue")
  for y = 92, 137 do
    for x = 0, W - 1 do
      if (y < 97 and (x + y) % 2 == 0) or ((x * 7 + y * 13) % 23 == 0) then K.px(x, y, "sky_top") end
    end
  end
  K.rect(0, 92, W, 1, "light_blue")
  -- low black reefs and islands across the channel, white water piling on their upstream ends
  -- low black reefs and islands across the channel, white water piling against them
  local reefs = {{30, 104, 22}, {100, 98, 12}, {150, 112, 28}, {226, 101, 16}, {290, 116, 24}, {356, 106, 30}, {404, 97, 10}}
  for _, r in ipairs(reefs) do
    local x, y, w = r[1], r[2], r[3]
    local i = -w
    while i < w do
      local rw = 3 + K.rnd(4)
      local rh = 2 + ((math.abs(i) < w / 2) and 1 or 0)
      K.ellipse(x + i, y, rw, rh, "ink")
      K.ellipse(x + i - 1, y - 1, rw - 1, rh - 1, "roof")
      K.rect(x + i - rw + 1, y - rh, math.max(1, rw - 1), 1, "stone_dk")
      i = i + rw + 1 + K.rnd(4)
    end
    for j = -w - 2, w + 2 do if K.rnd(2) == 0 then K.px(x + j, y + 3, "white") end end
    K.rect(x - w - 10, y + 1, 7, 1, "white")
    K.rect(x + w + 2, y + 2, 10, 1, "light_blue")
  end
  for i = 1, 220 do
    local x, y = K.rnd(W), 95 + K.rnd(28)
    if K.at(x, y) == "blue" then K.rect(x, y, 2 + K.rnd(3), 1, (K.rnd(4) == 0) and "white" or "light_blue") end
  end
end)

K.layer("landing", function()
  -- Oregon shore: dry bottom rising to the right, gravel at the water
  K.poly({{0, 136}, {150, 134}, {210, 128}, {280, 124}, {431, 118}, {431, 150}, {0, 150}}, "ochre")
  K.poly({{0, 136}, {150, 134}, {210, 128}, {280, 124}, {431, 118}, {431, 121}, {280, 127}, {210, 131}, {150, 137}, {0, 139}}, "clap_sh")
  K.ridge(300, W - 1, 122, 126, function(x) return 16 * ((x - 300) / 132) ^ 0.7 end, "ochre", "gold", "rust")
  for i = 1, 900 do
    local x, y = K.rnd(W), 106 + K.rnd(44)
    local c = K.at(x, y)
    if c == "ochre" then K.px(x, y, ({"gold", "rust", "sand"})[i % 3 + 1])
    elseif c == "clap_sh" then K.px(x, y, (i % 2 == 0) and "stone" or "stone_dk") end
  end
  for i = 1, 26 do
    local x, y = K.rnd(W), 128 + K.rnd(22)
    if K.at(x, y) == "ochre" or K.at(x, y) == "gold" or K.at(x, y) == "rust" then K.sage(x, y) end
  end
  -- trail coming in from the right toward the landing
  local trail = K.smooth({{440, 140, 6}, {360, 138, 5}, {290, 134, 4}, {240, 130, 3}})
  K.ribbon(trail, "rust", 1); K.ribbon(trail, "sand", 0)
end)

K.layer("mission", function()
  -- the old mission house on the rise: squared logs, shake roof, stone chimney
  local x, y = 362, 112
  K.side_wall(x + 34, y - 14, 8, 14, "wood", "deep")
  K.rect(x, y - 14, 34, 14, "rust")
  for yy = y - 13, y - 1, 3 do K.rect(x, yy, 34, 1, "wood") end
  K.rect(x, y - 14, 34, 1, "ochre")
  K.poly({{x - 2, y - 14}, {x + 17, y - 24}, {x + 36, y - 14}}, "roof")
  K.poly({{x + 17, y - 24}, {x + 44, y - 20}, {x + 44, y - 12}, {x + 36, y - 14}}, "roof_dk")
  K.line(x - 2, y - 14, x + 17, y - 24, "roof_lt")
  K.rect(x + 4, y - 9, 5, 9, "deep"); K.px(x + 7, y - 5, "gold")
  K.rect(x + 14, y - 10, 5, 4, "ink"); K.rect(x + 15, y - 9, 3, 2, "light_blue")
  K.rect(x + 24, y - 10, 5, 4, "ink"); K.rect(x + 25, y - 9, 3, 2, "light_blue")
  K.rect(x + 28, y - 28, 4, 8, "stone_dk"); K.rect(x + 28, y - 28, 2, 8, "stone")
  K.shadow(x, y + 1, 46)
  -- split-rail fence down the slope
  for i = 0, 6 do
    local fx = x - 10 - i * 9
    K.rect(fx, y + 2 + i, 1, 5, "deep")
    K.line(fx, y + 3 + i, fx + 9, y + 2 + i, "wood"); K.line(fx, y + 5 + i, fx + 9, y + 4 + i, "wood")
  end
end)

K.layer("figures", function()
  -- a raft of lashed logs at the landing with a wagon box and bonnet already aboard
  local rx, ry = 84, 131
  for i = 0, 6 do
    K.rect(rx, ry + i * 2 - 7, 70, 2, (i % 2 == 0) and "wood" or "rust")
    K.px(rx, ry + i * 2 - 7, "ochre"); K.px(rx + 69, ry + i * 2 - 7, "deep")
  end
  K.rect(rx + 4, ry - 8, 62, 1, "deep")
  K.rect(rx - 2, ry + 7, 74, 1, "light_blue")
  -- wagon bed and bonnet off their wheels
  K.rect(rx + 12, ry - 16, 34, 8, "blue"); K.rect(rx + 12, ry - 16, 34, 1, "light_blue")
  K.poly({{rx + 13, ry - 16}, {rx + 11, ry - 25}, {rx + 16, ry - 29}, {rx + 42, ry - 29}, {rx + 47, ry - 25}, {rx + 45, ry - 16}}, "cream")
  K.poly({{rx + 42, ry - 29}, {rx + 47, ry - 25}, {rx + 45, ry - 16}, {rx + 40, ry - 16}, {rx + 42, ry - 25}}, "clap_sh")
  K.wheel(rx + 56, ry - 13, 6)
  K.barrel(rx + 4, ry - 8)
  K.crate(rx + 58, ry - 8)
  -- steering sweep at the stern
  K.line(rx + 70, ry - 8, rx + 84, ry - 2, "deep")
  -- men rolling the last logs down to the water, a woman with a bundle
  K.person(196, 134, "red", "deep")
  K.person(210, 135, "blue", "roof")
  for i = 0, 1 do K.rect(186 + i * 4, 137 + i, 28, 2, "wood"); K.px(186 + i * 4, 137 + i, "ochre") end
  K.person(232, 131, "teal", "bonnet", true)
  -- wedge tents of the camp
  K.tent(286, 126, 10, 14)
  K.tent(318, 128, 12, 16)
  -- the oxen, turned out to graze for the Barlow Road crowd
  K.ox(120, 148, 1, "light", true)
  K.ox(266, 146, -1, "red")
end)

K.save("location_the_dalles")
