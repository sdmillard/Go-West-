-- White River crossing on the Barlow road (432x150).
-- Below Mount Hood the White River spreads over a wide bed of boulders and grey sand. The
-- water is milky with glacier flour, so the bottom cannot be seen, and its channels shift.
-- Fir and ponderosa pine stand on the terraces; the snow cone of the mountain fills the west.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 185349)

K.layer("sky", function()
  K.sky(W, 76, {{60, 22, 0.7}, {360, 12, 0.9}}, "mist")
end)

K.layer("mountain", function()
  -- Mount Hood: a sharp snow cone with glacier tongues, dark ridges at its foot
  K.peaks(110, 330, 86, 92, function(x) local d = math.abs(x - 214) / 104; return math.max(0, 74 * (1 - d) ^ 1.25 + 2 * math.sin(x / 5)) end, 44)
  K.ridge(0, W - 1, 0, 96, function(x) return -(72 - 7 * math.sin(x / 37 + 1) - 3 * math.sin(x / 13)) end, "teal", "haze", "teal")
  for i = 1, 900 do local x, y = K.rnd(W), 62 + K.rnd(34); if K.at(x, y) == "teal" then K.px(x, y, ({"pine", "ink", "teal", "pine"})[i % 4 + 1]) end end
end)

K.layer("bed", function()
  -- terraces of grass and needles above a broad bar of boulders and sand
  K.rect(0, 92, W, H - 92, "grass")
  for i = 1, 900 do K.px(K.rnd(W), 92 + K.rnd(H - 92), ({"grass", "leaf", "sage", "silt"})[i % 4 + 1]) end
  local bed = K.smooth({{-10, 112, 16}, {110, 116, 22}, {220, 118, 24}, {330, 114, 22}, {440, 108, 18}})
  K.ribbon(bed, "stone", 0)
  for i = 1, 1400 do
    local q = bed[1 + K.rnd(#bed)]
    local x, y = math.floor(q[1] + K.rnd(math.floor(q[3] * 2)) - q[3]), math.floor(q[2] + K.rnd(math.floor(q[3] * 1.2)) - q[3] * 0.6)
    if K.at(x, y) == "stone" then K.px(x, y, ({"stone_lt", "stone_dk", "sand", "stone", "clap_sh"})[i % 5 + 1]) end
  end
  -- braided milky channels
  for _, c in ipairs({{{-10, 108, 3}, {90, 112, 4}, {200, 110, 4}, {300, 106, 3}, {440, 102, 3}},
                      {{-10, 118, 4}, {120, 122, 5}, {230, 124, 5}, {340, 118, 4}, {440, 112, 3}},
                      {{150, 116, 2}, {200, 120, 2}, {260, 117, 2}}}) do
    local ch = K.smooth(c)
    K.ribbon(ch, "far_hill", 1); K.ribbon(ch, "haze", 0)
    for i = 1, #ch, 3 do if K.rnd(2) == 0 then K.rect(math.floor(ch[i][1]), math.floor(ch[i][2]), 2 + K.rnd(3), 1, "mist") end end
  end
  for i = 1, 30 do
    local q = bed[1 + K.rnd(#bed)]
    local x, y, r = math.floor(q[1] + K.rnd(30) - 15), math.floor(q[2] + K.rnd(14) - 7), 2 + K.rnd(2)
    K.ellipse(x, y, r, r - 1, "stone_ink"); K.ellipse(x - 1, y - 1, r - 1, math.max(1, r - 2), "stone_dk"); K.px(x - r + 1, y - 1, "stone_lt"); K.px(x - r + 2, y - 2, "stone")
  end
  local road = K.smooth({{300, 152, 6}, {280, 138, 4}, {262, 128, 3}})
  K.ribbon(road, "dirt_dk", 1); K.ribbon(road, "silt", 0)
end)

K.layer("trees", function()
  for _, t in ipairs({{14, 100, 30}, {40, 98, 24}, {360, 98, 28}, {392, 100, 34}, {420, 96, 26}, {80, 96, 20}}) do K.conifer(t[1], t[2], t[3], "ink", "pine", "leaf") end
  for _, t in ipairs({{20, 150, 44}, {404, 150, 46}, {378, 146, 32}}) do K.conifer(t[1], t[2], t[3], "ink", "pine", "teal") end
end)

K.layer("figures", function()
  K.wagon(214, 126, -1)
  K.team(188, 121, -1, {"dark"}, {"red"})
  K.wade(160, 262, 124, 3, "haze", "mist")
  K.person(270, 132, "blue", "hat"); K.line(266, 126, 262, 136, "wood") -- sounding the channel with a pole
  K.wagon(268, 148, -1)
  K.team(242, 144, -1, {"light", true}, {"dark"})
end)

K.save("location_white_river")
