-- Deer Creek (432x150).
-- Where Deer Creek comes into the North Platte there was the best camp of the upper river:
-- big cottonwoods, sweet grass, good water and coal in the bank. Emigrants laid by here to
-- rest the stock, wash and mend before the hard road to the upper crossing.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 184839)

K.layer("sky", function()
  K.sky(W, 74, {{120, 14, 1.0}, {340, 8, 0.7}}, "mist")
end)

K.layer("valley", function()
  -- Casper Mountain's long dark wall in the south, bare sage hills either side
  K.ridge(0, W - 1, 0, 90, function(x) return -(62 - 14 * math.exp(-((x - 220) / 120) ^ 2) + 2 * math.sin(x / 9)) end, "storm_lt", "mist", "storm")
  for i = 1, 200 do local x, y = 120 + K.rnd(200), 44 + K.rnd(30); if K.at(x, y) == "storm_lt" then K.px(x, y, "pine") end end
  K.ridge(0, W - 1, 0, 92, function(x) return -(70 + 4 * math.sin(x / 37) + 2 * math.sin(x / 13)) end, "clap_sh", "sand", "ochre")
  K.rect(0, 86, W, 8, "light_blue")
  K.rect(0, 86, W, 1, "sand"); K.rect(0, 93, W, 1, "sand")
  for i = 1, 60 do local x, y = K.rnd(W), 87 + K.rnd(6); K.rect(x, y, 2 + K.rnd(4), 1, (i % 3 == 0) and "white" or "sky") end
  K.rect(0, 94, W, H - 94, "grass")
  for i = 1, 1300 do K.px(K.rnd(W), 94 + K.rnd(H - 94), ({"leaf", "sage", "gold", "grass"})[i % 4 + 1]) end
  -- Deer Creek winding in from the left
  local creek = K.smooth({{-10, 140, 4}, {50, 128, 3}, {100, 116, 3}, {140, 104, 2}, {160, 94, 2}})
  K.ribbon(creek, "dirt_dk", 1)
  K.river(creek, false)
end)

K.layer("cottonwoods", function()
  -- big spreading cottonwoods along the river bank and the creek
  for _, t in ipairs({{22, 96, 1}, {40, 95, 0.8}, {90, 94, 1}, {196, 96, 1}, {212, 95, 0.7}, {318, 96, 1}, {336, 94, 0.8}, {400, 96, 1}}) do K.elm(t[1], t[2], t[3]) end
  for _, t in ipairs({{120, 118, 1}, {84, 132, 1}}) do K.elm(t[1], t[2], t[3]) end
  K.elm(16, 152, 2); K.elm(420, 156, 2)
  for _, w in ipairs({{150, 108, 1}, {64, 140, 1}, {170, 98, 1}}) do K.willow(w[1], w[2], w[3]) end
end)

K.layer("camp", function()
  -- a lay-by camp: wagons drawn up, tents, washing spread on the grass, stock grazing
  K.wagon(250, 124, 1); K.wagon(310, 128, -1)
  K.tent(206, 128, 12, 16); K.tent(356, 132, 12, 16)
  for i = 0, 3 do K.rect(220 + i * 9, 140, 6, 3, ({"white", "teal", "cream", "red"})[i + 1]); K.rect(220 + i * 9, 143, 6, 1, "leaf") end
  K.rect(282, 134, 1, 6, "wood"); K.rect(284, 134, 1, 6, "wood"); K.rect(281, 133, 5, 1, "deep"); K.ellipse(283, 140, 3, 1, "gold")
  K.px(283, 131, "storm_lt"); K.px(284, 128, "storm_lt")
  K.person(276, 142, "red", "bonnet", true); K.person(292, 142, "blue", "deep")
  K.person(246, 146, "teal", "bonnet", true)
  K.ox(120, 140, 1, "dark"); K.ox(160, 146, -1, "light"); K.ox(390, 140, -1, "red")
end)

K.save("location_deer_creek")
