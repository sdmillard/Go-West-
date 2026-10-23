-- Blue Mountains (432x150): the road climbing through heavy timber.
-- Emigrants found the Blues the worst-timbered country on the trail: ponderosa pine, fir and
-- larch so close that the road was cut through it, with steep pitches where teams were
-- doubled. Seen from a clearing at the foot of one climb, the road going up into the trees.
local K = dofile(app.params.kit)
local W, H = 432, 150

K.canvas(W, H, 1846)

K.layer("sky", function()
  K.sky(W, 60, {{120, 12, 0.7}, {300, 20, 1.0}}, "mist")
  -- timbered ridges stacking back, each paler with distance
  K.ridge(0, W - 1, 56, 70, function(x) return 18 + 6 * math.sin(x / 53 + 1) + 3 * math.sin(x / 19) end, "far_hill", "mist", "haze")
  K.ridge(0, W - 1, 66, 80, function(x) return 16 + 8 * math.sin(x / 37 + 3) + 3 * math.sin(x / 11) end, "haze", "far_hill", "teal")
end)

K.layer("far_timber", function()
  K.rect(0, 74, W, H - 74, "pine")
  -- a wall of conifer tips along the middle distance
  for x = -4, W + 4, 5 do
    local h = 14 + K.rnd(10)
    K.conifer(x + K.rnd(3), 84 + K.rnd(4), h, "ink", "pine", "teal")
  end
  for x = -4, W + 4, 7 do
    local h = 18 + K.rnd(12)
    K.conifer(x + K.rnd(4), 96 + K.rnd(5), h, "ink", "pine", "leaf")
  end
end)

K.layer("clearing", function()
  -- a grassy clearing with stumps where earlier trains cut timber
  K.poly({{0, 112}, {120, 104}, {260, 106}, {432, 112}, {432, 150}, {0, 150}}, "grass")
  K.dither(0, 110, W, 3, "leaf", "grass")
  for i = 1, 800 do
    local x, y = K.rnd(W), 108 + K.rnd(42)
    if K.at(x, y) == "grass" then K.px(x, y, (K.rnd(3) == 0) and "gold" or ((K.rnd(2) == 0) and "leaf" or "sage")) end
  end
  for _, s in ipairs({{70, 126}, {96, 140}, {226, 132}, {384, 128}, {350, 144}}) do
    K.rect(s[1], s[2] - 3, 5, 3, "wood"); K.rect(s[1], s[2] - 4, 5, 1, "gold"); K.px(s[1] + 2, s[2] - 4, "ochre")
  end
  -- the road: across the clearing, then up a steep pitch into the timber at upper left
  local road = K.smooth({{440, 146, 7}, {330, 136, 6}, {220, 126, 5}, {140, 114, 3}, {104, 100, 2}, {92, 90, 1}}, 10)
  K.ribbon(road, "rust", 1)
  K.ribbon(road, "ochre", -1)
  for i = 1, #road - 1, 2 do K.px(math.floor(road[i][1]), math.floor(road[i][2]), "dirt_dk") end
  -- big trees framing the clearing
  for _, t in ipairs({{10, 150, 64}, {34, 146, 52}, {404, 150, 70}, {426, 140, 54}, {128, 112, 36}, {168, 108, 30}}) do
    K.conifer(t[1], t[2], t[3], "ink", "pine", "leaf")
  end
end)

K.layer("travelers", function()
  -- a doubled team takes a wagon up the pitch; the next wagon waits its turn
  K.far_wagon(108, 104, -1)
  K.wagon(250, 134, -1)
  K.team(236, 133, -1, {"dark"}, {"red", true})
  K.team(206, 130, -1, {"light"}, {"dark", true})
  K.person(186, 132, "blue", "deep", false)
  K.person(310, 138, "red", "bonnet", true)
end)

K.save("location_blue_mountains")
