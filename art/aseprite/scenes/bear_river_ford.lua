-- Bear River crossing on Hensley's Salt Lake cutoff (432x150).
-- North of the Weber the cutoff strikes the Bear above its marshy mouth on the Great Salt
-- Lake: a deep, slow, olive river between cut mud banks, tules and bulrush along the
-- sloughs, salt grass and sage on the flats, and the bare Wellsville and Promontory ranges
-- across the valley. No ferry yet: companies caulk the wagon beds and float them over.
-- Shoshone lodges of willow and tule stand on the bottoms.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 185337)

local river = {{-10, 104, 9}, {90, 110, 10}, {190, 114, 11}, {290, 110, 10}, {370, 104, 9}, {440, 100, 8}}

K.layer("sky", function()
  K.sky(W, 70, {{120, 12, 0.8}, {340, 20, 0.6}}, "mist")
end)

K.layer("hills", function()
  -- Wellsville range to the north-east, Promontory low in the west, salt haze between
  K.ridge(0, W - 1, 0, 88, function(x) local d = (x - 320) / 70; return -(66 - 20 * math.exp(-d * d) - 3 * math.sin(x / 11)) end, "far_hill", "mist", "haze")
  K.ridge(0, 180, 0, 88, function(x) return -(74 - 6 * math.sin(x / 23 + 1)) end, "haze", "far_hill", "teal")
  K.rect(0, 84, W, 4, "mist")
end)

K.layer("flats", function()
  K.rect(0, 86, W, H - 86, "silt_lt")
  for i = 1, 1300 do K.px(K.rnd(W), 86 + K.rnd(H - 86), ({"sage", "silt_lt", "clap_sh", "gold", "sage", "grass"})[i % 6 + 1]) end
  local water = K.smooth(river)
  -- cut mud banks, then dark slow water with only a few glints
  K.ribbon(water, "silt_dk", 3); K.ribbon(water, "silt", 2)
  K.ribbon(water, "teal", 0)
  local inner = {}
  for i, q in ipairs(water) do inner[i] = {q[1], q[2], q[3] * 0.55} end
  K.ribbon(inner, "blue", 0)
  for i = 1, 60 do local q = water[1 + K.rnd(#water)]; K.rect(math.floor(q[1] + K.rnd(9) - 4), math.floor(q[2] + K.rnd(5) - 2), 2 + K.rnd(3), 1, "haze") end
  local road = K.smooth({{214, 152, 6}, {226, 138, 4}, {222, 126, 3}})
  K.ribbon(road, "dirt_dk", 1); K.ribbon(road, "ochre", 0)
end)

K.layer("tules", function()
  -- tule and bulrush clumps along the sloughs and the near bank
  for i = 1, 70 do
    local x = K.rnd(W)
    local y = (i % 2 == 0) and (98 + K.rnd(4)) or (126 + K.rnd(6))
    for k = 0, 3 do K.line(x + k, y, x + k + (k % 2), y - 4 - K.rnd(4), (k % 2 == 0) and "grass" or "sage") end
    if K.rnd(3) == 0 then K.px(x + 1, y - 7, "wood") end
  end
  for _, s in ipairs({{40, 140}, {120, 146}, {330, 142}, {400, 136}, {300, 96}, {60, 94}}) do K.sage(s[1], s[2]) end
  -- Shoshone lodges of willow poles and tule mats
  for _, l in ipairs({{372, 92}, {392, 94}}) do
    K.ellipse(l[1], l[2] - 3, 6, 4, "silt"); K.ellipse(l[1] - 1, l[2] - 4, 4, 3, "clap_sh"); K.rect(l[1] - 6, l[2] - 1, 13, 2, "silt"); K.rect(l[1] - 1, l[2] - 3, 2, 3, "deep")
  end
end)

K.layer("figures", function()
  -- a caulked wagon bed afloat, men on lines from both banks; the running gear waits
  local y = 112
  K.poly({{170, y - 6}, {216, y - 6}, {213, y}, {173, y}}, "blue"); K.rect(170, y - 6, 46, 1, "light_blue"); K.rect(172, y - 3, 42, 1, "teal")
  K.rect(176, y - 11, 8, 5, "ochre"); K.rect(190, y - 10, 10, 4, "cream"); K.barrel(202, y - 6)
  K.rect(168, y + 1, 50, 1, "haze")
  K.line(216, y - 4, 260, y - 14, "sand"); K.person(262, 99, "brick", "hat")
  K.line(170, y - 4, 140, y + 16, "sand"); K.person(136, 130, "blue", "hat")
  K.wagon(236, 146, 1)
  K.team(286, 142, 1, {"dark"}, {"red"})
  K.ox(330, 132, -1, "light"); K.ox(80, 132, 1, "dark")
end)

K.save("location_bear_river_ford")
