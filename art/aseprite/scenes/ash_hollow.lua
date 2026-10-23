-- Ash Hollow (432x150).
-- After the dry tableland between the forks of the Platte, the road drops down the very steep
-- slope later called Windlass Hill, where wagons were let down with locked wheels and ropes,
-- into a shady hollow of ash trees, wild roses and a good spring, opening onto the North Platte.
local K = dofile(app.params.kit)
local W, H = 432, 150

K.canvas(W, H, 184824)

local function hill(x)
  -- Windlass Hill: high on the left, a steep face falling to the hollow floor
  local t = math.max(0, math.min(1, (x - 40) / 170))
  return 100 - 60 * (1 - t) ^ 1.6 + 6 * math.sin(x / 13) * (1 - t)
end

K.layer("sky", function()
  K.sky(W, 74, {{170, 12, 0.8}, {360, 22, 0.6}}, "mist")
end)

K.layer("platte valley", function()
  -- the North Platte valley seen through the mouth of the hollow
  K.ridge(0, W - 1, 0, 96, function(x) return -(72 + 2 * math.sin(x / 41)) end, "far_hill", "mist", "haze")
  K.rect(0, 84, W, 18, "sage")
  K.dither(0, 84, W, 2, "sage", "far_hill")
  K.rect(0, 88, W, 2, "light_blue"); K.rect(0, 89, W, 1, "sky_top")
  for x = 0, W - 1, 7 do K.px(x + K.rnd(4), 87, "grass") end
end)

K.layer("bluffs", function()
  -- chalky bluffs closing the east side of the hollow, cedars in the draws
  local bluff = function(x) return 28 * math.min(1, math.max(0, (x - 280) / 50)) + 6 * math.sin(x / 11) + 4 * math.sin(x / 5) end
  K.ridge(270, W - 1, 100, 110, bluff, "clap_sh", "cream", "ochre")
  for x = 270, W - 1 do
    local top = math.floor(100 - bluff(x) + 0.5)
    for y = top + 2, 108 do
      if (y - top) % 6 == 0 then K.px(x, y, "sand") elseif (y - top) % 6 == 1 and K.rnd(3) == 0 then K.px(x, y, "ochre") end
    end
  end
  for _, c in ipairs({{300, 92, 8}, {322, 84, 10}, {360, 80, 9}, {398, 86, 8}, {414, 78, 10}, {344, 96, 7}}) do
    K.conifer(c[1], c[2], c[3], "pine", "teal", "leaf")
  end
end)

K.layer("hollow", function()
  -- floor of the hollow: grass, roses and the spring branch running out to the Platte
  K.rect(0, 100, W, H - 100, "grass")
  for i = 1, 1100 do
    local x, y = K.rnd(W), 100 + K.rnd(H - 100)
    K.px(x, y, ({"leaf", "sage", "gold", "grass", "red"})[i % 5 + 1])
  end
  local creek = K.smooth({{230, 142, 2}, {250, 128, 2}, {236, 116, 2}, {262, 104, 1}, {286, 96, 1}})
  K.river(creek, "leaf")
  K.ellipse(226, 144, 9, 3, "leaf"); K.ellipse(226, 144, 7, 2, "sky_top"); K.px(224, 143, "white")
  -- road from the hill foot across the hollow toward the river
  local road = K.smooth({{196, 118, 3}, {230, 112, 3}, {270, 104, 2}, {300, 98, 1}})
  K.ribbon(road, "ochre", 1); K.ribbon(road, "sand", 0)
end)

K.layer("windlass hill", function()
  -- the hill's foot sweeps from the hollow floor round toward the viewer
  local foot = function(x) return (x < 120) and H - 1 or 101 + 49 * ((230 - x) / 110) ^ 1.6 end
  for x = 0, 230 do
    local top = math.floor(hill(x) + 0.5)
    for y = top, math.floor(foot(x)) do K.px(x, y, "ochre") end
    K.px(x, top, "sand")
    if hill(x + 1) - hill(x - 1) > 0.15 then K.px(x, top + 1, "sand") end
    K.px(x, math.floor(foot(x)), "rust")
  end
  -- eroded grass slope: tufts and streaks running down the face
  for i = 1, 900 do
    local x = K.rnd(230)
    local top = math.floor(hill(x) + 0.5)
    local y = top + 2 + K.rnd(H - top)
    if K.at(x, y) == "ochre" then K.px(x, y, ({"gold", "sage", "rust", "grass"})[i % 4 + 1]) end
  end
  for _, g in ipairs({{30, 6}, {74, -5}, {120, 7}, {168, -4}}) do
    for y = math.floor(hill(g[1])) + 4, 150 do
      local x = math.floor(g[1] + g[2] * math.sin(y / 14))
      if K.at(x, y) then K.px(x, y, "rust"); K.px(x + 1, y, "wood") end
    end
  end
  -- deep wheel ruts cut straight down the face
  for k = 0, 1 do
    local x0 = 60 + k * 6
    for x = x0, 196 do
      local y = math.floor(hill(x) + 3 + (x - x0) * 0.06 + 0.5)
      K.px(x, y, "wood"); K.px(x, y + 1, "deep")
    end
  end
  -- the ground near the viewer stays steep and grassy
  K.ridge(0, 200, 0, H - 1, function(x) return -(126 + 12 * ((x / 120) ^ 2)) end, "grass", "sage", "leaf")
end)

K.layer("trees", function()
  -- the ash grove on the hollow floor, with wild rose thickets
  for _, t in ipairs({{214, 126, 1}, {268, 118, 1}, {296, 112, 1}, {320, 122, 1}, {246, 140, 1}, {390, 146, 2}, {150, 148, 1}}) do
    K.elm(t[1], t[2], t[3])
  end
  for _, r in ipairs({{230, 132}, {282, 124}, {300, 128}, {340, 132}, {204, 146}}) do
    K.willow(r[1], r[2], 1); K.px(r[1] - 2, r[2] - 4, "red"); K.px(r[1] + 2, r[2] - 3, "red")
  end
end)

K.layer("figures", function()
  -- two wagons on the descent, small with distance, men holding them back with ropes
  local function on_hill(x) return math.floor(hill(x) + 3.5) end
  K.far_wagon(96, on_hill(96), 1)
  K.line(96, on_hill(96) - 6, 80, on_hill(80) - 4, "cream")
  K.rect(78, on_hill(78) - 6, 1, 4, "blue"); K.px(78, on_hill(78) - 7, "skin")
  K.rect(74, on_hill(74) - 6, 1, 4, "red"); K.px(74, on_hill(74) - 7, "skin")
  K.far_wagon(150, on_hill(150), 1)
  -- in the hollow: a wagon pulled up in the shade, a woman at the spring
  K.wagon(326, 142, -1)
  K.team(316, 140, -1, {"red"}, {"light", true})
  K.person(236, 146, "teal", "bonnet", true)
  K.person(266, 144, "blue", "deep")
end)

K.save("location_ash_hollow")
