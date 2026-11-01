-- The Umpqua valley (432x150).
-- Below the canyon the country opens into round oak hills and grassy bottoms along the South
-- Umpqua, fir timber on the ridges. Umpqua people come to trade salmon and camas; the road is
-- easier from here, with the Calapooya hills ahead.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 185263)

K.layer("sky", function()
  K.sky(W, 74, {{40, 14, 0.7}, {200, 8, 1.0}, {350, 18, 0.8}}, "mist")
end)

K.layer("hills", function()
  -- far fir ridges, then round grassy hills dotted with oaks
  K.ridge(0, W - 1, 0, 88, function(x) return -(54 - 6 * math.sin(x / 37) - 3 * math.sin(x / 13 + 1)) end, "teal", "haze", "pine")
  for i = 1, 700 do local x, y = K.rnd(W), 46 + K.rnd(40); if K.at(x, y) == "teal" then K.px(x, y, ({"pine", "leaf", "teal"})[i % 3 + 1]) end end
  K.ridge(0, W - 1, 0, 96, function(x) return -(80 - 12 * math.abs(math.sin(x / 41 + 0.5)) - 4 * math.abs(math.sin(x / 17))) end, "sage", "gold", "grass")
  for i = 1, 900 do local x, y = K.rnd(W), 64 + K.rnd(32); if K.at(x, y) == "sage" then K.px(x, y, ({"gold", "grass", "silt_lt", "sage"})[i % 4 + 1]) end end
  -- oaks scattered over the hills, thick in the draws and thin on the crests
  for i = 1, 16 do
    local x = K.rnd(W)
    local top = math.floor(80 - 12 * math.abs(math.sin(x / 41 + 0.5)) - 4 * math.abs(math.sin(x / 17)))
    K.elm(x, top + 6 + K.rnd(12), 1)
  end
end)

K.layer("bottom", function()
  K.rect(0, 94, W, H - 94, "grass")
  for i = 1, 1600 do K.px(K.rnd(W), 94 + K.rnd(H - 94), ({"sage", "gold", "leaf", "grass", "sage"})[i % 5 + 1]) end
  local water = K.smooth({{440, 104, 5}, {360, 110, 6}, {280, 106, 6}, {200, 112, 7}, {120, 108, 7}, {-10, 116, 8}})
  K.ribbon(water, "leaf", 2); K.river(water, "silt_lt")
  local road = K.smooth({{440, 126, 4}, {340, 132, 4}, {240, 138, 5}, {140, 140, 5}, {-10, 146, 6}})
  K.ribbon(road, "rust", 1); K.ribbon(road, "ochre", 0)
end)

K.layer("trees", function()
  for _, o in ipairs({{40, 124, 2}, {384, 138, 2}, {300, 122, 1}}) do K.elm(o[1], o[2], o[3]) end
  for _, w in ipairs({{80, 104, 1}, {170, 106, 1}, {250, 102, 1}, {330, 104, 1}}) do K.willow(w[1], w[2], w[3]) end
end)

K.layer("figures", function()
  K.wagon(200, 138, -1)
  K.team(186, 134, -1, {"dark"}, {"light", true})
  -- Umpqua traders with salmon and baskets of camas
  K.person(258, 140, "rust", nil); K.rect(262, 134, 6, 2, "brick_lt"); K.px(268, 134, "red")
  K.person(270, 142, "ochre", nil, true); K.rect(266, 136, 4, 3, "gold")
  K.person(246, 140, "blue", "hat")
  -- a dugout canoe drawn up on the bank
  K.rect(110, 114, 20, 2, "wood"); K.rect(111, 116, 18, 1, "deep")
end)

K.save("location_umpqua_valley")
