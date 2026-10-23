-- Burnt River canyon (432x150).
-- Palmer (1845) and later diarists describe a narrow, crooked valley between steep, dry
-- brown hills, with the trail crossing and recrossing the creek among willows.
-- The view looks up the creek through interlocking spurs, with a wagon at a ford.
local K = dofile(app.params.kit)
local W, H = 432, 150

K.canvas(W, H, 184823)

local function curve(a, b, x0, x1, bend)
  -- top line from (x0, a) to (x1, b) with a convex shoulder
  return function(x)
    local t = math.max(0, math.min(1, (x - x0) / (x1 - x0)))
    return a + (b - a) * (t ^ bend)
  end
end

K.layer("sky", function()
  K.sky(W, 60, {{70, 12, 0.9}, {262, 7, 0.7}}, "mist")
end)

K.layer("far hills", function()
  -- distant dry ridge closing the head of the valley
  K.ridge(0, W - 1, 0, 90, function(x) return -(52 + 5 * math.sin(x / 31) + 3 * math.sin(x / 11 + 2)) end, "far_hill", "mist", "haze")
  K.ridge(120, 360, 0, 90, function(x) return -(60 + 6 * math.sin(x / 23 + 1)) end, "clap_sh", "sand", "ochre")
end)

K.layer("valley floor", function()
  K.rect(0, 72, W, H - 72, "ochre")
  for i = 1, 500 do
    local x, y = K.rnd(W), 74 + K.rnd(H - 74)
    K.px(x, y, (i % 3 == 0) and "gold" or "rust")
  end
  -- green strip of grass and rushes following the creek
  local pts = K.smooth({{232, 74, 2}, {218, 86, 4}, {246, 100, 7}, {262, 112, 9}, {222, 128, 13}, {204, 140, 15}, {214, 154, 17}})
  K.ribbon(pts, "grass", 7)
  K.ribbon(pts, "sage", 4)
  -- the trail: down the left side, across the ford, then away up the right
  K.ribbon(K.smooth({{-4, 150, 9}, {60, 140, 8}, {140, 136, 7}, {218, 132, 6}}), "rust", 1)
  K.ribbon(K.smooth({{-4, 150, 9}, {60, 140, 8}, {140, 136, 7}, {218, 132, 6}}), "sand", 0)
  K.ribbon(K.smooth({{226, 130, 5}, {280, 112, 4}, {300, 96, 3}, {276, 86, 2}, {250, 78, 1}}), "rust", 1)
  K.ribbon(K.smooth({{226, 130, 5}, {280, 112, 4}, {300, 96, 3}, {276, 86, 2}, {250, 78, 1}}), "sand", 0)
  -- the creek itself, twisting toward the viewer
  K.river(K.smooth({{232, 74, 1}, {218, 86, 2}, {246, 100, 3}, {262, 112, 4}, {222, 128, 6}, {204, 140, 7}, {214, 154, 8}}), "clap_sh")
  -- ford riffles where the trail crosses
  for i = 0, 7 do K.rect(196 + i * 4, 133 + (i % 2), 2, 1, "white") end
end)

K.layer("spurs", function()
  -- far left spur, sunlit
  K.ridge(0, 246, 0, 84, function(x) return -curve(40, 80, 0, 246, 1.8)(x) end, "ochre", "gold", "rust")
  -- far right spur, turned away from the light
  K.ridge(238, W - 1, 0, 92, function(x) return -curve(84, 46, 238, W - 1, 0.55)(x) end, "rust", "ochre", "wood")
  -- strata lines on the far spurs
  for y = 50, 84, 6 do
    for x = 0, W - 1 do
      local c = K.at(x, y)
      local on = math.sin(x / 9 + y) > 0.2
      if on and c == "ochre" then K.px(x, y, "rust") elseif on and c == "rust" then K.px(x, y, "wood") end
    end
  end
  -- near left spur sweeping down to the creek
  K.ridge(0, 196, 0, 124, function(x) return -curve(62, 120, 0, 196, 2.2)(x) end, "rust", "ochre", "wood")
  -- nearest right spur, deep in shadow
  K.ridge(286, W - 1, 0, 150, function(x) return -curve(118, 66, 286, W - 1, 0.5)(x) end, "wood", "rust", "deep")
  -- talus and gullies
  for i = 1, 260 do
    local x, y = K.rnd(W), 46 + K.rnd(104)
    local c = K.at(x, y)
    if c == "rust" then K.px(x, y, (i % 2 == 0) and "wood" or "ochre")
    elseif c == "wood" then K.px(x, y, (i % 2 == 0) and "deep" or "rust")
    elseif c == "ochre" then K.px(x, y, "gold") end
  end
  for i = 1, 90 do
    local x, y = K.rnd(W), 50 + K.rnd(100)
    local c = K.at(x, y)
    if c == "ochre" or c == "rust" or c == "wood" or c == "gold" then K.sage(x, y) end
  end
  for _, g in ipairs({{40, 70, 52, 90}, {110, 90, 120, 108}, {350, 96, 340, 118}, {404, 82, 396, 104}}) do
    K.line(g[1], g[2], g[3], g[4], "deep")
    K.line(g[1] + 1, g[2], g[3] + 1, g[4], "wood")
  end
end)

K.layer("brush", function()
  -- willows along the water
  for _, w in ipairs({{226, 84, 1}, {254, 96, 1}, {272, 116, 1}, {200, 118, 1}, {150, 146, 1}, {262, 146, 2}, {214, 76, 1}, {262, 104, 1}}) do
    K.willow(w[1], w[2], w[3])
  end
end)

K.layer("figures", function()
  -- wagon halfway through the ford, the driver wading beside the team
  K.wagon(178, 138, 1)
  K.team(232, 132, 1, {"dark"}, {"light", true})
  K.line(224, 131, 250, 118, "deep")
  K.person(266, 128, "blue", "deep")
  -- splash at the wheels
  for i = 0, 9 do K.px(184 + i * 4, 139 + (i % 2), "white") end
end)

K.save("location_burnt_river")
