-- The Bear River valley at Smith's Fork (432x150).
-- After the dry miles from Green River the road came down into the Bear River valley: a broad
-- green bottom, willows along a winding river, good grass, and mountains all around. Here
-- Smith's Fork comes in and the Greenwood cutoff's road rejoins the road from Fort Bridger.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 184852)

local river = {{-10, 98, 3}, {60, 102, 4}, {120, 98, 4}, {190, 106, 5}, {250, 114, 6}, {320, 110, 7}, {380, 120, 8}, {440, 132, 9}}
local fork = {{120, 150, 4}, {150, 134, 3}, {180, 120, 3}, {205, 110, 3}}

K.layer("sky", function()
  K.sky(W, 76, {{300, 10, 0.9}, {100, 20, 0.7}}, "mist")
end)

K.layer("mountains", function()
  K.ridge(0, W - 1, 0, 90, function(x) return -(50 - 12 * math.abs(math.sin(x / 41)) - 6 * math.abs(math.sin(x / 17 + 1))) end, "far_hill", "mist", "haze")
  K.ridge(0, W - 1, 0, 90, function(x) return -(60 - 8 * math.abs(math.sin(x / 27 + 2)) - 3 * math.sin(x / 7)) end, "haze", "far_hill", "teal")
  K.ridge(0, W - 1, 0, 96, function(x) return -(70 + 6 * math.sin(x / 29) + 3 * math.sin(x / 11)) end, "teal", "haze", "pine")
  for i = 1, 300 do local x, y = K.rnd(W), 60 + K.rnd(30); if K.at(x, y) == "teal" then K.px(x, y, (i % 2 == 0) and "pine" or "sage") end end
  for x = 6, W, 23 do K.conifer(x, 80 + math.floor(6 * math.sin(x / 29)), 8 + x % 4) end
end)

K.layer("valley", function()
  K.rect(0, 92, W, H - 92, "grass")
  for i = 1, 1400 do K.px(K.rnd(W), 92 + K.rnd(H - 92), ({"leaf", "sage", "gold", "grass"})[i % 4 + 1]) end
  local water = K.smooth(river)
  K.ribbon(water, "leaf", 3)
  K.river(water, false)
  local fw = K.smooth(fork)
  K.ribbon(fw, "leaf", 2)
  K.river(fw, false)
  -- two roads meeting: from Bridger along the valley, and the cutoff coming over the hills
  local main = K.smooth({{440, 104, 2}, {380, 100, 2}, {300, 98, 2}, {250, 100, 2}, {230, 104, 2}})
  K.ribbon(main, "rust", 1); K.ribbon(main, "ochre", 0)
  local cutoff = K.smooth({{300, 70, 1}, {290, 84, 1}, {260, 96, 2}, {232, 104, 2}})
  K.ribbon(cutoff, "rust", 1); K.ribbon(cutoff, "ochre", 0)
  local on = K.smooth({{230, 104, 2}, {210, 124, 3}, {170, 140, 4}, {100, 146, 5}, {-6, 148, 5}})
  K.ribbon(on, "rust", 1); K.ribbon(on, "ochre", 0)
end)

K.layer("willows", function()
  for i = 1, #river - 1 do
    local a = river[i]
    K.willow(a[1] + 10, a[2] - a[3] - 1, 1); K.willow(a[1] + 26, a[2] + a[3] + 6, (a[2] > 112) and 2 or 1)
  end
  for _, w in ipairs({{142, 130, 1}, {170, 114, 1}, {198, 104, 1}}) do K.willow(w[1], w[2], w[3]) end
end)

K.layer("figures", function()
  K.wagon(180, 140, -1)
  K.team(166, 136, -1, {"dark"}, {"light", true})
  K.person(206, 142, "teal", "bonnet", true)
  K.far_wagon(280, 90, -1)
  K.far_wagon(360, 101, -1)
  K.ox(330, 132, 1, "red"); K.ox(60, 120, -1, "light")
end)

K.save("location_bear_river")
