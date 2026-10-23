-- Little Sandy (432x150).
-- West of South Pass the road crosses dry sage plain to the willow-fringed Little Sandy, a small
-- creek. Near here the road forked: the shorter northern cutoff struck straight across the
-- desert, while this journey keeps to the longer southern road toward Bridger's post.
-- The Wind River Range still shows white to the north.
local K = dofile(app.params.kit)
local W, H = 432, 150

K.canvas(W, H, 184834)

K.layer("sky", function()
  K.sky(W, 98, {{288, 12, 0.8}, {120, 24, 0.5}}, "mist")
end)

K.layer("ranges", function()
  local tops = {{280, 18}, {312, 26}, {344, 22}, {376, 30}, {410, 26}, {440, 30}}
  K.peaks(240, W - 1, 92, 94, function(x)
    local h = 4 * math.max(0, math.min(1, (x - 240) / 40))
    for _, p in ipairs(tops) do h = math.max(h, p[2] - math.abs(x - p[1]) * 0.8) end
    return h
  end, 18)
  K.ridge(0, 260, 0, 94, function(x) return -(86 + 2 * math.sin(x / 19)) end, "far_hill", "mist", "haze")
end)

K.layer("plain", function()
  K.rect(0, 90, W, H - 90, "clap_sh")
  for x = 0, W - 1 do K.px(x, 90, "sand") end
  for i = 1, 2200 do
    local x, y = K.rnd(W), 90 + K.rnd(60)
    K.px(x, y, ({"sage", "teal", "ochre", "haze", "clap_sh", "sand"})[i % 6 + 1])
  end
  -- the creek: small, willow-lined, cut a few feet below the plain
  local creek = K.smooth({{-6, 112, 2}, {70, 116, 2}, {140, 112, 3}, {200, 120, 3}, {260, 116, 3}, {330, 124, 4}, {440, 120, 4}})
  K.ribbon(creek, "ochre", 3)
  K.ribbon(creek, "grass", 2)
  K.river(creek, false)
  -- the fork: the cutoff runs off right across the desert, the main road bends left to the ford
  local main = K.smooth({{300, 158, 7}, {286, 138, 5}, {250, 126, 4}, {210, 120, 3}, {150, 106, 2}, {80, 98, 1}, {-6, 94, 1}})
  K.ribbon(main, "ochre", 1); K.ribbon(main, "sand", 0)
  local cutoff = K.smooth({{286, 138, 4}, {330, 124, 3}, {380, 110, 2}, {440, 100, 1}})
  K.ribbon(cutoff, "ochre", 0)
  for i = 1, 30 do
    local x, y = K.rnd(W), 120 + K.rnd(30)
    local c = K.at(x, y)
    if c ~= "sand" and c ~= "ochre" and c ~= "blue" and c ~= "sky_top" and c ~= "grass" and c ~= "light_blue" and c ~= "white" then K.sage(x, y) end
  end
end)

K.layer("willows", function()
  for _, w in ipairs({{30, 112}, {58, 115}, {120, 111}, {176, 117}, {236, 116}, {250, 118}, {312, 122}, {352, 124}, {400, 121}}) do K.willow(w[1], w[2], 1) end
end)

K.layer("figures", function()
  -- a wagon fording the creek, the water barely over the felloes
  K.wagon(190, 121, -1)
  K.team(180, 117, -1, {"dark"}, {"light", true})
  K.wade(186, 238, 121, 4)
  K.wade(150, 180, 118, 3)
  -- a small party far off, taking the cutoff into the desert
  K.far_wagon(386, 109, 1)
  K.far_wagon(410, 104, 1)
  -- near the fork, a man pointing the way down the southern road
  K.person(270, 146, "red", "deep")
  K.line(266, 136, 260, 134, "red")
  K.person(282, 148, "teal", "bonnet", true)
end)

K.save("location_little_sandy")
