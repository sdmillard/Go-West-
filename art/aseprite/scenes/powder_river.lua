-- Powder River valley (432x150).
-- After the Burnt River canyon the road opens into the broad grassy Powder valley. The Elkhorn
-- range rises to the west, dark with pine below and snow above, and the Blue Mountains wait
-- ahead. Palmer's famous lone pine was already a stump, so a stump is what is shown.
local K = dofile(app.params.kit)
local W, H = 432, 150

K.canvas(W, H, 184835)

K.layer("sky", function()
  K.sky(W, 96, {{330, 10, 0.9}, {150, 22, 0.6}}, "mist")
end)

K.layer("mountains", function()
  -- the Elkhorns: snowy crests, pine forest on the lower slopes
  local tops = {{40, 30}, {84, 42}, {126, 36}, {170, 48}, {214, 40}, {250, 30}}
  local elk = function(x)
    local h = 6
    for _, p in ipairs(tops) do h = math.max(h, p[2] - math.abs(x - p[1]) * 0.7) end
    return h
  end
  K.peaks(0, 300, 92, 94, elk, 30)
  -- pine forest on the lower slopes, with a ragged tree line of spires
  for x = 0, 300 do
    local top = math.floor(92 - elk(x) + 0.5)
    local line = 92 - (14 + math.floor(4 * math.sin(x / 13) + 2 * math.sin(x / 5)))
    if x % 3 == 0 then line = line - 2 end
    local lit = elk(x + 1) - elk(x - 1) > 0
    for y = math.max(top + 1, line), 94 do K.px(x, y, (lit and (x + y) % 3 ~= 0) and "haze" or "teal") end
  end
  -- Blue Mountains, lower and farther, to the north-west (right)
  K.ridge(280, W - 1, 0, 94, function(x) return -(76 - 6 * math.sin(x / 23) - 3 * math.sin(x / 9)) end, "far_hill", "mist", "haze")
end)

K.layer("valley", function()
  K.rect(0, 90, W, H - 90, "grass")
  for i = 1, 2000 do
    local x, y = K.rnd(W), 90 + K.rnd(60)
    K.px(x, y, ({"sage", "gold", "leaf", "grass", "clap_sh"})[i % 5 + 1])
    if y > 120 and i % 3 == 0 then K.px(x, y - 1, "gold") end
  end
  -- distant foothill benches
  K.ridge(0, W - 1, 0, 100, function(x) return -(92 - 4 * math.max(0, math.sin(x / 40))) end, "sage", "gold", "grass")
  -- the Powder River meandering through the meadow
  local river = K.smooth({{-6, 104, 2}, {60, 108, 2}, {120, 104, 3}, {190, 112, 3}, {240, 108, 3}, {300, 116, 4}, {350, 112, 4}, {440, 118, 5}})
  K.ribbon(river, "leaf", 3)
  K.river(river, "sage")
  local road = K.smooth({{440, 140, 6}, {360, 132, 5}, {280, 126, 4}, {200, 122, 3}, {120, 118, 2}, {40, 114, 1}, {-6, 112, 1}})
  K.ribbon(road, "ochre", 1); K.ribbon(road, "sand", 0)
end)

K.layer("trees", function()
  -- cottonwoods and willows along the river
  for _, t in ipairs({{70, 106, 1}, {132, 102, 1}, {250, 106, 1}, {356, 110, 1}}) do K.elm(t[1], t[2], t[3]) end
  for _, w in ipairs({{96, 108}, {176, 112}, {206, 114}, {290, 116}, {320, 116}, {400, 120}}) do K.willow(w[1], w[2], 1) end
  -- Palmer's lone pine, already cut down: a stump with chips around it
  local sx, sy = 168, 128
  K.rect(sx, sy - 5, 6, 5, "wood"); K.rect(sx, sy - 5, 2, 5, "rust")
  K.rect(sx, sy - 6, 6, 1, "ochre"); K.px(sx + 2, sy - 6, "gold"); K.px(sx + 4, sy - 6, "rust")
  K.px(sx - 1, sy, "wood"); K.px(sx + 6, sy, "wood"); K.px(sx + 8, sy - 1, "ochre")
  K.shadow(sx, sy + 1, 9)
end)

K.layer("figures", function()
  K.wagon(250, 136, -1)
  K.team(240, 132, -1, {"red"}, {"dark", true})
  K.person(178, 129, "blue", "deep")
  K.person(300, 140, "red", "bonnet", true)
  K.far_wagon(80, 116, -1)
  K.far_wagon(104, 117, -1)
end)

K.save("location_powder_river")
