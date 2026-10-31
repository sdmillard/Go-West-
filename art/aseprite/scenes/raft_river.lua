-- Raft River (432x150). Not a timber stop.
-- A dry sage flat where the little Raft River, fringed with willow, comes down to the Snake.
-- Here the California road turned off south up the Raft River valley toward the City of Rocks,
-- and parties bound for California and for Oregon said their goodbyes. No signpost in 1848:
-- only the two sets of ruts parting in the sage, and the far blue Raft River Mountains.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 184882)

K.layer("sky", function()
  K.sky(W, 82, {{150, 14, 0.7}, {380, 24, 0.5}}, "mist")
end)

K.layer("plain", function()
  K.ridge(0, W - 1, 0, 90, function(x) return -(68 + 6 * math.abs(math.sin(x / 47)) + 2 * math.sin(x / 13)) end, "far_hill", "mist", "haze")
  K.ridge(0, W - 1, 0, 92, function(x) return -(80 + 2 * math.sin(x / 37)) end, "clap_sh", "sand", "silt")
  K.rect(0, 88, W, H - 88, "silt_lt")
  for i = 1, 1100 do
    local x, y = K.rnd(W), 80 + K.rnd(70)
    if K.at(x, y) == "silt_lt" or K.at(x, y) == "clap_sh" then K.px(x, y, ({"silt", "sand", "stone_lt", "clap_sh"})[i % 4 + 1]) end
  end
  for i = 1, 110 do K.sage(K.rnd(W), 92 + K.rnd(58)) end
  -- the Raft River: a thin line of water and willows coming down from the south hills
  local river = K.smooth({{300, 86, 1}, {280, 100, 1}, {240, 116, 2}, {200, 132, 2}, {150, 150, 3}})
  K.ribbon(river, "grass", 3)
  K.river(river, false)
end)

K.layer("roads", function()
  -- the Oregon road running on west, the California road bending away south-west up the valley
  local oregon = K.smooth({{440, 140, 4}, {360, 132, 4}, {300, 124, 3}, {200, 112, 2}, {110, 104, 2}, {20, 98, 1}})
  K.ribbon(oregon, "silt", 1); K.ribbon(oregon, "sand", 0)
  local california = K.smooth({{300, 124, 3}, {300, 112, 2}, {296, 100, 2}, {300, 90, 1}})
  K.ribbon(california, "silt", 1); K.ribbon(california, "sand", 0)
  for _, w in ipairs({{290, 98, 1}, {270, 106, 1}, {232, 122, 1}, {206, 132, 1}, {176, 142, 2}}) do K.willow(w[1], w[2], w[3]) end
end)

K.layer("figures", function()
  -- two wagons parting company: one turns south for California, one goes on for Oregon
  K.wagon(318, 128, -1)
  K.team(302, 123, -1, {"dark"}, {"light", true})
  K.far_wagon(296, 104, 1)
  K.person(336, 136, "blue", "deep"); K.person(346, 137, "red", "bonnet", true)
  K.person(306, 114, "rust", "roof")
  K.far_wagon(130, 104, -1)
end)

K.save("location_raft_river")
