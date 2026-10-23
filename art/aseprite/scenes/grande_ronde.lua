-- Grande Ronde Valley (432x150), from the long steep hill where the road came down into it.
-- Joel Palmer (1845) describes the descent as "very steep and rocky" into "a beautiful
-- valley" of grass, nearly round and ringed by the timbered Blue Mountains. Cayuse and Nez
-- Perce bands camped and traded here; the Grande Ronde River winds across the floor.
local K = dofile(app.params.kit)
local W, H = 432, 150

K.canvas(W, H, 1845)

K.layer("sky", function()
  K.sky(W, 70, {{60, 14, 0.9}, {250, 24, 0.7}, {340, 8, 1.1}})
  -- the Blue Mountains ringing the far side, timbered and blue with distance
  K.ridge(0, W - 1, 66, 76, function(x) return 22 + 7 * math.sin(x / 47 + 2) + 4 * math.sin(x / 17) end, "far_hill", "mist", "haze")
  K.ridge(0, W - 1, 72, 80, function(x) return 12 + 5 * math.sin(x / 31) + 2 * math.sin(x / 9 + 1) end, "teal", "haze", "pine")
  for i = 1, 260 do
    local x = K.rnd(W)
    local top = 72 - (12 + 5 * math.sin(x / 31) + 2 * math.sin(x / 9 + 1))
    local y = math.floor(top + 1 + K.rnd(math.max(1, 80 - top)))
    K.px(x, y, "pine"); K.px(x, y - 1, "pine")
  end
end)

K.layer("valley", function()
  -- the round valley floor, bright grass, with darker swales and the river's willows
  K.rect(0, 78, W, H - 78, "grass")
  K.dither(0, 78, W, 3, "teal", "grass")
  for y = 80, 118 do
    for x = 0, W - 1 do
      if K.rnd(9) == 0 then K.px(x, y, (y < 92) and "sage" or ((K.rnd(2) == 0) and "sage" or "leaf")) end
    end
  end
  K.river(K.smooth({{440, 84, 1}, {360, 88, 2}, {300, 84, 1.5}, {240, 92, 2}, {180, 88, 2}, {120, 96, 2.5}, {60, 92, 2}, {-10, 98, 3}}, 10), "leaf")
  for i = 1, 40 do
    local t = K.rnd(100) / 100
    local x = math.floor(440 - 450 * t)
    local y = math.floor(84 + 14 * t + 4 * math.sin(t * 9)) - 2
    K.px(x, y, "pine"); K.px(x + 1, y, "leaf")
  end
  -- a lodge camp on the valley floor, and grazing horses
  for _, l in ipairs({{300, 98}, {312, 97}, {322, 99}}) do
    K.poly({{l[1], l[2] - 9}, {l[1] - 4, l[2]}, {l[1] + 4, l[2]}}, "cream")
    K.line(l[1], l[2] - 9, l[1] + 4, l[2], "clap_sh")
    K.px(l[1] - 1, l[2] - 11, "deep"); K.px(l[1] + 1, l[2] - 11, "deep")
    K.px(l[1], l[2] - 1, "deep")
  end
  for _, h in ipairs({{272, 104}, {280, 106}, {346, 103}, {356, 105}, {262, 108}}) do
    K.rect(h[1], h[2] - 2, 4, 2, "wood"); K.px(h[1] + 4, h[2] - 3, "wood")
    K.px(h[1], h[2], "deep"); K.px(h[1] + 3, h[2], "deep")
  end
end)

K.layer("hill", function()
  -- the near hillside dropping from upper left to the valley, open pine and bunchgrass
  -- shadowed fall of the slope below its edge
  K.poly({{0, 86}, {80, 96}, {170, 116}, {260, 136}, {350, 150}, {360, 150}, {270, 132}, {180, 112}, {90, 92}, {0, 82}}, "leaf")
  K.poly({{0, 86}, {80, 96}, {170, 116}, {260, 136}, {330, 150}, {0, 150}}, "gold")
  K.poly({{0, 92}, {80, 102}, {170, 121}, {250, 140}, {300, 150}, {0, 150}}, "ochre")
  for i = 1, 900 do
    local x, y = K.rnd(300), 90 + K.rnd(60)
    local c = K.at(x, y)
    if c == "gold" or c == "ochre" then K.px(x, y, (K.rnd(3) == 0) and "sage" or ((K.rnd(2) == 0) and "gold" or "rust")) end
  end
  for i = 1, 12 do
    local x, y = 8 + K.rnd(250), 112 + K.rnd(36)
    if K.at(x, y) == "ochre" or K.at(x, y) == "sage" or K.at(x, y) == "rust" or K.at(x, y) == "gold" then K.boulder(x, y, 3 + K.rnd(3), 2) end
  end
  for _, t in ipairs({{14, 100, 34}, {36, 108, 28}, {6, 132, 40}, {286, 150, 30}}) do K.conifer(t[1], t[2], t[3]) end
  -- the road cut down the hill: rutted, rocky, steep
  local road = K.smooth({{30, 94, 2}, {90, 104, 3}, {150, 118, 4}, {210, 132, 5}, {270, 150, 6}}, 10)
  K.ribbon(road, "rust", 1)
  K.ribbon(road, "clap_sh", -1)
  for i = 1, #road - 1, 3 do K.px(math.floor(road[i][1]), math.floor(road[i][2]), "dirt_dk") end
end)

K.layer("travelers", function()
  -- wagons easing down with locked wheels, a chain dragging behind; more already on the floor
  K.far_wagon(214, 112, 1)
  K.far_wagon(236, 116, 1)
  K.wagon(118, 130, 1)
  K.team(164, 130, 1, {"red"}, {"light", true})
  K.line(118, 124, 104, 128, "stone_ink")   -- drag chain on the rear wheel
  K.person(108, 132, "blue", "deep", false)
  K.person(200, 131, "red", "bonnet", true)
end)

K.save("location_grande_ronde")
