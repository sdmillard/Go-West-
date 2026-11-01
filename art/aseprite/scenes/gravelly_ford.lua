-- Gravelly Ford of the Humboldt (432x150).
-- A gravel bar lets the wagons cross the Humboldt. Willows and rye grass line the river, and
-- there is nothing else for fuel or shade: bare sage hills on both sides under a wide sky.
-- Wagons are fording; on the near bank a guard sits up with the cattle.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 185127)

local river = {{-10, 96, 5}, {80, 102, 6}, {160, 108, 8}, {240, 112, 9}, {320, 108, 8}, {440, 100, 7}}

K.layer("sky", function()
  K.sky(W, 70, {{40, 16, 0.6}, {220, 8, 0.9}}, "mist")
end)

K.layer("hills", function()
  K.ridge(0, W - 1, 0, 90, function(x) return -(60 - 9 * math.abs(math.sin(x / 53 + 1)) - 4 * math.sin(x / 21)) end, "far_hill", "mist", "haze")
  K.ridge(0, W - 1, 0, 96, function(x) return -(76 - 7 * math.sin(x / 37) - 3 * math.sin(x / 13 + 2)) end, "clap_sh", "sand", "silt")
  for i = 1, 400 do local x, y = K.rnd(W), 66 + K.rnd(30); if K.at(x, y) == "clap_sh" then K.px(x, y, ({"sage", "silt", "haze"})[i % 3 + 1]) end end
end)

K.layer("bottom", function()
  K.rect(0, 88, W, H - 88, "silt_lt")
  for i = 1, 1300 do K.px(K.rnd(W), 88 + K.rnd(H - 88), ({"sage", "silt", "gold", "clap_sh", "sand"})[i % 5 + 1]) end
  local water = K.smooth(river)
  K.ribbon(water, "sage", 6) -- rye grass along the banks
  K.river(water, "stone_lt")
  -- the gravel bar across the channel
  -- the gravel bar shows as broken riffles and stones across the shallow channel
  for i = 1, 260 do
    local x = 196 + K.rnd(70)
    local y = 103 + math.floor((x - 196) * 0.12) + K.rnd(12)
    local r = K.rnd(5)
    if r == 0 then K.px(x, y, "stone") elseif r == 1 then K.px(x, y, "stone_lt") else K.rect(x, y, 1 + K.rnd(3), 1, (r == 2) and "white" or "light_blue") end
  end
  local road = K.smooth({{230, 98, 2}, {226, 104, 2}, {230, 118, 3}, {200, 134, 4}, {120, 146, 5}, {-10, 148, 5}})
  K.ribbon(road, "rust", 1); K.ribbon(road, "ochre", 0)
end)

K.layer("willows", function()
  for i = 1, #river - 1 do local a = river[i]; K.willow(a[1] + 18, a[2] - a[3] - 2, 1); if i ~= 3 then K.willow(a[1] + 40, a[2] + a[3] + 5, 1) end end
  for _, s in ipairs({{30, 132}, {300, 140}, {380, 128}, {410, 146}, {340, 92}}) do K.sage(s[1], s[2]) end
end)

K.layer("figures", function()
  K.wagon(216, 112, 1)
  K.team(266, 108, 1, {"dark"}, {"light", true})
  K.wade(214, 262, 112, 4); K.wade(266, 294, 108, 4)
  K.wagon(130, 142, 1)
  K.team(180, 138, 1, {"red"}, {"dark"})
  -- night guard with the cattle, rifle across his knees
  K.person(360, 132, "brick", "hat")
  K.line(355, 128, 366, 126, "deep")
  K.ox(390, 124, -1, "light"); K.ox(330, 140, 1, "red"); K.ox(405, 138, -1, "dark")
end)

-- winter: snow on the pale desert ground as well as the grass
K.season_extra = {{season="winter", y0=60, y1=150, map={silt_lt="white", clap_sh="white", sand="stone_lt"}}}
K.save("location_gravelly_ford")
