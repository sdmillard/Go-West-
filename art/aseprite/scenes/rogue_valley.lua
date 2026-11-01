-- The Rogue River valley at Bear Creek (432x150).
-- Bear Creek runs down a wide valley of oak openings to the Rogue: tawny late-summer grass,
-- dark round oaks scattered over it, pine on the hills and the Siskiyous behind. The best grass
-- and game since the Snake, and Shasta and Takelma country; the companies keep together here.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 185239)

local creek = {{440, 96, 2}, {380, 100, 3}, {320, 98, 3}, {250, 106, 4}, {190, 116, 4}, {130, 126, 5}, {60, 138, 6}, {-10, 150, 7}}

K.layer("sky", function()
  K.sky(W, 72, {{70, 12, 0.9}, {260, 6, 0.7}, {390, 20, 0.6}}, "mist")
end)

K.layer("hills", function()
  -- the Siskiyous and the valley's timbered hills
  K.ridge(0, W - 1, 0, 90, function(x) return -(52 - 8 * math.sin(x / 51 + 1) - 4 * math.sin(x / 19) - 2 * math.sin(x / 7)) end, "far_hill", "mist", "haze")
  K.ridge(0, W - 1, 0, 94, function(x) return -(68 - 6 * math.sin(x / 33) - 3 * math.sin(x / 12 + 1)) end, "teal", "haze", "pine")
  for i = 1, 900 do local x, y = K.rnd(W), 58 + K.rnd(36); if K.at(x, y) == "teal" then K.px(x, y, ({"pine", "leaf", "sage", "teal"})[i % 4 + 1]) end end
end)

K.layer("valley", function()
  -- dry tawny grass with green along the creek
  K.rect(0, 86, W, H - 86, "sage")
  -- patches of cured grass: tufts a few pixels across
  for i = 1, 1400 do
    local x, y = K.rnd(W), 86 + K.rnd(H - 86)
    local c = ({"gold", "silt_lt", "sand", "gold", "ochre", "silt_lt"})[K.rnd(6) + 1]
    K.rect(x, y, 1 + K.rnd(2), 1, c); if K.rnd(2) == 0 then K.px(x, y - 1, c) end
  end
  for i = 1, 700 do K.px(K.rnd(W), 86 + K.rnd(H - 86), ({"sage", "grass", "rust"})[K.rnd(3) + 1]) end
  local water = K.smooth(creek)
  K.ribbon(water, "grass", 4); K.ribbon(water, "leaf", 2)
  K.river(water, false)
  local road = K.smooth({{440, 110, 3}, {360, 114, 3}, {290, 120, 4}, {230, 130, 4}, {170, 140, 5}, {120, 152, 6}})
  K.ribbon(road, "rust", 1); K.ribbon(road, "ochre", 0)
end)

K.layer("oaks", function()
  -- Oregon white oaks: dark rounded crowns scattered over the openings, small with distance
  for _, o in ipairs({{22, 92, 1}, {48, 94, 1}, {104, 90, 1}, {163, 99, 1}, {296, 92, 1}, {312, 95, 1}, {388, 90, 1}, {426, 100, 1}, {212, 93, 1}}) do K.elm(o[1], o[2], o[3]) end
  for _, o in ipairs({{60, 120, 2}, {350, 130, 2}, {410, 146, 2}, {270, 112, 1}}) do K.elm(o[1], o[2], o[3]) end
  for i = 1, #creek - 1 do local a = creek[i]; K.willow(a[1] - 8, a[2] - a[3] - 1, 1) end
end)

K.layer("figures", function()
  K.wagon(250, 128, -1)
  K.team(236, 124, -1, {"red"}, {"dark"})
  K.wagon(330, 116, -1)
  K.team(316, 112, -1, {"dark"}, {"light", true})
  K.person(298, 130, "brick", "hat"); K.line(293, 126, 304, 124, "deep") -- guard with his rifle
  K.far_wagon(400, 107, -1)
  -- deer at the edge of the oaks
  K.rect(150, 108, 5, 2, "ochre"); K.rect(150, 110, 1, 3, "wood"); K.rect(154, 110, 1, 3, "wood"); K.rect(155, 106, 1, 2, "ochre"); K.px(156, 106, "deep")
end)

K.save("location_rogue_valley")
