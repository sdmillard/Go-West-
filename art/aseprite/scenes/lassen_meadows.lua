-- The Applegate turnoff at Lassen's Meadows (432x150).
-- A wide meadow on the big bend of the Humboldt. The California road goes on down the river
-- to the left; the Applegate road turns off northwest, to the right, across bare desert toward
-- Rabbit Hole Springs and Black Rock. A rough sign and a cairn mark the parting.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 185139)

K.layer("sky", function()
  K.sky(W, 72, {{100, 12, 0.7}, {330, 6, 1.1}}, "mist")
end)

K.layer("country", function()
  -- the desert ahead: far blue ranges, then pale bare flats
  K.ridge(0, W - 1, 0, 88, function(x) return -(62 - 8 * math.abs(math.sin(x / 31 + 2)) - 3 * math.sin(x / 11)) end, "far_hill", "mist", "haze")
  -- low bare hills to the northwest, rising out of the flat
  K.ridge(0, W - 1, 0, 92, function(x) local f = math.min(1, math.max(0, (x - 150) / 90)); return -(84 - f * (12 + 5 * math.abs(math.sin(x / 23)))) end, "clap_sh", "sand", "silt")
  K.rect(0, 84, W, H - 84, "clap_sh")
  for i = 1, 900 do K.px(K.rnd(W), 84 + K.rnd(H - 84), ({"sand", "silt_lt", "silt", "sage"})[i % 4 + 1]) end
end)

K.layer("meadow", function()
  -- the meadow along the river on the left half
  for y = 88, H - 1 do
    local edge = 150 + (y - 88) * 1.1 + 10 * math.sin(y / 5) + 6 * math.sin(y / 2.3)
    if y > 112 then edge = 230 - (y - 112) * 0.8 + 8 * math.sin(y / 4) end
    K.rect(0, y, math.floor(edge), 1, "grass")
  end
  for i = 1, 1100 do local x, y = K.rnd(W), 88 + K.rnd(H - 88); if K.at(x, y) == "grass" then K.px(x, y, ({"leaf", "sage", "gold", "grass"})[i % 4 + 1]) end end
  local water = K.smooth({{-10, 104, 5}, {50, 110, 6}, {110, 104, 6}, {150, 96, 5}, {190, 92, 4}, {230, 90, 3}})
  K.ribbon(water, "leaf", 2); K.river(water, "silt_lt")
  -- the roads: down the river, and off to the northwest
  local down = K.smooth({{250, 128, 4}, {170, 134, 4}, {90, 128, 4}, {20, 122, 3}, {-10, 120, 3}})
  K.ribbon(down, "rust", 1); K.ribbon(down, "ochre", 0)
  local north = K.smooth({{250, 128, 4}, {300, 114, 3}, {350, 100, 2}, {400, 90, 1}, {440, 86, 1}})
  K.ribbon(north, "silt", 1); K.ribbon(north, "sand", 0)
  local come = K.smooth({{250, 128, 4}, {300, 140, 5}, {440, 148, 6}})
  K.ribbon(come, "rust", 1); K.ribbon(come, "ochre", 0)
end)

K.layer("marks", function()
  for _, w in ipairs({{40, 98, 1}, {120, 98, 1}, {170, 90, 1}, {70, 120, 2}}) do K.willow(w[1], w[2], w[3]) end
  for _, s in ipairs({{300, 100}, {380, 108}, {420, 124}, {360, 132}, {330, 90}, {410, 96}}) do K.sage(s[1], s[2]) end
  -- cairn and the sign at the parting
  K.ellipse(268, 120, 5, 3, "stone_dk"); K.ellipse(267, 117, 4, 3, "stone"); K.ellipse(266, 113, 3, 2, "stone_lt")
  K.rect(282, 104, 1, 16, "wood"); K.rect(276, 104, 16, 5, "ochre"); K.rect(276, 108, 16, 1, "wood")
  for i = 0, 3 do K.rect(278 + i * 3, 106, 2, 1, "deep") end
  K.line(284, 106, 290, 102, "deep")
end)

K.layer("figures", function()
  K.wagon(296, 120, 1)
  K.team(346, 112, 1, {"red"}, {"dark"})
  K.person(258, 128, "blue", "hat")
  K.person(250, 130, "red", "bonnet", true)
  K.far_wagon(60, 121, -1) -- a California wagon going on down the river
  K.ox(140, 120, 1, "light")
end)

-- winter: snow on the pale desert ground as well as the grass
K.season_extra = {{season="winter", y0=60, y1=150, map={silt_lt="white", clap_sh="white", sand="stone_lt"}}}
K.save("location_lassen_meadows")
