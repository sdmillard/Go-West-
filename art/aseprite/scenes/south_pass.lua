-- South Pass (432x150).
-- The Continental Divide here is a broad sage saddle, so gentle that diarists were surprised to
-- learn they had crossed it. The snowy Wind River Range stands to the north and the Oregon
-- Buttes to the southwest. A wagon train strings out small along the road; Pacific Springs
-- shows as a green marsh just west of the summit.
local K = dofile(app.params.kit)
local W, H = 432, 150

K.canvas(W, H, 184833)

K.layer("sky", function()
  K.sky(W, 98, {{40, 10, 0.9}, {214, 20, 0.6}}, "mist")
end)

K.layer("ranges", function()
  -- Wind River Range to the north (right), with snow on the high peaks
  local tops = {{236, 26}, {262, 34}, {290, 30}, {318, 44}, {344, 40}, {372, 52}, {398, 46}, {424, 50}}
  local wind = function(x)
    local h = 8 * math.max(0, math.min(1, (x - 190) / 60))
    for _, p in ipairs(tops) do h = math.max(h, p[2] - math.abs(x - p[1]) * 0.9) end
    return h
  end
  K.peaks(190, W - 1, 96, 98, wind, 28)
  -- Oregon Buttes far to the southwest: flat-topped and blue
  K.ridge(10, 110, 0, 96, function(x)
    local d = math.abs(x - 60) / 50
    return -(96 - ((d < 0.55) and 22 or 22 * (1 - (d - 0.55) / 0.45)))
  end, "far_hill", "mist", "haze")
end)

K.layer("saddle", function()
  -- the long sage swell of the divide
  local swell = function(x) return 92 - 6 * math.exp(-((x - 230) / 120) ^ 2) + 2 * math.sin(x / 31) end
  for x = 0, W - 1 do
    local top = math.floor(swell(x) + 0.5)
    for y = top, H - 1 do K.px(x, y, "clap_sh") end
    K.px(x, top, "sand")
  end
  for i = 1, 2400 do
    local x, y = K.rnd(W), 86 + K.rnd(64)
    if K.at(x, y) == "clap_sh" then
      local near = (y - 86) / 64
      K.px(x, y, ({"sage", "teal", "ochre", "haze", "clap_sh"})[i % 5 + 1])
      if near > 0.5 and i % 3 == 0 then K.px(x, y - 1, "haze") end
    end
  end
  -- Pacific Springs marsh
  K.ellipse(110, 104, 30, 3, "grass"); K.ellipse(108, 103, 22, 2, "sage")
  for i = 0, 6 do K.px(92 + i * 5, 104, "light_blue") end
  -- the road over the summit, worn into several parallel ruts
  local road = K.smooth({{440, 150, 9}, {360, 132, 6}, {290, 112, 4}, {230, 100, 2}, {160, 98, 2}, {100, 102, 1}, {-6, 104, 1}})
  K.ribbon(road, "ochre", 1); K.ribbon(road, "sand", 0)
  for i = 1, #road - 1, 2 do K.px(math.floor(road[i][1]), math.floor(road[i][2]), "dirt_dk") end
  for i = 1, 26 do
    local x, y = K.rnd(W), 116 + K.rnd(34)
    if K.at(x, y) ~= "sand" and K.at(x, y) ~= "ochre" then K.sage(x, y) end
  end
end)

K.layer("figures", function()
  -- the train strung out over the summit, smaller with distance
  for _, w in ipairs({{196, 100}, {218, 101}, {240, 102}, {262, 106}}) do K.far_wagon(w[1], w[2], -1) end
  for _, w in ipairs({{138, 99}, {160, 99}}) do
    K.rect(w[1], w[2] - 5, 6, 3, "cream"); K.rect(w[1], w[2] - 2, 6, 1, "blue"); K.rect(w[1] - 5, w[2] - 3, 4, 2, "ox_dk")
  end
  -- near the viewer, the last wagon and a man walking beside the team
  K.wagon(340, 136, -1)
  K.team(330, 132, -1, {"red"}, {"light", true})
  K.person(316, 140, "blue", "deep")
  K.person(392, 142, "teal", "bonnet", true)
end)

K.save("location_south_pass")
