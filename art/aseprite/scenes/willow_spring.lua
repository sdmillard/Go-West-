-- Willow Spring (432x150). Not a timber stop.
-- Between the North Platte and the Sweetwater the road crossed a dry, alkaline sage upland.
-- Willow Spring was the one sweet water on it: a cold spring rising in a little hollow under a
-- clump of willows, with a bit of grass; Prospect Hill rises just beyond on the road west.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 184844)

K.layer("sky", function()
  K.sky(W, 80, {{220, 12, 0.8}, {60, 26, 0.5}}, "mist")
end)

K.layer("upland", function()
  K.ridge(0, W - 1, 0, 96, function(x) return -(70 + 3 * math.sin(x / 71) + 2 * math.sin(x / 19)) end, "far_hill", "mist", "haze")
  -- Prospect Hill: a long rise the road climbs beyond the spring
  K.ridge(0, W - 1, 0, 100, function(x) local d = (x - 330) / 90; return -(84 - 14 * math.exp(-d * d) + math.sin(x / 9)) end, "clap_sh", "sand", "silt")
  K.rect(0, 92, W, H - 92, "silt_lt")
  for i = 1, 900 do
    local x, y = K.rnd(W), 70 + K.rnd(80)
    local c = K.at(x, y)
    if c == "silt_lt" or c == "clap_sh" then K.px(x, y, ({"silt", "sand", "stone_lt", "clap_sh"})[i % 4 + 1]) end
  end
  -- alkali patches crusted white
  for _, a in ipairs({{60, 120, 22, 3}, {300, 132, 30, 4}, {390, 108, 16, 2}}) do
    K.ellipse(a[1], a[2], a[3], a[4], "stone_lt"); K.ellipse(a[1] - 3, a[2], a[3] - 6, math.max(1, a[4] - 2), "white")
  end
  -- sage everywhere, bigger near
  for i = 1, 70 do
    local x, y = K.rnd(W), 96 + K.rnd(54)
    if K.at(x, y) ~= "white" then K.sage(x, y) end
  end
end)

K.layer("spring", function()
  -- the hollow: green grass around a little pool and run, a thick clump of willows
  K.ellipse(180, 124, 52, 12, "grass")
  K.ellipse(178, 122, 40, 8, "leaf")
  for i = 1, 200 do local x, y = 130 + K.rnd(100), 112 + K.rnd(24); if K.at(x, y) == "grass" or K.at(x, y) == "leaf" then K.px(x, y, (i % 3 == 0) and "sage" or "grass") end end
  K.ellipse(184, 124, 10, 3, "blue"); K.ellipse(183, 123, 7, 2, "sky_top"); K.rect(180, 122, 3, 1, "white")
  K.line(194, 125, 226, 134, "blue"); K.line(195, 125, 227, 134, "sky_top")
  for _, w in ipairs({{160, 120, 2}, {176, 116, 2}, {200, 118, 2}, {150, 126, 1}, {214, 124, 1}}) do K.willow(w[1], w[2], w[3]) end
  -- the road passing by
  local road = K.smooth({{-6, 140, 4}, {80, 136, 4}, {150, 138, 3}, {240, 128, 3}, {300, 112, 2}, {340, 100, 2}, {380, 92, 1}})
  K.ribbon(road, "silt", 1); K.ribbon(road, "sand", 0)
end)

K.layer("figures", function()
  K.wagon(96, 140, 1)
  K.team(150, 140, 1, {"light"}, {"dark", true})
  K.person(186, 130, "blue", "deep"); K.rect(190, 127, 3, 3, "wood")
  K.person(70, 144, "red", "bonnet", true)
  K.far_wagon(330, 104, 1)
  -- the bleached skull of an ox that did not get this far
  K.rect(268, 142, 5, 3, "white"); K.px(267, 141, "white"); K.px(273, 141, "white"); K.px(269, 143, "stone_dk")
end)

K.save("location_willow_spring")
