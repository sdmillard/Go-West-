-- Snake River, Three Island Crossing (432x150).
-- Here the Snake is broad and split by gravel islands into channels; the last channel is deep
-- and swift. Emigrants raised wagon beds on blocks, chained wagons together for weight, and
-- drove the oxen across, swimming in the deep water. The north shore beyond is open sage plain.
local K = dofile(app.params.kit)
local W, H = 432, 150
local N, S = 92, 132 -- far and near shore lines

K.canvas(W, H, 184832)

K.layer("sky", function()
  K.sky(W, 72, {{180, 8, 0.9}, {372, 20, 0.7}, {20, 26, 0.5}}, "mist")
end)

K.layer("north shore", function()
  -- distant mountains and the sage plain on the north bank
  K.ridge(0, W - 1, 0, N, function(x) return -(56 + 8 * math.sin(x / 61 + 1) + 3 * math.sin(x / 17)) end, "far_hill", "mist", "haze")
  K.ridge(0, W - 1, 0, N, function(x) return -(78 + 2 * math.sin(x / 29)) end, "clap_sh", "sand", "ochre")
  K.rect(0, 84, W, N - 84, "clap_sh")
  for i = 1, 500 do
    local x, y = K.rnd(W), 80 + K.rnd(N - 80)
    if K.at(x, y) == "clap_sh" then K.px(x, y, ({"sage", "ochre", "teal"})[i % 3 + 1]) end
  end
  -- low basalt rim along the far bank
  for x = 0, W - 1 do
    local h = 2 + math.floor(math.max(0, 2 * math.sin(x / 19)))
    for y = N - h, N do K.px(x, y, ((x % 4) == 0) and "roof_dk" or "roof") end
    K.px(x, N - h, "roof_lt")
  end
end)

K.layer("river", function()
  K.rect(0, N + 1, W, S - N + 4, "blue")
  for y = N + 1, S + 4 do
    for x = 0, W - 1 do
      if (y < N + 4 and (x + y) % 2 == 0) or ((x * 5 + y * 11) % 19 == 0) then K.px(x, y, "sky_top") end
    end
  end
  -- current lines, heavier in the deep north channel
  for i = 1, 260 do
    local x, y = K.rnd(W), N + 2 + K.rnd(S - N)
    local deep = y < N + 12
    K.rect(x, y, deep and (4 + K.rnd(5)) or (2 + K.rnd(3)), 1, (deep and K.rnd(3) == 0) and "white" or "light_blue")
  end
  -- the three islands: gravel with willows and grass
  for _, isl in ipairs({{70, 110, 44, 4}, {210, 106, 54, 4}, {356, 112, 40, 3}}) do
    local x, y, w, h = isl[1], isl[2], isl[3], isl[4]
    K.ellipse(x, y + 1, w + 2, h + 1, "light_blue")
    K.ellipse(x, y, w, h, "clap_sh")
    K.ellipse(x - 2, y - 1, w - 6, math.max(1, h - 1), "sage")
    K.ellipse(x - 4, y - 1, w - 16, math.max(1, h - 2), "grass")
    for i = 1, math.floor(w / 6) do K.willow(x - w + 8 + K.rnd(w * 2 - 16), y, 1) end
    K.rect(x - w - 6, y + 1, 8, 1, "white"); K.rect(x + w, y + 2, 10, 1, "white")
  end
end)

K.layer("south shore", function()
  -- the near bank: a gravel landing under a low cut bank of brown soil
  K.poly({{0, S}, {120, S - 2}, {260, S + 2}, {431, S - 1}, {431, 150}, {0, 150}}, "ochre")
  K.poly({{0, S}, {120, S - 2}, {260, S + 2}, {431, S - 1}, {431, S + 3}, {260, S + 6}, {120, S + 2}, {0, S + 4}}, "clap_sh")
  for i = 1, 600 do
    local x, y = K.rnd(W), S - 3 + K.rnd(22)
    local c = K.at(x, y)
    if c == "ochre" then K.px(x, y, ({"gold", "rust", "sand"})[i % 3 + 1])
    elseif c == "clap_sh" then K.px(x, y, (i % 2 == 0) and "stone" or "stone_dk") end
  end
  for i = 1, 22 do
    local x, y = K.rnd(W), S + 6 + K.rnd(12)
    if K.at(x, y) == "ochre" or K.at(x, y) == "gold" or K.at(x, y) == "rust" then K.sage(x, y) end
  end
end)

K.layer("figures", function()
  -- the crossing: wagons chained together on the middle island, one in the deep channel
  -- with the water up to its bed, the oxen swimming ahead with only heads and backs showing
  K.far_wagon(200, 108, 1)
  K.far_wagon(222, 108, 1)
  K.far_wagon(272, 101, 1)
  K.wade(270, 290, 101, 5)
  for i = 0, 2 do
    local x = 296 + i * 10
    K.rect(x, 96, 7, 2, "ox_dk"); K.px(x + 7, 95, "ox_dk"); K.px(x + 8, 95, "ox_lt")
    K.rect(x - 2, 98, 12, 1, "light_blue"); K.px(x + 9, 97, "white")
  end
  -- a drover swimming beside the lead yoke, small with distance
  K.px(328, 96, "skin"); K.px(328, 97, "red"); K.rect(326, 98, 5, 1, "light_blue")
  -- on the near bank a family blocks up the wagon bed, oxen waiting
  K.wagon(110, 146, 1)
  K.rect(112, 136, 4, 2, "wood"); K.rect(148, 136, 4, 2, "wood")
  K.team(166, 145, 1, {"red"}, {"light", true})
  K.person(102, 146, "blue", "roof")
  K.person(92, 147, "teal", "bonnet", true)
  K.barrel(70, 146); K.crate(78, 147)
  K.ox(230, 146, -1, "dark")
end)

K.save("location_snake_river")
