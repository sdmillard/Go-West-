-- The Little Blue River (432x150).
-- For days the road followed the Little Blue up its valley across what is now Nebraska: a narrow
-- timbered bottom of cottonwood, elm and oak between low grassy bluffs, the river winding beside
-- the road, good grass and wood and water, before the trail struck across to the Platte.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 184812)

local course = {{-10, 100, 3}, {70, 104, 4}, {140, 100, 5}, {210, 108, 6}, {250, 120, 8}, {220, 134, 10}, {150, 146, 12}, {80, 160, 14}}

K.layer("sky", function()
  K.sky(W, 74, {{180, 12, 1.0}, {20, 22, 0.6}, {380, 20, 0.7}}, "mist")
end)

K.layer("bluffs", function()
  K.ridge(0, W - 1, 0, 100, function(x) return -(66 + 5 * math.sin(x / 61) + 2 * math.sin(x / 23)) end, "far_hill", "mist", "haze")
  K.ridge(0, W - 1, 0, 100, function(x) return -(76 + 7 * math.sin(x / 33 + 2) + 2 * math.sin(x / 13)) end, "sage", "clap_sh", "grass")
  K.rect(0, 94, W, H - 94, "grass")
  for i = 1, 1300 do
    local x, y = K.rnd(W), 80 + K.rnd(H - 80)
    if K.at(x, y) ~= "far_hill" and K.at(x, y) ~= "mist" and K.at(x, y) ~= "haze" then K.px(x, y, ({"leaf", "sage", "gold", "grass"})[i % 4 + 1]) end
  end
end)

K.layer("river", function()
  local water = K.smooth(course)
  K.ribbon(water, "dirt_dk", 2)
  K.river(water, false)
  -- the road running up the valley on the open side of the bottom
  local road = K.smooth({{440, 140, 6}, {370, 124, 5}, {320, 112, 4}, {290, 104, 3}, {260, 98, 2}, {200, 94, 2}, {120, 92, 1}, {40, 91, 1}})
  K.ribbon(road, "rust", 1); K.ribbon(road, "ochre", 0)
end)

K.layer("timber", function()
  -- the timber belt hugging the river all the way up the valley
  -- a continuous mass of crowns of uneven height, trunks showing beneath here and there
  local dk, md, lt = K.leaves("pine", "leaf", "grass")
  for x = -6, 236, 5 do
    local y = 92 + math.floor(2 * math.sin(x / 17) + 2 * math.sin(x / 7))
    local r = 5 + (x * 7) % 4
    if K.season == "winter" then
      K.line(x, y + 6, x, y - r, "ox"); K.line(x, y - 2, x - 3, y - r, "ox"); K.line(x, y - 3, x + 3, y - r - 1, "ox")
      for i = 0, 5 do K.px(x - 3 + (i * 5 + x) % 7, y - r + (i * 3) % 5, "storm_lt") end
    else
      K.ellipse(x, y - 2, r, r - 1, dk); K.ellipse(x - 1, y - 3, r - 2, r - 3, md); K.ellipse(x - 2, y - 4, math.max(1, r - 4), math.max(1, r - 5), lt)
    end
    if x % 15 == 0 then K.rect(x, y + 3, 1, 3, "deep") end
  end
  for _, t in ipairs({{196, 118, 1}, {262, 130, 1}, {238, 112, 1}, {170, 132, 1}, {118, 140, 1}}) do K.elm(t[1], t[2], t[3]) end
  K.elm(40, 156, 2)
  for _, w in ipairs({{206, 132, 1}, {254, 146, 1}, {150, 126, 1}, {184, 144, 2}}) do K.willow(w[1], w[2], w[3]) end
end)

K.layer("figures", function()
  -- a short train strung out up the valley road
  K.far_wagon(214, 94, -1); K.far_wagon(236, 95, -1)
  K.wagon(334, 122, -1)
  K.team(322, 117, -1, {"light"}, {"dark", true})
  K.person(356, 124, "teal", "bonnet", true)
  K.wagon(412, 140, -1)
  K.team(398, 136, -1, {"red"}, {"dark", true})
  K.person(384, 146, "blue", "deep")
end)

K.save("location_little_blue")
