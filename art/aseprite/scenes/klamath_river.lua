-- The Klamath River crossing (432x150).
-- Below the Klamath lake the river runs over a rock ledge, shallow enough to ford in the fall.
-- West of it the road climbs into pine timber: the Cascade Mountains, the first real forest
-- since the Missouri. Wagons are crossing on the ledge.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 185213)

K.layer("sky", function()
  K.sky(W, 90, {{90, 8, 0.8}, {320, 16, 0.7}}, "mist")
end)

K.layer("mountains", function()
  -- the Cascades rising west (left), timbered
  K.ridge(0, W - 1, 0, 92, function(x) return -(70 - 34 * math.max(0, 1 - x / 300) - 4 * math.sin(x / 17) - 2 * math.sin(x / 6)) end, "teal", "haze", "pine")
  for i = 1, 1200 do local x, y = K.rnd(W), 30 + K.rnd(60); if K.at(x, y) == "teal" then K.px(x, y, ({"pine", "leaf", "teal", "pine"})[i % 4 + 1]) end end
  for x = 3, 300, 7 do local top = math.floor(70 - 34 * math.max(0, 1 - x / 300) - 4 * math.sin(x / 17) - 2 * math.sin(x / 6)); K.conifer(x, top + 8, 7 + x % 4) end
  -- open juniper and sage country to the east (right)
  K.ridge(260, W - 1, 0, 92, function(x) return -(78 - 3 * math.sin(x / 19)) end, "sage", "haze", "teal")
end)

K.layer("river", function()
  K.rect(0, 86, W, H - 86, "silt_lt")
  for i = 1, 1000 do K.px(K.rnd(W), 86 + K.rnd(H - 86), ({"sage", "grass", "silt", "gold"})[i % 4 + 1]) end
  local water = {{-10, 100, 9}, {100, 104, 10}, {200, 108, 11}, {300, 106, 11}, {440, 102, 10}}
  local w = K.smooth(water)
  K.ribbon(w, "stone_dk", 2); K.river(w, false)
  -- the rock ledge: a pale shelf across the river with white water spilling below it
  for x = 150, 280 do
    local y = 100 + math.floor((x - 150) * 0.05 + math.sin(x / 7))
    K.rect(x, y, 1, 8, ((x * 7) % 5 == 0) and "stone_dk" or "stone")
    K.px(x, y, "stone_lt")
    for d = 8, 8 + 2 + K.rnd(4) do if K.rnd(4) ~= 0 then K.px(x, y + d, (K.rnd(3) == 0) and "light_blue" or "white") end end
  end
  local road = K.smooth({{440, 124, 4}, {340, 120, 4}, {290, 112, 3}, {216, 104, 3}, {150, 100, 3}, {110, 92, 2}, {60, 84, 2}, {20, 78, 1}})
  K.ribbon(road, "rust", 1); K.ribbon(road, "ochre", 0)
end)

K.layer("trees", function()
  for _, t in ipairs({{12, 98, 34}, {34, 92, 26}, {56, 96, 30}, {84, 90, 22}, {20, 140, 44}, {50, 148, 40}}) do K.conifer(t[1], t[2], t[3]) end
  for _, j in ipairs({{350, 96}, {390, 92}, {420, 98}}) do K.ellipse(j[1], j[2] - 4, 3, 4, "pine"); K.ellipse(j[1] - 1, j[2] - 5, 2, 2, "teal"); K.rect(j[1], j[2] - 1, 1, 2, "deep") end
  for _, s in ipairs({{330, 136}, {380, 128}, {410, 142}, {360, 112}}) do K.sage(s[1], s[2]) end
end)

K.layer("figures", function()
  K.wagon(200, 104, -1)
  K.team(186, 100, -1, {"dark"}, {"light", true})
  K.wade(198, 246, 104, 3); K.wade(186, 214, 100, 3)
  K.wagon(330, 122, -1)
  K.team(316, 118, -1, {"red"}, {"dark"})
  K.person(300, 126, "blue", "hat")
end)

-- winter: snow on the pale desert ground as well as the grass
K.season_extra = {{season="winter", y0=84, y1=150, map={silt_lt="white", gold="stone_lt"}}}
K.save("location_klamath_river")
