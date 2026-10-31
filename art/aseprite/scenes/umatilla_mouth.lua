-- The Columbia at the mouth of the Umatilla (432x150). Not a timber stop.
-- Here the emigrants first came to the great Columbia: a wide, fast river between low, bare
-- basalt bluffs, the Umatilla running in through sand, dunes and sage, wind blowing the sand
-- about, and no timber at all. The roads from the Blue Mountains and from Walla Walla join here.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 184898)

K.layer("sky", function()
  K.sky(W, 72, {{220, 10, 0.8}, {40, 18, 0.6}}, "mist")
end)

K.layer("far shore", function()
  -- Washington side: bare rimrock bluffs in layered basalt
  K.ridge(0, W - 1, 0, 84, function(x) return -(56 + 6 * math.sin(x / 47) + 3 * math.abs(math.sin(x / 19))) end, "far_hill", "mist", "haze")
  for x = 0, W - 1 do
    local t = 66 + math.floor(3 * math.sin(x / 31) + 2 * math.sin(x / 11))
    for y = t, 84 do
      local h = (x * 73 + y * 151 + (x // 3) * 37) % 13
      local band = ((y - t + (x // 40)) % 6 == 0)
      K.px(x, y, (band and h < 9 and "stone_dk") or (h == 0 and "stone_ink") or (h < 3 and "stone_dk") or (h == 12 and "stone_lt") or "stone")
    end
    K.px(x, t, "rust")
  end
end)

K.layer("river", function()
  -- the Columbia: a broad band of dark water, wind chop and long glints
  K.rect(0, 84, W, 26, "blue")
  for i = 1, 260 do local x, y = K.rnd(W), 85 + K.rnd(24); K.rect(x, y, 3 + K.rnd(8), 1, (i % 4 == 0) and "white" or ((i % 2 == 0) and "light_blue" or "sky_top")) end
  K.rect(0, 84, W, 1, "storm_lt")
  -- near shore: pale sand and dunes rippled by the wind, sage between them
  K.rect(0, 110, W, H - 110, "sand")
  K.rect(0, 110, W, 1, "cream")
  for _, d in ipairs({{60, 122, 40, 6}, {200, 130, 50, 8}, {360, 120, 36, 5}, {300, 144, 44, 6}}) do
    K.ellipse(d[1], d[2], d[3], d[4], "clap_sh"); K.ellipse(d[1] - 6, d[2] - 2, d[3] - 10, d[4] - 3, "cream")
    for k = -d[3] + 6, d[3] - 6, 5 do K.line(d[1] + k, d[2] - 1, d[1] + k + 3, d[2] + 1, "sand") end
  end
  for i = 1, 600 do K.px(K.rnd(W), 112 + K.rnd(38), ({"silt_lt", "clap_sh", "sand", "cream"})[i % 4 + 1]) end
  for i = 1, 40 do K.sage(K.rnd(W), 116 + K.rnd(34)) end
  -- the Umatilla coming in through the sand, a few willows at its mouth
  local mouth = K.smooth({{96, 152, 4}, {130, 140, 3}, {138, 128, 3}, {160, 120, 4}, {170, 110, 6}})
  K.ribbon(mouth, "silt_lt", 2)
  K.river(mouth, false)
  K.willow(130, 134, 1); K.willow(176, 122, 1); K.willow(110, 146, 1)
  -- roads from the hills joining by the river
  local road = K.smooth({{440, 142, 4}, {380, 136, 3}, {300, 128, 3}, {230, 122, 2}, {190, 118, 2}})
  K.ribbon(road, "silt", 1); K.ribbon(road, "silt_lt", 0)
end)

K.layer("figures", function()
  K.wagon(300, 136, -1)
  K.team(286, 131, -1, {"dark"}, {"light", true})
  K.person(322, 140, "blue", "deep"); K.person(332, 141, "red", "bonnet", true)
  K.far_wagon(400, 132, -1)
  -- sand blowing off a dune crest
  for k = 0, 10 do K.px(214 + k * 3, 120 - (k % 3), "cream") end
end)

K.save("location_umatilla_mouth")
