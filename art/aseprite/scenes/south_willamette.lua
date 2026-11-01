-- The head of the Willamette valley (432x150).
-- Over the Calapooya hills the Willamette valley opens wide and green, the Coast Range and the
-- Cascades blue on either side, the river winding among cottonwoods and ash. At its head a few
-- new claims: a log cabin, a rail fence, a cleared field, Eugene Skinner's among them.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 185275)

K.layer("sky", function()
  K.sky(W, 76, {{110, 10, 1.0}, {300, 16, 0.8}}, "mist")
end)

K.layer("distance", function()
  -- Spencer Butte and the Coast Range hills to the west, the Cascades far east with snow
  K.peaks(300, W - 1, 70, 80, function(x) return 14 + 8 * math.sin(x / 23) end, 18)
  K.ridge(0, W - 1, 0, 90, function(x) return -(64 - 6 * math.sin(x / 41) - 3 * math.sin(x / 13)) end, "far_hill", "mist", "haze")
  K.ridge(0, 200, 0, 92, function(x) return -(80 - 32 * math.max(0, 1 - math.abs(x - 70) / 90) ^ 1.6 - 2 * math.sin(x / 7)) end, "teal", "haze", "pine")
  for i = 1, 500 do local x, y = K.rnd(200), 48 + K.rnd(44); if K.at(x, y) == "teal" then K.px(x, y, ({"pine", "leaf", "teal"})[i % 3 + 1]) end end
end)

K.layer("valley", function()
  K.rect(0, 86, W, H - 86, "grass")
  for i = 1, 2000 do K.px(K.rnd(W), 86 + K.rnd(H - 86), ({"leaf", "sage", "grass", "gold", "grass"})[i % 5 + 1]) end
  local water = K.smooth({{440, 96, 3}, {360, 100, 4}, {300, 96, 4}, {230, 102, 5}, {160, 98, 5}, {90, 104, 6}, {-10, 100, 6}})
  K.ribbon(water, "leaf", 2); K.river(water, "silt_lt")
  -- a cleared field, ploughed, beside the claim
  K.poly({{250, 112}, {350, 110}, {370, 128}, {262, 132}}, "dirt_dk")
  for y = 113, 130, 2 do K.line(254 + (y - 112) // 2, y, 352 + (y - 110), y, "rust") end
  local road = K.smooth({{-10, 130, 4}, {80, 134, 4}, {160, 138, 5}, {240, 140, 5}, {340, 144, 6}, {440, 146, 6}})
  K.ribbon(road, "rust", 1); K.ribbon(road, "ochre", 0)
end)

K.layer("trees", function()
  for _, t in ipairs({{40, 100, 1}, {120, 96, 1}, {200, 98, 1}, {330, 96, 1}, {410, 98, 1}, {60, 128, 2}}) do K.elm(t[1], t[2], t[3]) end
  for _, w in ipairs({{150, 104, 1}, {280, 104, 1}, {380, 102, 1}}) do K.willow(w[1], w[2], w[3]) end
end)

K.layer("claim", function()
  -- the claim cabin with smoke, and a worm rail fence along the field
  K.log_cabin(200, 124, 30, 16, 4, K.season == "winter")
  for x = 246, 372, 6 do
    local y = 108 + (x - 246) // 40
    K.line(x, y + ((x // 6) % 2) * 2, x + 6, y + (((x // 6) + 1) % 2) * 2, "wood")
    K.line(x, y + 3 + ((x // 6) % 2) * 2, x + 6, y + 3 + (((x // 6) + 1) % 2) * 2, "wood")
  end
end)

K.layer("figures", function()
  K.wagon(110, 136, 1)
  K.team(160, 132, 1, {"red"}, {"dark"})
  K.person(236, 128, "brick", "hat") -- the settler come out to meet them
  K.person(98, 140, "teal", "bonnet", true)
  K.ox(320, 122, -1, "light")
end)

K.save("location_south_willamette")
