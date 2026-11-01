-- Goose Lake (432x150).
-- A long shallow lake lying under the Warner Mountains, grey-blue and wind-ruffled, with good
-- grass and rushes along its south shore where the companies camp and graze their stock.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 185189)

K.layer("sky", function()
  K.sky(W, 66, {{120, 12, 0.9}, {300, 20, 0.6}, {400, 8, 0.5}}, "mist")
end)

K.layer("mountains", function()
  -- the Warners across the lake, timber dark on their flanks
  K.ridge(0, W - 1, 0, 92, function(x) return -(40 - 10 * math.abs(math.sin(x / 61 + 1)) - 5 * math.sin(x / 19) - 2 * math.sin(x / 6)) end, "haze", "far_hill", "teal")
  for i = 1, 500 do local x, y = K.rnd(W), 40 + K.rnd(40); if K.at(x, y) == "haze" and K.rnd(2) == 0 then K.px(x, y, (i % 3 == 0) and "pine" or "teal") end end
  K.ridge(0, W - 1, 0, 92, function(x) return -(70 - 4 * math.sin(x / 29)) end, "sage", "haze", "teal")
end)

K.layer("lake", function()
  K.rect(0, 74, W, 34, "sky_top")
  K.rect(0, 74, W, 2, "light_blue")
  for i = 1, 260 do K.rect(K.rnd(W), 76 + K.rnd(30), 2 + K.rnd(6), 1, (i % 3 == 0) and "light_blue" or ((i % 3 == 1) and "blue" or "sea")) end
  for x = 0, W - 1 do K.px(x, 107 + math.floor(math.sin(x / 9)), "sand") end
end)

K.layer("shore", function()
  K.rect(0, 108, W, H - 108, "grass")
  for i = 1, 1500 do K.px(K.rnd(W), 108 + K.rnd(H - 108), ({"leaf", "sage", "gold", "grass", "leaf"})[i % 5 + 1]) end
  -- rushes at the water's edge
  for x = 0, W - 1 do
    if math.sin(x / 13) + 0.6 * math.sin(x / 5.1) > 0.2 and K.rnd(2) == 0 then
      K.line(x, 110, x + K.rnd(3) - 1, 106 - K.rnd(6), ({"pine", "leaf", "sage"})[K.rnd(3) + 1])
    end
  end
  local road = K.smooth({{440, 120, 3}, {340, 126, 4}, {240, 136, 4}, {140, 140, 5}, {-10, 146, 5}})
  K.ribbon(road, "rust", 1); K.ribbon(road, "ochre", 0)
end)

K.layer("figures", function()
  K.wagon(170, 138, -1)
  K.team(156, 134, -1, {"red"}, {"dark"})
  K.tent(280, 126, 12, 16)
  K.person(300, 128, "brick", "hat"); K.person(262, 128, "teal", "bonnet", true)
  K.ox(360, 118, -1, "light"); K.ox(390, 130, 1, "dark"); K.ox(60, 120, 1, "red")
  K.rect(240, 122, 1, 4, "deep"); K.px(240, 120, "gold"); K.px(239, 119, "mist") -- cook fire
end)

K.save("location_goose_lake")
