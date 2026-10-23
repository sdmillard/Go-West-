-- Soda Springs (432x150).
-- In the Bear River valley, under low juniper-dotted hills, carbonated springs bubble out of
-- rusty-orange mounds of travertine. Steamboat Spring spouted and puffed beside the river.
-- Emigrants stopped to drink the "beer" water, sweetened with sugar or syrup.
local K = dofile(app.params.kit)
local W, H = 432, 150

K.canvas(W, H, 184831)

-- a travertine mound: stepped orange terraces with a pool on top
local function mound(cx, y, rx, ry, pool)
  -- terraces climb in steps, each with a dark wet lip and a sunlit top
  local steps = math.max(2, math.floor(rx / 5))
  K.ellipse(cx + 2, y + 1, rx, ry, "shadow")
  local top_y, top_rx, top_ry = y, rx, ry
  for k = 0, steps - 1 do
    local r = rx - k * 4
    local yy = y - k * 2
    local rr = math.max(1, ry - math.floor(k / 2))
    K.ellipse(cx, yy, r, rr, "rust")
    K.ellipse(cx - 1, yy - 1, r - 1, math.max(1, rr - 1), (k % 2 == 0) and "ochre" or "gold")
    K.ellipse(cx - 2, yy - 1, math.max(1, r - 4), math.max(1, rr - 2), (k % 2 == 0) and "gold" or "sand")
    for i = 0, r * 2, 5 do K.px(cx - r + i, yy + rr, "red") end
    top_y, top_rx, top_ry = yy, r, rr
  end
  if pool then
    K.ellipse(cx, top_y - 1, math.max(2, top_rx - 2), math.max(1, top_ry - 1), "cream")
    K.ellipse(cx, top_y - 1, math.max(1, top_rx - 4), math.max(1, top_ry - 1), "sky_top")
    K.px(cx - 1, top_y - 1, "white"); K.px(cx + 1, top_y - 2, "white")
    -- overflow trickling down the terraces
    K.line(cx + 2, top_y + 1, cx + 4, y + ry, "cream")
  end
  return top_y
end

K.layer("sky", function()
  K.sky(W, 70, {{250, 18, 0.7}, {60, 8, 1.0}}, "mist")
end)

K.layer("hills", function()
  -- the Bear River range far off, then cedar-dotted foothills
  K.ridge(0, W - 1, 0, 100, function(x) return -(46 + 10 * math.sin(x / 47) + 4 * math.sin(x / 13 + 2)) end, "far_hill", "mist", "haze")
  local fh = function(x) return 22 + 8 * math.sin(x / 31 + 1) + 4 * math.sin(x / 11) end
  K.ridge(0, W - 1, 92, 100, fh, "sage", "clap_sh", "teal")
  for i = 1, 140 do
    local x = K.rnd(W)
    local top = math.floor(92 - fh(x) + 0.5)
    local y = top + 3 + K.rnd(math.max(1, 92 - top))
    K.ellipse(x, y, 2, 1, "pine"); K.px(x - 1, y - 1, "leaf")
  end
end)

K.layer("valley", function()
  K.rect(0, 92, W, H - 92, "grass")
  for i = 1, 1100 do
    local x, y = K.rnd(W), 92 + K.rnd(H - 92)
    K.px(x, y, ({"sage", "leaf", "gold", "grass"})[i % 4 + 1])
  end
  -- Bear River bending through the meadow
  local river = K.smooth({{-6, 100, 3}, {60, 104, 4}, {140, 99, 4}, {230, 105, 4}, {320, 98, 4}, {440, 102, 4}})
  K.ribbon(river, "leaf", 4)
  K.river(river, "sage")
  -- the road
  local road = K.smooth({{-6, 132, 6}, {80, 126, 5}, {170, 122, 4}, {260, 116, 3}, {350, 112, 2}, {440, 110, 2}})
  K.ribbon(road, "ochre", 1); K.ribbon(road, "sand", 0)
  -- crusted white soda flats around the springs
  for _, f in ipairs({{120, 118, 46, 7}, {300, 128, 60, 9}, {360, 106, 30, 4}}) do
    K.ellipse(f[1], f[2], f[3], f[4], "clap_sh")
    for i = 1, f[3] * 2 do
      local x, y = f[1] - f[3] + K.rnd(f[3] * 2), f[2] - f[4] + K.rnd(f[4] * 2)
      if K.at(x, y) == "clap_sh" then K.px(x, y, (i % 3 == 0) and "cream" or "sand") end
    end
  end
end)

K.layer("springs", function()
  mound(360, 106, 14, 4, true)
  mound(112, 118, 18, 5, true)
  mound(146, 121, 10, 3, false)
  mound(300, 128, 26, 7, true)
  mound(258, 134, 12, 4, true)
  -- Steamboat Spring by the river: a puffing jet of spray
  local sx, sy = 206, 104
  mound(sx, sy, 10, 3, false)
  for i = 0, 9 do
    local w = 1 + math.floor(i / 3)
    K.rect(sx - w + (i % 2), sy - 4 - i * 2, w * 2, 2, (i % 3 == 0) and "light_blue" or "white")
  end
  K.ellipse(sx - 1, sy - 26, 5, 3, "white"); K.ellipse(sx + 2, sy - 24, 4, 2, "mist")
  -- bubbles in the big pool
  for _, b in ipairs({{296, 125}, {303, 126}, {299, 123}}) do K.px(b[1], b[2], "white") end
end)

K.layer("figures", function()
  -- wagons stopped along the road, a party tasting the water at the big spring
  K.far_wagon(352, 113, -1)
  K.far_wagon(376, 112, -1)
  K.wagon(18, 140, 1)
  K.team(72, 138, 1, {"dark"}, {"light", true})
  K.person(278, 132, "red", "bonnet", true)
  K.person(320, 134, "blue", "deep")
  K.rect(318, 124, 2, 2, "stone"); K.px(317, 125, "stone")
  K.person(330, 135, "teal", "roof")
end)

K.save("location_soda_springs")
